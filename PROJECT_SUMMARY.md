# AuditGemma — Project Summary & Features

**AuditGemma** is an SME loan compliance and risk triage copilot, built for the "Build with Gemma: Bengaluru AI Sprint" hackathon.

This document serves as a comprehensive overview of the entire system architecture, the features implemented across the stack, and recent infrastructure updates.

---

## 🏗️ System Architecture

The project is split across three main codebases, all connected to a unified Firebase backend.

1. **FastAPI Backend (Python)**: The core AI engine running the local Gemma models (via Ollama) and processing the business logic.
2. **Next.js Web Dashboard (React)**: The portal for Compliance Officers to deep-dive into flagged cases and interrogate the AI.
3. **Flutter Mobile App (Dart)**: The dual-role mobile application for both SME applicants (uploading documents) and roaming Officers (quick triage).

---

## ✨ Features Implemented

### 1. The 4-Stage AI Pipeline (Backend)
- **Stage 1: Vision Extraction Agent**: Uses Gemma vision models to extract tabular financial data from raw uploaded images (Invoices, GST returns, Bank Statements, KYC) into structured JSON.
- **Stage 2: Deterministic Signal Layer**: Runs hard math (Benford's Law deviations, Transaction Velocity tracking, Median/MAD thresholds, Cross-document entity consistency) over the extracted JSON to flag anomalies reliably without LLM hallucination.
- **Stage 3: Gemma Reasoning Agent**: Scores the case (0-100) and writes a contextual, plain-language audit narrative. It reasons *over* the rigid Stage 2 signals combined with user-provided business context.
- **Stage 4: Conversational Agent**: Allows compliance officers to ask unscripted questions live. The agent is strictly grounded in the extracted case data to prevent hallucinating external knowledge.

### 2. Officer Web Dashboard (Next.js)
- **Real-time Case Queue**: Officers can monitor incoming loan applications.
- **Reasoning Panel**: Displays the extracted JSON data alongside Gemma's narrative and the specific hard-math signals that were tripped.
- **Live Conversational Chat**: Officers can interrogate the AI's logic directly on the case view.
- **PDF Export**: Generates a clean, downloadable PDF report of the entire audit trail (data, signals, narrative, and chat history) for compliance archiving.
- **Authentication**: Secured via Firebase Auth.

### 3. SME & Officer Mobile App (Flutter)
- **Role-Gated UX**: A single app serving two distinct user flows.
- **SME View**: Intuitive document upload flow (capturing Invoices, KYC, etc.) and submission with business context notes.
- **Officer View**: Quick-triage interface.
- **Swipe Actions**: Officers can swipe on case cards to Escalate, Approve, or request more documents on the go.
- **Escalation Tools**: Includes UI mockups for Voice Notes (allowing officers to append audio thoughts) and Push Notifications for high-risk alerts.

### 4. Synthetic Demo Data Engine
- **Programmatic Generators**: A Python pipeline (`sample_data/generate_samples.py`) that uses `Pillow` to draw realistic-looking synthetic financial documents. 
- **Deterministic Testing**: Generates 5 specific cases (Clean Control, GSTIN Mismatch, Transaction Burst, MAD Outlier, and Borderline Ambiguous) with exact numbers designed to flawlessly trip the Stage 2 signals without relying on hallucinatory AI image generators.
- **Statistical Fidelity**: The generator constructs full 30+ item bank statements with explicitly skewed leading-digit distributions to reliably trigger mathematical tests (like Benford's Law) during the live demo without lowering the hard-coded `BENFORD_MIN_SAMPLE_SIZE`.

---

## 🔄 Recent Updates & Migrations

- **Database Swapped to Firestore**: Replaced the original in-memory backend Python dictionary (`CASE_STORE`) with a robust `firebase-admin` Firestore integration. All apps now read/write to the same cloud database in real-time.
- **Firebase Authentication Wired Up & Enforced**: Replaced local mocked auth states. The Web Dashboard and Flutter App now authenticate directly against Firebase Identity Platform. Furthermore, the **FastAPI Backend now strictly enforces Firebase ID Tokens** (`Authorization: Bearer`) on all officer-facing routes, rejecting unauthenticated requests with a 401/403. Both frontends have been upgraded to automatically attach this token to their API calls.
- **Firestore Security Rules**: Authored and documented `firestore.rules` enforcing a "Read-Direct / Write-via-Backend" architectural pattern. Clients are completely blocked from writing to the database directly, ensuring all data mutations pass through the FastAPI backend's business logic, while keeping the door open for secure `onSnapshot` real-time reads in the future.
- **Officer Audit Trail**: Built a compliance-credibility feature. The backend now writes chronological logs to an `audit_log` Firestore collection on every status change. This history is rendered in a collapsible UI section on the Next.js Case Detail page and seamlessly embedded into the exported PDF Report.
- **End-to-End Testing**: Updated `scripts/e2e_check.py` to ping all pipeline endpoints locally. It uses `python-dotenv` and the Firebase Auth REST API to fetch a real `idToken` to test protected routes without throwing 401s on the morning of the hackathon.
- **Backend Cloud Run Deployment**: Fully containerized the FastAPI backend (`Dockerfile`, `.dockerignore`) and authored `scripts/deploy.sh` to automate deployment to Google Cloud Run, leveraging **Secret Manager** to securely mount the Firebase Admin credentials at runtime.
- **Frontend Deployments**: Fully documented the live-demo deployment tradeoffs. Wrote exact instructions for mapping the `NEXT_PUBLIC_API_URL` environment variables on **Vercel** for the web dashboard, and implemented dynamic `--dart-define` build-time configuration to install the Flutter app on a **Physical Android Device**.
- **Demo Script Finalized**: Created a comprehensive `DEMO_SCRIPT.md` run-sheet detailing exactly what to click, what to say, and fallback strategies for the live hackathon presentation.
- **Removed OCR Fallback Dependency**: Streamlined the extraction pipeline by removing Tesseract and `pytesseract` entirely. The architecture now relies 100% on Gemma's native vision capabilities, simplifying deployment and avoiding brittle system-level dependencies.
- **Cross-Platform File Handling**: Refactored the Flutter document capture flow to standardize on `XFile.readAsBytes()`, ensuring the image upload pipeline works identically (and flawlessly) across both Android physical devices and Flutter Web.
- **Error Handling & UX Hardening**: 
  - Implemented a Starlette `BaseHTTPMiddleware` global exception handler in the FastAPI backend to catch unhandled crashes and return clean JSON 500s. This prevents Starlette from stripping CORS headers during a crash, eliminating misleading "CORS blocked" browser errors.
  - Hardened the `POST /score` endpoint to explicitly reject zero-document cases with a 400 Bad Request, protecting the downstream signal layer from edge-case crashes.
  - Implemented robust 401 Unauthorized handling in both the Next.js dashboard and Flutter app, ensuring users whose sessions expire are cleanly redirected to the login screen rather than encountering raw API errors or silent failures.
- **Deterministic Risk Scoring Engine**: Radically overhauled the backend scoring logic (Stage 3) to eliminate "black box" scoring. 
  - Gemma is no longer permitted to invent the base risk score. Instead, a new `risk_engine.py` applies a rigid, reproducible, deterministic penalty system (starting at 100) based strictly on Stage 2 signal thresholds (e.g., GST mismatches, transaction velocity).
  - Gemma's role is now restricted to (1) generating the plain-language audit narrative to explain the algorithmic score, and (2) proposing a tightly bounded contextual adjustment (capped at ±10 points) with a strict justification based on the user's business context.
  - The Next.js Officer Dashboard was upgraded to render a transparent, tabular **Score Breakdown** directly beneath the Risk Assessment header, clearly separating the deterministic deductions from the LLM's contextual adjustment.
