
from PySide6.QtCore import QObject, Signal
from pathlib import Path
from jar_manager.core.jar_service import JarService

class JarWorker(QObject):

    progress_global = Signal(int)
    log = Signal(str)
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
        errors = []

        for i, item in enumerate(self.items):

            if self._cancel:
                self.finished.emit("Proceso cancelado")
                return

            path = Path(item)

            try:
                self.log.emit(f"Procesando: {path.name}")

                if self.mode == "Desempaquetar":
                    process = self.service.unpack(path, self.destination)
                else:
                    process = self.service.pack(path, self.destination)

                stdout, stderr = process.communicate()

                if process.returncode != 0:
                    errors.append(f"{path.name}: {stderr}")
                    self.log.emit(stderr)
                else:
                    self.log.emit("OK")

            except Exception as e:
                errors.append(str(e))
                self.log.emit(str(e))

            percent = int(((i + 1) / total) * 100)
            self.progress_global.emit(percent)

        if errors:
            self.finished.emit("Finalizado con errores")
        else:
            self.finished.emit("Proceso completado")
