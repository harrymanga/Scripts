
from PySide6.QtWidgets import QFileDialog
from PySide6.QtCore import QThread
from jar_manager.workers.jar_worker import JarWorker

class MainController:

    def __init__(self, view):
        self.view = view
        self.thread = None
        self.worker = None
        self._connect()

    def _connect(self):
        ui = self.view.ui
        ui.browseInputBtn.clicked.connect(self.browse_input)
        ui.browseOutputBtn.clicked.connect(self.browse_output)
        ui.executeBtn.clicked.connect(self.execute)
        ui.cancelBtn.clicked.connect(self.cancel)
        ui.modeComboBox.currentTextChanged.connect(self.reset_ui)

    def browse_input(self):
        mode = self.view.ui.modeComboBox.currentText()

        if mode == "Desempaquetar":
            files, _ = QFileDialog.getOpenFileNames(
                self.view, "Seleccionar JAR", "", "JAR (*.jar)"
            )
            if files:
                self.view.ui.inputEdit.setText(";".join(files))
        else:
            folder = QFileDialog.getExistingDirectory(
                self.view, "Seleccionar carpeta"
            )
            if folder:
                current = self.view.ui.inputEdit.text()
                if current:
                    self.view.ui.inputEdit.setText(current + ";" + folder)
                else:
                    self.view.ui.inputEdit.setText(folder)

    def browse_output(self):
        folder = QFileDialog.getExistingDirectory(self.view, "Destino")
        if folder:
            self.view.ui.outputEdit.setText(folder)

    def execute(self):
        items = self.view.ui.inputEdit.text().split(";")
        destination = self.view.ui.outputEdit.text()
        mode = self.view.ui.modeComboBox.currentText()

        self.thread = QThread()
        self.worker = JarWorker(items, destination, mode)
        self.worker.moveToThread(self.thread)

        self.thread.started.connect(self.worker.run)
        self.worker.progress.connect(self.view.ui.progressBar.setValue)
        self.worker.status.connect(self.view.ui.statusLabel.setText)
        self.worker.finished.connect(self.on_finish)
        self.worker.error.connect(self.on_error)

        self.thread.start()

    def cancel(self):
        if self.worker:
            self.worker.cancel()

    def on_finish(self, msg):
        self.view.ui.statusLabel.setText(msg)
        self.thread.quit()

    def on_error(self, msg):
        self.view.ui.statusLabel.setText(f"Error: {msg}")
        self.thread.quit()

    def reset_ui(self):
        self.view.ui.inputEdit.clear()
        self.view.ui.outputEdit.clear()
        self.view.ui.progressBar.setValue(0)
        self.view.ui.statusLabel.clear()
