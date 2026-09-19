from PySide6.QtWidgets import QApplication, QWidget, QVBoxLayout, QPushButton, QFileDialog
import sys

def launch_app():
    app = QApplication(sys.argv)
    window = QWidget()
    layout = QVBoxLayout()

    btn = QPushButton("Select Files to Translate")
    btn.clicked.connect(lambda: QFileDialog.getOpenFileNames(window, "Select Files"))

    layout.addWidget(btn)
    window.setLayout(layout)
    window.setWindowTitle("Industrial Lang Translator")
    window.resize(400, 200)
    window.show()
    sys.exit(app.exec())
