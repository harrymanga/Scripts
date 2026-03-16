
from PySide6.QtCore import QThread
from jar_manager.core.worker import JarWorker

class MainController:

    def __init__(self, view):
        self.view = view
        self._connect_signals()

    def _connect_signals(self):
        self.view.ui.executeBtn.clicked.connect(self.execute)

    def execute(self):
        files = [self.view.ui.inputPathEdit.text()]
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
