from app.core.batch_manager import BatchManager
from app.core.cache import TranslationCache
from app.providers.factory import ProviderFactory

class TranslatorService:

    def __init__(self,
                 primary_provider="google",
                 fallback_provider=None,
                 max_chars=4000):

        self.batch_manager = BatchManager(max_chars)
        self.cache = TranslationCache()

        available = ProviderFactory.available_providers()

        if primary_provider not in available:
            if available:
                print(f"[INFO] '{primary_provider}' not available. Using '{available[0]}' instead.")
                primary_provider = available[0]
            else:
                raise RuntimeError("No translation providers available.")

        self.primary = ProviderFactory.create(primary_provider)

        self.fallback = None
        if fallback_provider and fallback_provider in available:
            self.fallback = ProviderFactory.create(fallback_provider)


    def _translate_with_fallback(self,
                                 texts,
                                 target_lang,
                                 source_lang="auto"):

        try:
            return self.primary.translate_batch(
                texts,
                target_lang,
                source_lang
            )
        except Exception:

            if self.fallback:
                return self.fallback.translate_batch(
                    texts,
                    target_lang,
                    source_lang
                )

            raise

    def translate_texts(self,
                        texts,
                        target_lang,
                        source_lang="auto"):

        batches = self.batch_manager.create_batches(texts)
        final_results = []

        for batch in batches:
            uncached = []
            cached_map = {}

            for text in batch:
                cached = self.cache.get(text)
                if cached:
                    cached_map[text] = cached
                else:
                    uncached.append(text)

            translated = []
            if uncached:
                translated = self._translate_with_fallback(
                    uncached,
                    target_lang,
                    source_lang
                )

                for original, trans in zip(uncached, translated):
                    self.cache.set(original, trans)

            idx = 0
            for text in batch:
                if text in cached_map:
                    final_results.append(cached_map[text])
                else:
                    final_results.append(translated[idx])
                    idx += 1

        return final_results