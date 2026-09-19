import sqlite3
import hashlib

class TranslationCache:
    def __init__(self, db_path="cache.db"):
        self.conn = sqlite3.connect(db_path)
        self.conn.execute("""
            CREATE TABLE IF NOT EXISTS cache (
                hash TEXT PRIMARY KEY,
                translated TEXT
            )
        """)

    def _hash(self, text):
        return hashlib.sha256(text.encode()).hexdigest()

    def get(self, text):
        h = self._hash(text)
        cursor = self.conn.execute("SELECT translated FROM cache WHERE hash=?", (h,))
        row = cursor.fetchone()
        return row[0] if row else None

    def set(self, text, translated):
        h = self._hash(text)
        self.conn.execute(
            "INSERT OR REPLACE INTO cache VALUES (?,?)",
            (h, translated)
        )
        self.conn.commit()
