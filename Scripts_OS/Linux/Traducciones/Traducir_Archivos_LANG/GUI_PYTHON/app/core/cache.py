import sqlite3
import hashlib
from threading import Lock

class TranslationCache:
    def __init__(self, db_path="cache.db"):
        self.lock = Lock()
        self.conn = sqlite3.connect(
            db_path,
            check_same_thread=False
        )
        self._create_table()

    def _create_table(self):
        with self.lock:
            self.conn.execute("""
                CREATE TABLE IF NOT EXISTS cache (
                    hash TEXT PRIMARY KEY,
                    translated TEXT
                )
            """)
            self.conn.commit()

    def _hash(self, text):
        return hashlib.sha256(text.encode()).hexdigest()

    def get(self, text):
        h = self._hash(text)
        with self.lock:
            cursor = self.conn.execute(
                "SELECT translated FROM cache WHERE hash=?",
                (h,)
            )
            row = cursor.fetchone()
        return row[0] if row else None

    def set(self, text, translated):
        h = self._hash(text)
        with self.lock:
            self.conn.execute(
                "INSERT OR REPLACE INTO cache VALUES (?,?)",
                (h, translated)
            )
            self.conn.commit()

    def close(self):
        self.conn.close()