
from PySide6.QtWidgets import QMainWindow
from PySide6.QtUiTools import QUiLoader
from PySide6.QtCore import QFile
from pathlib import Path

class MainWindow(QMainWindow):

    def __init__(self):
        super().__init__()

        loader = QUiLoader()
        ui_file = QFile(str(Path(__file__).parent / "main_window.ui"))
        ui_file.open(QFile.ReadOnly)

        self.ui = loader.load(ui_file, self)
        ui_file.close()

        self.setCentralWidget(self.ui)
