from deep_translator import GoogleTranslator

class GoogleProvider:
    def __init__(self, source='auto', target='es'):
        self.translator = GoogleTranslator(source=source, target=target)

    def translate_batch(self, texts):
        return [self.translator.translate(t) for t in texts]
