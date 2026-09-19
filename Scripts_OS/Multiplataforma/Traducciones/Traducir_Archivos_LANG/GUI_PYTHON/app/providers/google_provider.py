from app.providers.base import BaseProvider
from app.core.rate_limiter import retry_with_backoff


class GoogleProvider(BaseProvider):

    def __init__(self):
        try:
            from deep_translator import GoogleTranslator
            self.GoogleTranslator = GoogleTranslator
        except ImportError:
            raise RuntimeError(
                "GoogleProvider requires 'deep-translator'. "
                "Install with: pip install deep-translator"
            )

    @property
    def name(self):
        return "google"

    @retry_with_backoff(retries=4)
    def _translate(self, text, source_lang, target_lang):
        translator = self.GoogleTranslator(
            source=source_lang,
            target=target_lang
        )
        return translator.translate(text)

    def translate_batch(self, texts, target_lang, source_lang="auto"):
        return [
            self._translate(t, source_lang, target_lang)
            for t in texts
        ]