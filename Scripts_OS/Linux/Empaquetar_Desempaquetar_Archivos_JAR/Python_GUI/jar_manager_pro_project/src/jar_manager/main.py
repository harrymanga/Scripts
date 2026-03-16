
import sys
from jar_manager.cli import run as run_cli

def run_gui():
    from PySide6.QtWidgets import QApplication
    from jar_manager.ui.main_window import MainWindow
    from jar_manager.controllers.main_controller import MainController

    app = QApplication(sys.argv)
    app.setStyle("Fusion")

    window = MainWindow()
    controller = MainController(window)

    window.show()
    sys.exit(app.exec())

if __name__ == "__main__":
    if "--cli" in sys.argv:
        run_cli()
    else:
        run_gui()
