
import subprocess
import shutil
from pathlib import Path

class JarService:

    def __init__(self):
        if not shutil.which("jar"):
            raise RuntimeError("No se encontró el comando 'jar' en el sistema. Instala JDK.")

    def unpack(self, jar_path: Path, destination: Path):
        output_folder = destination / jar_path.stem
        output_folder.mkdir(parents=True, exist_ok=True)
        result = subprocess.run(
            ["jar", "xf", str(jar_path)],
            cwd=output_folder,
            capture_output=True,
            text=True
        )
        if result.returncode != 0:
            raise RuntimeError(result.stderr)

    def pack(self, folder_path: Path, destination: Path):
        output_file = destination / f"{folder_path.name}.jar"
        result = subprocess.run(
            ["jar", "cf", str(output_file), "-C", str(folder_path), "."],
            capture_output=True,
            text=True
        )
        if result.returncode != 0:
            raise RuntimeError(result.stderr)
