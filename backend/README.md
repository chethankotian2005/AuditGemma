# AuditGemma Backend

FastAPI backend implementing the four-stage Gemma pipeline from the project spec.

## Status (Day 0 scaffold — what's done vs. what's next)

**Done and tested:**
- Stage 2 deterministic signal layer — Benford's Law, transaction velocity, robust
  (median/MAD) threshold anomaly check, cross-document entity consistency. Fully
  unit-tested (`pytest tests/ -v`, 8/8 passing), no Gemma dependency, safe to build
  the mobile/web UI against right now using mocked scores.
- Stage 1/3/4 Gemma agent modules — extraction, scoring+narrative, conversational
  agent — with the Thinking Mode on/off split exactly matching the spec's table.
- FastAPI routes wiring all four stages together: `/extract`, `/score`, `/converse`,
  `/case/{id}`, `/cases`.
- Document extraction uses Gemma's native vision only — no separate OCR dependency required.

**Next (do this before the mobile/dashboard team needs real scores):**
1. Install Ollama locally, pull the model, confirm a real Gemma call works end-to-end
   (see below).
2. Swap `CASE_STORE` (in-memory dict in `app/api/routes.py`) for Firestore once the
   Firebase project is set up — the shape is already isolated to that one variable.
3. Build the sample document set (messy invoice/GST/bank statement images) for the
   live demo — put them in `sample_data/`.
4. Add auth (Firebase Auth token verification) to gate officer-only routes.

## Scoring Methodology
The scoring system is fully **deterministic and reproducible**.
- **Base Score:** Every case starts at a `100` (lowest risk).
- **Penalties:** Stage 2 deterministic checks (Benford's Law, Entity Consistency, etc.) penalize the score if they trigger. Penalties are fixed (`Severity Weight × Check Importance Weight`).
- **Gemma's Role:** Gemma acts strictly as an explainer and contextual adjuster. Gemma is restricted to proposing a contextual adjustment bounded between `[-10, 10]`, accompanied by a strict justification based on the business context.
- **Action/Confidence:** The final score determines the recommended action based on hard thresholds (e.g. `>= 80` -> Approve, `< 50` -> Escalate).

## Setup

```bash
python3 -m venv venv
source venv/bin/activate          # Windows: venv\Scripts\activate
pip install -r requirements.txt
cp .env.example .env
```

### Install Ollama + pull Gemma (do this early — model pull takes a while on venue wifi)

```bash
# https://ollama.com/download
ollama pull gemma3:4b       # ~6GB VRAM — E4B edge variant per spec
ollama pull gemma3:2b       # fallback for lower-spec laptops (2-3GB)
ollama serve                # keep running in a separate terminal
```

### ⚠️ Before you demo checklist
1. Start Ollama locally.
2. Confirm `gemma3:4b` is pulled (`ollama list`).
3. Start the backend (`docker-compose up -d` or `uvicorn main:app`).
4. **WAIT** for the "Model warm-up complete" log line in the backend before touching the app! Do not let the first live document upload also be the first real model load.

> Note: confirm the exact Ollama model tag for "Gemma 4 E4B" / "E2B" once you've
> checked Ollama's library — tag names can differ slightly from the spec's naming
> (`gemma3:4b` used here as the closest available tag as of writing). Update
> `GEMMA_MODEL` in `.env` accordingly.

### Run

```bash
uvicorn main:app --reload --port 8000
```

- Health check: `GET http://localhost:8000/health`
- Interactive API docs: `http://localhost:8000/docs` — use this to test `/score` and
  `/converse` by hand before the mobile app is wired up.

### Test the signal layer (no Ollama needed)

```bash
pytest tests/ -v
```

### Troubleshooting

> **If you see a CORS error in the browser console**, check the backend terminal/logs
> first — a crash mid-request can look like a CORS error even when CORS is configured
> correctly. The backend includes a global exception handler that catches unhandled
> errors and returns a proper JSON 500 with a correlation `error_id` you can search
> for in the server logs.

### Known failure modes and how they surface

During a live demo, if something breaks, here is how the app will respond:

1. **Ollama unreachable or model not pulled:** The backend catches the connection error and returns a clean `502 Bad Gateway`. Both the Flutter app and Next.js dashboard will show a readable error: "Server error (502): Gemma extraction failed: Could not reach Ollama at..." rather than crashing silently.
2. **Gemma returns malformed JSON:** If Gemma fails to produce valid JSON (more common under Thinking Mode), the backend fallback parser attempts to salvage it. If it still fails, it throws a `ValueError` which surfaces to the client as a `502` with "Gemma did not return valid JSON...".
3. **Submitting zero documents:** The `POST /score` endpoint explicitly validates the document list and returns a `400 Bad Request` ("Cannot score a case with zero documents.") preventing a crash in the signal layer.
4. **Network drop mid-upload (Flutter):** If the phone loses Wi-Fi while uploading a document or waiting for extraction, the Flutter app catches the `ClientException`, shows a red Snackbar ("Could not reach the server. Check your network connection."), and leaves the UI in a state where the user can simply tap the button again to retry.


## API quick reference

| Endpoint | Stage | Purpose |
|---|---|---|
| `POST /api/v1/extract` | 1 | Upload one document image → structured JSON |
| `POST /api/v1/score` | 2+3 | Documents + business context → score/confidence/narrative |
| `POST /api/v1/converse` | 4 | case_id + question → grounded Gemma answer |
| `GET /api/v1/case/{id}` | — | Case status for mobile/dashboard polling |
| `PATCH /api/v1/case/{id}/status` | — | Officer swipe action (approve/escalate/request_documents) |
| `GET /api/v1/cases` | — | Case queue for officer dashboard |

## Design notes worth remembering for judge Q&A

- **Why median/MAD instead of mean/stdev for the threshold check**: a naive z-score
  is skewed by the very outlier it's trying to catch (one huge amount inflates the
  stdev enough to hide itself). Median + MAD stays stable. Good answer if a judge
  probes the statistical rigor of the "no-training" signal layer.
