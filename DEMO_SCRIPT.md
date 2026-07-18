# AuditGemma — Live Demo Script & Run-Sheet

This script outlines the exact choreography for the live hackathon presentation, mapping perfectly to Section 10 of the spec.

## Setup & Pre-Flight (Do this 15 mins before judging)
1. Ensure the Python backend is running locally (`uvicorn app.main:app --host 0.0.0.0 --port 8000`).
2. Ensure Ollama is running in the background.
3. Run `python scripts/e2e_check.py` to assert the whole pipeline is healthy and Gemma is warm.
4. Have the Web Dashboard (`officer-dashboard`) open in Chrome on full screen.
5. Have the Mobile App (`auditgemma_mobile`) running in the Chrome device emulator (or a real Android device if connected via USB).
6. **Data Selection:** We will use **Case 4 (Borderline)** from `sample_data/` for the live demo to showcase Gemma's contextual maturity.

---

## The Run-Sheet

### Phase 1: The SME Experience (Mobile)
**Action:** Open the Mobile App, login as `SME`.
**Talking Point:** *"AuditGemma isn't just an internal tool; it starts with the borrower. The SME applicant easily snaps photos of their GST filings, Invoices, and KYC documents."*
**Action:** Tap 'Upload' and select the 4 images from `sample_data/case_4_borderline*`.
**Action:** Type the business context: *"Seasonal Agro-exporter, Kerala, Q4 seasonal equipment buying expected."*
**Action:** Tap 'Submit'. 
**Talking Point:** *"Behind the scenes, our Stage 1 Vision Agent uses Gemma to instantly extract tabular financial data from these raw images into structured JSON."*

> **Fallback Plan:** If the Vision Agent (Ollama) hangs on the venue Wi-Fi, explain that local LLMs are resource-intensive and tap the pre-cached "Load Demo Case" button if you built one, or simply pivot to the dashboard where cases are already queued.

### Phase 2: The Officer Dashboard (Web)
**Action:** Switch to the Next.js Dashboard. The new case should appear at the top of the queue. Click on it.
**Talking Point:** *"Here is where AuditGemma shines. Instead of black-box AI, we use a deterministic Stage 2 Signal Layer to run hard math—like Benford's Law and MAD outlier checks—over the extracted data. Gemma then reasons over those rigid signals."*
**Action:** Scroll through the extracted data and point to the **Reasoning Narrative**.
**Talking Point:** *"Notice how Gemma flagged a MAD outlier, but instead of outright rejecting it, the agent read our 'Seasonal Agro-exporter' context and expressed intelligent uncertainty, recognizing a seasonal bulk order. This is the maturity lenders actually need."*

### Phase 3: Conversational Grounding (Web)
**Action:** Type a live question into the chat panel on the right side of the case view.
**Example Question:** *"If we exclude the large November equipment purchase, does this business's cash flow look stable?"*
**Talking Point:** *"Compliance officers can interrogate the AI's logic live. Because the conversational agent is grounded strictly in the extracted case data and Stage 2 signals, it won't hallucinate external knowledge."*

### Phase 4: Escalation (Mobile)
**Action:** Switch back to the Mobile App, log out of SME, and log in as `Officer`.
**Talking Point:** *"Officers on the go receive push notifications for high-risk cases."* (Tap the "Simulate Push" button to show the popup).
**Action:** Swipe right on the Case Card to 'Escalate'.
**Action:** Tap the Microphone icon to record a Voice Note.
**Talking Point:** *"A compliance officer on the factory floor can swipe to escalate and append a voice note straight to the file."*

### Phase 5: PDF Export (Web)
**Action:** Switch back to the Web Dashboard. Click the **Export PDF Report** button.
**Talking Point:** *"Finally, the entire audit trail—extracted data, deterministic signals, Gemma's narrative, and the officer chat history—is exported to a clean PDF for the compliance archives."*

---

## 🚨 Current Punch List (Known Technical Gaps)
*Do not let these surprise you during the live demo!*

1. **Push Notifications are Simulated:** The `firebase_messaging` library isn't configured in Flutter. Tapping "Simulate Push" triggers a local popup. **Don't pretend it's a real remote FCM push sent from the backend during the demo; just show the UX flow.**
2. **Voice Notes are a UI Mockup:** The `VoiceRecorderWidget` looks great and plays an animation, but it creates a dummy `.m4a` file and doesn't actually record real device audio. **Don't try to play the audio back during the demo!**
3. **Camera on Web:** If you run the Flutter app via `flutter run -d chrome`, the native camera won't work. **You must use the Gallery/File Picker to upload the sample documents during the live demo.**
