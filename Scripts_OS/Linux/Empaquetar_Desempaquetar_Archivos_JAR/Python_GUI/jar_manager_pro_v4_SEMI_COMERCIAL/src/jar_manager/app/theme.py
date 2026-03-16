
def apply_dark_theme(app):
    app.setStyle("Fusion")
    app.setStyleSheet("""
        QWidget { background-color: #2b2b2b; color: #dddddd; }
        QLineEdit, QComboBox, QTableWidget {
            background-color: #3c3f41;
            border: 1px solid #555;
        }
        QPushButton {
            background-color: #555;
            padding: 5px;
        }
        QPushButton:hover { background-color: #666; }
        QProgressBar {
            border: 1px solid #555;
            text-align: center;
        }
        QProgressBar::chunk { background-color: #3daee9; }
        QTextEdit { background-color: #1e1e1e; }
    """)
