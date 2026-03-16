
from PySide6.QtCore import QObject, Signal
from pathlib import Path
from jar_manager.core.jar_service import JarService

class JarWorker(QObject):
    progress = Signal(int)
    finished = Signal(str)
    error = Signal(str)

    def __init__(self, files, destination, mode):
        super().__init__()
        self.files = files
        self.destination = Path(destination)
        self.mode = mode

    def run(self):
        try:
            total = len(self.files)
            for i, file in enumerate(self.files):
                if self.mode == "Desempaquetar":
                    JarService.unpack(Path(file), self.destination)
                else:
                    JarService.pack(Path(file), self.destination)

                percent = int(((i + 1) / total) * 100)
                self.progress.emit(percent)

            self.finished.emit("Proceso completado")
        except Exception as e:
            self.error.emit(str(e))
