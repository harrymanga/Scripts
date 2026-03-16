
import subprocess
from pathlib import Path

class JarService:

    @staticmethod
    def unpack(jar_path: Path, destination: Path):
        destination.mkdir(parents=True, exist_ok=True)
        result = subprocess.run(
            ["jar", "xfv", str(jar_path)],
            cwd=destination,
            capture_output=True,
            text=True
        )
        if result.returncode != 0:
            raise RuntimeError(result.stderr)

    @staticmethod
    def pack(folder_path: Path, destination: Path):
        destination.mkdir(parents=True, exist_ok=True)
        jar_name = destination / f"{folder_path.name}.jar"
        result = subprocess.run(
            ["jar", "cfv", str(jar_name), "-C", str(folder_path), "."],
            capture_output=True,
            text=True
        )
        if result.returncode != 0:
            raise RuntimeError(result.stderr)
