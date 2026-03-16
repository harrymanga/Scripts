
import subprocess
import shutil
from pathlib import Path

class JarService:

    def __init__(self):
        if not shutil.which("jar"):
            raise RuntimeError("Comando 'jar' no encontrado. Instala JDK.")

    def unpack(self, jar_path: Path, destination: Path):
        output = destination / jar_path.stem
        output.mkdir(parents=True, exist_ok=True)
        return subprocess.Popen(
            ["jar", "xf", str(jar_path)],
            cwd=output,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True
        )

    def pack(self, folder: Path, destination: Path):
        output = destination / f"{folder.name}.jar"
        return subprocess.Popen(
            ["jar", "cf", str(output), "-C", str(folder), "."],
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True
        )
