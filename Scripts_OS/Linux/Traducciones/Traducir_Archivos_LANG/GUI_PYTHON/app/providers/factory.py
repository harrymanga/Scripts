class ProviderFactory:

    _providers = {}

    @classmethod
    def register_provider(cls, name, provider_cls):
        cls._providers[name] = provider_cls

    @classmethod
    def create(cls, provider_name: str, **kwargs):
        provider_name = provider_name.lower()

        if provider_name not in cls._providers:
            raise ValueError(
                f"Provider '{provider_name}' not available. "
                f"Registered: {list(cls._providers.keys())}"
            )

        return cls._providers[provider_name](**kwargs)

    @classmethod
    def available_providers(cls):
        return list(cls._providers.keys())


# Registro seguro
try:
    from app.providers.google_provider import GoogleProvider
    ProviderFactory.register_provider("google", GoogleProvider)
except Exception:
    pass

try:
    from app.providers.deepl_provider import DeepLProvider
    ProviderFactory.register_provider("deepl", DeepLProvider)
except Exception:
    pass