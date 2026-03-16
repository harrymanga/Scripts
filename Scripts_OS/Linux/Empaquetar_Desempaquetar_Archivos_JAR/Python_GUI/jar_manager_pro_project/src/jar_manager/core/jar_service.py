
import subprocess
from pathlib import Path

class JarService:

    @staticmethod
    def unpack(jar_path: Path, destination: Path):

        if not jar_path.exists():
            raise FileNotFoundError(f"No existe: {jar_path}")

        # Crear carpeta con nombre del JAR
        jar_folder = destination / jar_path.stem
        jar_folder.mkdir(parents=True, exist_ok=True)

        result = subprocess.run(
            ["jar", "xf", str(jar_path)],
            cwd=jar_folder,
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
