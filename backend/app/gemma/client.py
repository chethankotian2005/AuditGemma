"""
Thin wrapper around the local Ollama API for Gemma 4 calls.

Thinking Mode is toggled per-call (via `<|think|>` prefix in the prompt),
matching the spec's stage-by-stage table:
  - Stage 1 extraction (JSON):        thinking OFF
  - Stage 3 scoring (JSON):           thinking OFF
  - Stage 3 narrative generation:     thinking ON
  - Stage 4 conversational agent:     thinking ON
"""
import base64
import json
import httpx
from app.config import settings


class GemmaClient:
    def __init__(self, base_url: str | None = None, model: str | None = None):
        self.base_url = base_url or settings.OLLAMA_BASE_URL
        self.model = model or settings.GEMMA_MODEL

    async def _post(self, payload: dict, timeout: float) -> dict:
        async with httpx.AsyncClient(timeout=timeout) as client:
            try:
                resp = await client.post(f"{self.base_url}/api/generate", json=payload)
                resp.raise_for_status()
                return resp.json()
            except httpx.ConnectError as e:
                raise RuntimeError(
                    f"AI service unavailable — check that Ollama is running and the model is pulled (`ollama pull {payload.get('model')}`)."
                ) from e
            except httpx.HTTPStatusError as e:
                if e.response.status_code == 404:
                    raise RuntimeError(
                        f"AI service unavailable — model '{payload.get('model')}' not found in Ollama. Run `ollama pull {payload.get('model')}`."
                    ) from e
                raise
            except httpx.ReadTimeout:
                raise RuntimeError(
                    f"AI service timed out while responding for model '{payload.get('model')}'. "
                    f"Check that Ollama is healthy and your hardware can run the model."
                )

    async def generate(
        self,
        prompt: str,
        thinking: bool = False,
        json_mode: bool = False,
        image_base64: str | None = None,
        system: str | None = None,
        options: dict | None = None,
    ) -> str:
        """
        Returns raw text response. Caller parses JSON if json_mode=True.
        """
        full_prompt = f"<|think|>\n{prompt}" if thinking else prompt

        payload = {
            "model": self.model,
            "prompt": full_prompt,
            "stream": False,
            "keep_alive": "30m",
        }
        if system:
            payload["system"] = system
        if json_mode:
            payload["format"] = "json"
        if image_base64:
            payload["images"] = [image_base64]
        if options:
            payload["options"] = options

        timeout = settings.GEMMA_TIMEOUT_THINKING if thinking else settings.GEMMA_TIMEOUT_FAST
        result = await self._post(payload, timeout=timeout)
        return result.get("response", "")

    async def generate_json(self, prompt: str, thinking: bool = False, image_base64: str | None = None, system: str | None = None) -> dict:
        raw = await self.generate(prompt, thinking=thinking, json_mode=True, image_base64=image_base64, system=system)
        try:
            return json.loads(raw)
        except json.JSONDecodeError:
            # Gemma occasionally wraps JSON in prose despite format=json; try to salvage
            start = raw.find("{")
            end = raw.rfind("}")
            if start != -1 and end != -1:
                return json.loads(raw[start:end + 1])
            raise ValueError(f"Gemma did not return valid JSON: {raw[:300]}")

    @staticmethod
    def image_to_base64(image_bytes: bytes) -> str:
        return base64.b64encode(image_bytes).decode("utf-8")


gemma_client = GemmaClient()
