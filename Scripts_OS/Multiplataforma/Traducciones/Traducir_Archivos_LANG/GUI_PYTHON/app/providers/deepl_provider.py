import os
import requests
from app.providers.base import BaseProvider
from app.core.rate_limiter import retry_with_backoff

class DeepLProvider(BaseProvider):

    def __init__(self):
        self.api_key = os.getenv("DEEPL_API_KEY")
        if not self.api_key:
            raise ValueError("DEEPL_API_KEY not set")

    @property
    def name(self):
        return "deepl"

    @retry_with_backoff(retries=3)
    def _translate(self, text, source_lang, target_lang):

        payload = {
            "auth_key": self.api_key,
            "text": text,
            "target_lang": target_lang.upper()
        }

        # DeepL detecta automáticamente si no se envía source_lang
        if source_lang != "auto":
            payload["source_lang"] = source_lang.upper()

        response = requests.post(
            "https://api-free.deepl.com/v2/translate",
            data=payload,
            timeout=10
        )

        response.raise_for_status()
        return response.json()["translations"][0]["text"]

    def translate_batch(self, texts, target_lang, source_lang="auto"):
        return [
            self._translate(t, source_lang, target_lang)
            for t in texts
        ]