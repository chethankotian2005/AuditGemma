"""
Central config for AuditGemma backend.
Reads from environment with sane hackathon-day defaults.
"""
import os
from dotenv import load_dotenv

load_dotenv()


class Settings:
    # Ollama / Gemma
    OLLAMA_BASE_URL: str = os.getenv("OLLAMA_BASE_URL", "http://localhost:11434")
    # Primary model. Fall back to E2B on low-spec hackathon laptops by
    # overriding GEMMA_MODEL=gemma3:1b in .env
    GEMMA_MODEL: str = os.getenv("GEMMA_MODEL", "gemma3:4b")
    GEMMA_MODEL_FALLBACK: str = os.getenv("GEMMA_MODEL_FALLBACK", "gemma3:1b")

    # Request timeouts — Thinking Mode calls run 3-15s, give headroom
    GEMMA_TIMEOUT_FAST: float = float(os.getenv("GEMMA_TIMEOUT_FAST", "60.0"))       # thinking OFF calls (extraction, JSON scoring)
    GEMMA_TIMEOUT_THINKING: float = float(os.getenv("GEMMA_TIMEOUT_THINKING", "90.0"))   # thinking ON calls (narrative, conversation)

    # Deterministic signal layer thresholds
    BENFORD_MIN_SAMPLE_SIZE: int = 30          # below this, Benford's Law is not statistically meaningful
    BENFORD_CHI_SQUARE_ALERT: float = 15.51    # p=0.05 critical value, df=8 (9 leading digits)
    VELOCITY_WINDOW_HOURS: int = 24
    VELOCITY_MAX_TXNS_PER_WINDOW: int = 8
    ZSCORE_ANOMALY_THRESHOLD: float = 2.5

    # App
    APP_NAME: str = "AuditGemma"
    CORS_ORIGINS: list = ["*"]  # tighten before public deploy
    
    # Firebase / Firestore
    FIREBASE_SERVICE_ACCOUNT_PATH: str = os.getenv("FIREBASE_SERVICE_ACCOUNT_PATH", "")
    FIREBASE_PROJECT_ID: str = os.getenv("FIREBASE_PROJECT_ID", "auditgemma-ca1bb")


settings = Settings()
