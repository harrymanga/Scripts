
from PySide6.QtCore import QThread
from PySide6.QtWidgets import QFileDialog
from jar_manager.core.worker import JarWorker

class MainController:

    def __init__(self, view):
        self.view = view
        self._connect_signals()
        self.thread = None
        self.worker = None

    def _connect_signals(self):
        self.view.ui.executeBtn.clicked.connect(self.execute)
        self.view.ui.cancelBtn.clicked.connect(self.cancel)
        self.view.ui.browseJarBtn.clicked.connect(self.browse_file)
        self.view.ui.browseOutputBtn.clicked.connect(self.browse_folder)
        self.view.ui.modeComboBox.currentTextChanged.connect(self.on_mode_changed)

    def on_mode_changed(self):
        self.view.ui.inputPathEdit.clear()
        self.view.ui.outputPathEdit.clear()
        self.view.ui.statusLabel.clear()
        self.view.ui.progressBar.setValue(0)

    def browse_file(self):
    
        mode = self.view.ui.modeComboBox.currentText()
    
        if mode == "Desempaquetar":
            files, _ = QFileDialog.getOpenFileNames(
                self.view,
                "Seleccionar JAR",
                "",
                "JAR Files (*.jar)"
            )
            if files:
                self.view.ui.inputPathEdit.setText(";".join(files))
    
        else:  # Empaquetar
            folder = QFileDialog.getExistingDirectory(
                self.view,
                "Seleccionar carpeta a empaquetar"
            )
            if folder:
                self.view.ui.inputPathEdit.setText(folder)
    
    def browse_folder(self):
        folder = QFileDialog.getExistingDirectory(self.view, "Seleccionar destino")
        if folder:
            self.view.ui.outputPathEdit.setText(folder)

    def execute(self):
        files = self.view.ui.inputPathEdit.text().split(";")
        destination = self.view.ui.outputPathEdit.text()
        mode = self.view.ui.modeComboBox.currentText()

        self.thread = QThread()
        self.worker = JarWorker(files, destination, mode)
        self.worker.moveToThread(self.thread)

        self.thread.started.connect(self.worker.run)
        self.worker.progress.connect(self.view.ui.progressBar.setValue)
        self.worker.finished.connect(self.view.ui.statusLabel.setText)
        self.worker.error.connect(self.view.ui.statusLabel.setText)

        self.worker.finished.connect(self.thread.quit)
        self.thread.start()

    def cancel(self):
        if self.worker:
            self.worker.cancel()
