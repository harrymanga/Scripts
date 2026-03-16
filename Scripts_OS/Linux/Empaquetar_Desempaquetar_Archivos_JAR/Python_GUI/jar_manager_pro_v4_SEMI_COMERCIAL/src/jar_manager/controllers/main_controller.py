
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
        ui.addBtn.clicked.connect(self.add_items)
        ui.outputBtn.clicked.connect(self.select_output)
        ui.runBtn.clicked.connect(self.run)
        ui.cancelBtn.clicked.connect(self.cancel)

    def add_items(self):
        mode = self.view.ui.modeBox.currentText()

        if mode == "Desempaquetar":
            files, _ = QFileDialog.getOpenFileNames(
                self.view, "Seleccionar JAR", "", "JAR (*.jar)"
            )
            for f in files:
                self.view.ui.table.addItem(f)
        else:
            folder = QFileDialog.getExistingDirectory(self.view)
            if folder:
                self.view.ui.table.addItem(folder)

    def select_output(self):
        folder = QFileDialog.getExistingDirectory(self.view)
        if folder:
            self.view.ui.outputEdit.setText(folder)

    def run(self):
        items = self.view.ui.table.items()
        dest = self.view.ui.outputEdit.text()
        mode = self.view.ui.modeBox.currentText()

        self.thread = QThread()
        self.worker = JarWorker(items, dest, mode)
        self.worker.moveToThread(self.thread)

        self.thread.started.connect(self.worker.run)
        self.worker.progress_global.connect(self.view.ui.progressBar.setValue)
        self.worker.log.connect(self.view.ui.logPanel.append)
        self.worker.finished.connect(self.on_finish)

        self.thread.start()

    def cancel(self):
        if self.worker:
            self.worker.cancel()

    def on_finish(self, msg):
        self.view.ui.logPanel.append(msg)
        self.thread.quit()
