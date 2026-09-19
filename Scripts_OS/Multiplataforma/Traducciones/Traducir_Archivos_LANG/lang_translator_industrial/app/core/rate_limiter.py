import time

def retry_with_backoff(func, retries=5):
    def wrapper(*args, **kwargs):
        delay = 1
        for attempt in range(retries):
            try:
                return func(*args, **kwargs)
            except Exception:
                time.sleep(delay)
                delay *= 2
        raise Exception("Max retries exceeded")
    return wrapper
