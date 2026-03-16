
from PySide6.QtCore import QObject, Signal
from pathlib import Path
from jar_manager.core.jar_service import JarService

class JarWorker(QObject):

    progress = Signal(int)
    status = Signal(str)
    finished = Signal(str)
    error = Signal(str)

    def __init__(self, items, destination, mode):
        super().__init__()
        self.items = items
        self.destination = Path(destination)
        self.mode = mode
        self._cancel = False
        self.service = JarService()

    def cancel(self):
        self._cancel = True

    def run(self):
        total = len(self.items)

        try:
            for i, item in enumerate(self.items):

                if self._cancel:
                    self.finished.emit("Proceso cancelado")
                    return

                path = Path(item)
                self.status.emit(f"Procesando: {path.name}")

                if self.mode == "Desempaquetar":
                    self.service.unpack(path, self.destination)
                else:
                    self.service.pack(path, self.destination)

                percent = int(((i + 1) / total) * 100)
                self.progress.emit(percent)

            self.finished.emit("Proceso completado correctamente")

        except Exception as e:
            self.error.emit(str(e))
