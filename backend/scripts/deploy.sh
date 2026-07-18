#!/bin/bash
# Deploy AuditGemma Backend to Google Cloud Run
set -e

echo "====================================================="
echo "   AuditGemma Backend - Cloud Run Deployment Script  "
echo "====================================================="

# Ensure gcloud is installed
if ! command -v gcloud &> /dev/null; then
    echo "Error: gcloud CLI not found. Please install the Google Cloud SDK."
    exit 1
fi

PROJECT_ID=$(gcloud config get-value project)
if [ -z "$PROJECT_ID" ]; then
    echo "Error: No active gcloud project. Run 'gcloud config set project YOUR_PROJECT_ID'"
    exit 1
fi

REGION="us-central1"
SERVICE_NAME="auditgemma-backend"
SECRET_NAME="auditgemma-firebase-key"
SERVICE_ACCOUNT_FILE="firebase-adminsdk.json"

echo "Deploying to Project: $PROJECT_ID in Region: $REGION..."

# 1. Enable required APIs
echo "Ensuring required APIs are enabled (Cloud Run, Secret Manager, Cloud Build)..."
gcloud services enable run.googleapis.com secretmanager.googleapis.com cloudbuild.googleapis.com

# 2. Setup Firebase Admin Credentials in Secret Manager
if [ -f "$SERVICE_ACCOUNT_FILE" ]; then
    echo "Found $SERVICE_ACCOUNT_FILE. Configuring Secret Manager..."
    
    # Check if secret exists
    if ! gcloud secrets describe $SECRET_NAME >/dev/null 2>&1; then
        echo "Creating secret: $SECRET_NAME..."
        gcloud secrets create $SECRET_NAME --replication-policy="automatic"
    fi
    
    # Add new version
    echo "Uploading key to Secret Manager..."
    gcloud secrets versions add $SECRET_NAME --data-file="$SERVICE_ACCOUNT_FILE"
    
    # Grant Cloud Run service agent access to the secret
    PROJECT_NUMBER=$(gcloud projects describe $PROJECT_ID --format="value(projectNumber)")
    gcloud secrets add-iam-policy-binding $SECRET_NAME \
        --member="serviceAccount:$PROJECT_NUMBER-compute@developer.gserviceaccount.com" \
        --role="roles/secretmanager.secretAccessor" >/dev/null 2>&1
else
    echo "WARNING: $SERVICE_ACCOUNT_FILE not found in current directory."
    echo "The deployed service will not have Firebase access unless configured manually."
    read -p "Continue deployment anyway? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# 3. Read OLLAMA_BASE_URL
echo ""
echo "IMPORTANT: Ollama/Gemma does not run inside this Cloud Run container."
read -p "Enter your OLLAMA_BASE_URL (e.g., https://your-ngrok-url.ngrok.app or leave blank to fail gracefully on Gemma calls): " OLLAMA_URL

# 4. Deploy to Cloud Run
echo ""
echo "Building and deploying to Cloud Run..."
gcloud run deploy $SERVICE_NAME \
    --source . \
    --region $REGION \
    --allow-unauthenticated \
    --set-env-vars="OLLAMA_BASE_URL=$OLLAMA_URL" \
    --set-secrets="/etc/secrets/firebase-adminsdk.json=$SECRET_NAME:latest" \
    --update-env-vars="FIREBASE_SERVICE_ACCOUNT_PATH=/etc/secrets/firebase-adminsdk.json"

echo ""
echo "====================================================="
echo "Deployment complete! Check the Cloud Run URL above."
echo "Verify health: curl -X GET https://<YOUR-CLOUD-RUN-URL>/health"
echo "====================================================="
