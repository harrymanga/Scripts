class BatchManager:
    def __init__(self, max_chars=4000):
        self.max_chars = max_chars

    def create_batches(self, texts):
        batches = []
        current = []
        size = 0

        for text in texts:
            if size + len(text) > self.max_chars:
                batches.append(current)
                current = []
                size = 0

            current.append(text)
            size += len(text)

        if current:
            batches.append(current)

        return batches
