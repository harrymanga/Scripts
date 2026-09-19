from PySide6.QtWidgets import (
    QApplication, QWidget, QVBoxLayout,
    QPushButton, QFileDialog,
    QTextEdit, QComboBox, QLabel
)
import sys
from app.core.translator_service import TranslatorService

def launch_app():

    app = QApplication(sys.argv)
    window = QWidget()
    layout = QVBoxLayout()

    service = TranslatorService(
        primary_provider="google",
        fallback_provider="deepl"
    )

    lang_selector = QComboBox()
    lang_selector.addItems([
        "es",  # Spanish
        "en",  # English
        "fr",  # French
        "de",  # German
        "it",  # Italian
        "pt",  # Portuguese
        "ja",  # Japanese
        "zh"   # Chinese
    ])

    output = QTextEdit()
    output.setReadOnly(True)

    def select_files():

        target_lang = lang_selector.currentText()

        files, _ = QFileDialog.getOpenFileNames(
            window,
            "Select Files"
        )

        if not files:
            return

        texts = []
        for file in files:
            with open(file, "r", encoding="utf-8") as f:
                texts.append(f.read())

        translations = service.translate_texts(
            texts,
            target_lang=target_lang,
            source_lang="auto"
        )

        output.setText("\n\n---\n\n".join(translations))

    btn = QPushButton("Select Files to Translate")
    btn.clicked.connect(select_files)

    layout.addWidget(QLabel("Translate to:"))
    layout.addWidget(lang_selector)
    layout.addWidget(btn)
    layout.addWidget(output)

    window.setLayout(layout)
    window.setWindowTitle("Industrial Lang Translator")
    window.resize(600, 400)
    window.show()

    sys.exit(app.exec())