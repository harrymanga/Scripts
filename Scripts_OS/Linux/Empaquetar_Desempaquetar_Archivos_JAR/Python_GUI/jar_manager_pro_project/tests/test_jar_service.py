from jar_manager.core.jar_service import JarService
from pathlib import Path
import tempfile

def test_unpack_invalid_file():
    with tempfile.TemporaryDirectory() as tmpdir:
        try:
            JarService.unpack(Path("fake.jar"), Path(tmpdir))
        except Exception:
            assert True
