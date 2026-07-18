import uuid
import traceback
import logging

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from starlette.middleware.base import BaseHTTPMiddleware
from starlette.requests import Request
from starlette.responses import JSONResponse

from app.config import settings
from app.api.routes import router

logger = logging.getLogger("auditgemma")

app = FastAPI(
    title=settings.APP_NAME,
    description="Gemma-native SME compliance and risk triage copilot",
    version="0.1.0",
)


class GlobalExceptionMiddleware(BaseHTTPMiddleware):
    """
    Catch-all for any unhandled exception anywhere in the app.

    Why this is a middleware and not @app.exception_handler(Exception):
    FastAPI's exception_handler fires INSIDE Starlette's exception handling
    layer, which sits BELOW CORSMiddleware in the stack. That means the
    response it produces never passes through CORSMiddleware and arrives at
    the browser without Access-Control-Allow-Origin headers — causing the
    exact same misleading "CORS blocked" error we're trying to fix.

    By contrast, this middleware sits ABOVE CORSMiddleware (added first via
    app.add_middleware, so it wraps outermost). When it catches an exception
    and returns a JSONResponse, that response flows back through
    CORSMiddleware on the way out, which attaches the correct CORS headers.
    """

    async def dispatch(self, request: Request, call_next):
        try:
            return await call_next(request)
        except Exception:
            error_id = uuid.uuid4().hex[:8]
            logger.error(
                "Unhandled exception [error_id=%s] %s %s\n%s",
                error_id,
                request.method,
                request.url.path,
                traceback.format_exc(),
            )
            return JSONResponse(
                status_code=500,
                content={
                    "detail": "Internal server error",
                    "error_id": error_id,
                },
            )


# Middleware order matters: add_middleware wraps outermost-first.
# GlobalExceptionMiddleware is added FIRST so it wraps OUTSIDE CORSMiddleware.
# Request flow: GlobalExceptionMiddleware → CORSMiddleware → app routes
# Response flow: app routes → CORSMiddleware (adds CORS headers) → GlobalExceptionMiddleware
app.add_middleware(GlobalExceptionMiddleware)

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.CORS_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(router, prefix="/api/v1")


@app.on_event("startup")
async def startup_event():
    from app.gemma.client import gemma_client
    logger.info(f"Warming up {settings.GEMMA_MODEL} — this may take 30-60s on first load...")
    try:
        # A trivial prompt just to get the model loaded into Ollama's memory
        await gemma_client.generate(prompt="hi", thinking=False)
        logger.info(f"Model warm-up complete for {settings.GEMMA_MODEL}. Ready for traffic.")
    except Exception as e:
        logger.warning(f"Model warm-up failed: {e}. First request will pay the cold-load cost.")


@app.get("/health")
async def health():
    return {"status": "ok", "app": settings.APP_NAME}
