import os

WORKERS = int(os.getenv("WORKERS", 5))
BATCH_SIZE = int(os.getenv("BATCH_SIZE", 4000))
CACHE_PATH = os.getenv("CACHE_PATH", "cache.db")
