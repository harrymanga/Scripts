
import sys
import argparse
from PySide6.QtWidgets import QApplication
from jar_manager.ui.main_window import MainWindow
from jar_manager.app.theme import apply_dark_theme
from jar_manager.core.jar_service import JarService
from pathlib import Path

def run_cli(args):
    service = JarService()
    dest = Path(args.output)
    dest.mkdir(parents=True, exist_ok=True)

    for item in args.input:
        path = Path(item)
        if args.mode == "unpack":
            process = service.unpack(path, dest)
        else:
            process = service.pack(path, dest)

        stdout, stderr = process.communicate()
        if process.returncode != 0:
            print("ERROR:", stderr)
        else:
            print("OK:", path.name)

def run_gui():
    app = QApplication(sys.argv)
    apply_dark_theme(app)
    window = MainWindow()
    window.show()
    sys.exit(app.exec())

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Jar Manager Pro 4.0")
    parser.add_argument("--cli", action="store_true")
    parser.add_argument("--mode", choices=["pack", "unpack"])
    parser.add_argument("--input", nargs="+")
    parser.add_argument("--output")

    args = parser.parse_args()

    if args.cli:
        run_cli(args)
    else:
        run_gui()
