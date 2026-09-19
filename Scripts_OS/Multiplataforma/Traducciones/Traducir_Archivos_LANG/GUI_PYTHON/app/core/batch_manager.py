class BatchManager:
    def __init__(self, max_chars=4000):
        self.max_chars = max_chars

    def create_batches(self, texts):
        batches = []
        current = []
        size = 0

        for text in texts:
            text_len = len(text)

            # Si el texto individual excede el máximo
            if text_len > self.max_chars:
                batches.append([text])
                continue

            if size + text_len > self.max_chars and current:
                batches.append(current)
                current = []
                size = 0

            current.append(text)
            size += text_len

        if current:
            batches.append(current)

        return batches