- **Why Thinking Mode is OFF for Stage 1/3-JSON but ON for Stage 3-narrative/Stage 4**:
  rigid JSON degrades under Thinking Mode; genuine multi-step reasoning (narrative,
  conversation) benefits from it. This split is explicitly called out in the code
  comments — good to point at live if asked "why not just always use thinking mode?"

## Firebase Setup (Firestore & FCM)

To enable persistent storage and push notifications for the officer mobile app:

1. Go to the [Firebase Console](https://console.firebase.google.com/) and create a new project.
2. In the left sidebar, go to **Firestore Database** and click **Create database**. Start in test mode for local development.
3. Go to **Project Settings > Service Accounts**.
4. Click **Generate new private key**. Save the `.json` file to your machine (e.g., in the root of this project, but **do not commit it**).
5. Open your `.env` file and set the path to the downloaded key:
   ```env
   FIREBASE_SERVICE_ACCOUNT_PATH=./auditgemma-firebase-adminsdk.json
   ```
6. The backend will automatically initialize the Firebase Admin SDK on startup if this path is provided, creating a `cases` collection and sending FCM alerts to the `officer_alerts` topic.

## Authentication (Firebase Auth)
The FastAPI routes are heavily protected using Firebase ID Tokens passed via the `Authorization: Bearer <token>` header. 
- **Protected Routes:** `POST /score`, `POST /converse`, `GET /cases`, `GET /case/{id}`, `PATCH /case/{id}/status`.
- **Unprotected Routes:** `POST /extract`. 
  - *TODO: `/extract` is intentionally left unauthenticated to allow SME applicants to upload without being explicitly registered on the Officer's Firebase tenant. Consider adding SME-specific tenant auth in a later iteration.*

### Manual Test (Testing Rejection)
You can quickly confirm that the backend properly rejects unauthenticated requests by attempting to hit a protected route via `curl`. It should return a `401 Unauthorized` error.

```bash
curl -X GET "http://localhost:8000/api/v1/cases" -H "accept: application/json"
```
*(Expected Output: `{"detail":"Not authenticated"}`)*

## Firestore Security & Data Flow
The architecture strictly follows the **Read-Direct / Write-via-Backend** pattern:

- **Reads (Frontends):** While the dashboard and mobile app currently use `GET /cases` for polling, they are architected so they *can* use `onSnapshot` for direct, real-time Firestore reads.
- **Writes (Backend):** Client apps are **NEVER** allowed to write directly to Firestore (e.g., updating a case score or changing status). All write actions must flow through the FastAPI backend (e.g., `PATCH /case/{id}/status`), which uses the Firebase Admin SDK to bypass security rules and enforce business logic.
- **Security Rules (`firestore.rules`):** The provided rules explicitly `allow read` for authenticated officers/owners but enforce `allow write: if false;` to block any malicious client-side tampering.

## 🚀 Deployment (Google Cloud Run)

The backend is fully containerized and ready to deploy to Google Cloud Run. 

### ⚠️ CRITICAL: The Ollama / Gemma Tradeoff
**Ollama and Gemma models cannot run inside a standard Cloud Run container.** They require persistent local GPUs and taking minutes to pull multi-GB weights on every cold start is not viable for a serverless environment.

For the live hackathon demo, you MUST choose one of three architectures:

1. **The "Hybrid" approach (Recommended for Demo):** 
   - Deploy the backend to Cloud Run.
   - Run Ollama locally on your presentation laptop.
   - Expose your local Ollama instance securely via an `ngrok` tunnel.
   - Set the `OLLAMA_BASE_URL` in Cloud Run to your ngrok URL.
   - *Why?* Proves you can deploy a real cloud backend, while leveraging your laptop's GPU for fast inference.

2. **The "Non-Gemma Cloud" approach:**
   - Deploy to Cloud Run, but leave `OLLAMA_BASE_URL` empty.
   - Use the deployed backend to demonstrate the Deterministic Signal Layer (Stage 2), Auth, and Database integration.
   - *Why?* Safe, but you cannot demo the AI extraction or reasoning live on the cloud URL.

3. **The "Pure Local" approach:**
   - Skip Cloud Run for the live demo entirely.
   - Run both the FastAPI backend and Ollama locally on your laptop (`localhost`).
   - Keep the Cloud Run URL handy just to prove to the judges that the code *is* deployable.
   - *Why?* Zero latency, zero network dependency, immune to bad venue Wi-Fi.

### Step-by-Step Deployment

**1. Prerequisites**
- Install the [Google Cloud CLI](https://cloud.google.com/sdk/docs/install).
- Login: `gcloud auth login`
- Set your project: `gcloud config set project YOUR_PROJECT_ID`
- Ensure Billing is enabled on your GCP project.

**2. Firebase Credentials Setup**
Place your Firebase Admin SDK JSON key in the `backend/` directory and rename it exactly to `firebase-adminsdk.json`. (Do NOT commit this file). The deployment script will automatically upload this securely to **Google Cloud Secret Manager** and mount it into the Cloud Run container at runtime.

**3. Run the Deploy Script**
From the `backend/` directory, run:
```bash
chmod +x scripts/deploy.sh
./scripts/deploy.sh
```

The script will prompt you for your `OLLAMA_BASE_URL` (if you are using the ngrok approach). Once complete, it will output your live Cloud Run URL.

**4. Verify Health**
```bash
curl -X GET https://YOUR-CLOUD-RUN-URL/health
```
*(Should return `200 OK`)*
