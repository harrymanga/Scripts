import logging
import os
import sys
from typing import Dict, List, Optional

from PyQt5.QtCore import QObject, QThread, pyqtSignal, Qt
from PyQt5.QtWidgets import (
    QFileDialog,
    QMainWindow,
    QMessageBox,
    QInputDialog,
    QProgressBar,
)

from traductor_pro.application.use_cases import (
    ManageApiKeysUseCase,
    TranslateBatchUseCase,
    TranslateFileUseCase,
)
from traductor_pro.domain.entities import (
    FileTranslationJob,
    FileType,
    GlobalReport,
    TranslationEngine,
    TranslationReport,
)
from traductor_pro.domain.interfaces import ProgressCallback

logger = logging.getLogger(__name__)

LANG_CODES = {
    "Auto-detectar": None,
    "es - Español": "es",
    "en - Inglés": "en",
    "fr - Francés": "fr",
    "de - Alemán": "de",
    "pt - Portugués": "pt",
    "it - Italiano": "it",
    "ja - Japonés": "ja",
    "ko - Coreano": "ko",
    "zh - Chino": "zh",
    "ru - Ruso": "ru",
}

ENGINE_MAP = {
    "Google Translate": TranslationEngine.GOOGLE,
    "DeepL": TranslationEngine.DEEPL,
    "OpenAI": TranslationEngine.OPENAI,
}

EXT_TYPE_MAP = {
    ".cfg": FileType.CFG,
    ".lang": FileType.LANG,
    ".txt": FileType.TXT,
    ".properties": FileType.PROPERTIES,
}


class QtProgressCallback(ProgressCallback):
    def __init__(self, signals: "WorkerSignals") -> None:
        self._signals = signals

    def on_progress(self, current: int, total: int, message: str) -> None:
        self._signals.progress.emit(current, total, message)

    def on_file_complete(self, report: TranslationReport) -> None:
        self._signals.file_complete.emit(report)

    def on_error(self, error: str) -> None:
        self._signals.error.emit(error)


class WorkerSignals(QObject):
    progress = pyqtSignal(int, int, str)
    file_complete = pyqtSignal(object)
    error = pyqtSignal(str)
    finished = pyqtSignal(object)


class TranslationWorker(QThread):
    def __init__(
        self,
        batch_use_case: TranslateBatchUseCase,
        jobs: List[FileTranslationJob],
    ) -> None:
        super().__init__()
        self.signals = WorkerSignals()
        self._batch_use_case = batch_use_case
        self._jobs = jobs
        self._cancelled = False

    def run(self) -> None:
        callback = QtProgressCallback(self.signals)
        report = self._batch_use_case.execute(self._jobs, callback)
        self.signals.finished.emit(report)

    def cancel(self) -> None:
        self._cancelled = True


class ApiKeyDialog:
    @staticmethod
    def show(parent: QMainWindow, key_use_case: ManageApiKeysUseCase) -> None:
        services = ["deepl", "openai"]
        items = [f"{s} ({'✓ Configurada' if key_use_case.get(s) else '✗ Sin configurar'})" for s in services]
        item, ok = QInputDialog.getItem(
            parent, "API Keys", "Seleccione servicio:", items, 0, False
        )
        if not ok:
            return
        idx = items.index(item)
        service = services[idx]
        existing = key_use_case.get(service) or ""
        api_key, ok = QInputDialog.getText(
            parent,
            f"API Key - {service.upper()}",
            f"Ingrese la API key para {service}:",
            text=existing,
        )
        if ok and api_key.strip():
            key_use_case.set(service, api_key.strip())
            QMessageBox.information(parent, "API Keys", f"API key para {service} guardada exitosamente.")
        elif ok and not api_key.strip():
            key_use_case.delete(service)
            QMessageBox.information(parent, "API Keys", f"API key para {service} eliminada.")


class MainWindowController(QMainWindow):
    def __init__(
        self,
        translate_file_use_case: TranslateFileUseCase,
        batch_use_case: TranslateBatchUseCase,
        key_use_case: ManageApiKeysUseCase,
        cache_port,
        report_generator,
    ) -> None:
        super().__init__()
        self._translate_file = translate_file_use_case
        self._batch = batch_use_case
        self._keys = key_use_case
        self._cache = cache_port
        self._report_gen = report_generator
        self._worker: Optional[TranslationWorker] = None

        self._load_ui()
        self._connect_signals()

    def _load_ui(self) -> None:
        from PyQt5 import uic

        ui_path = os.path.join(os.path.dirname(__file__), "..", "..", "..", "..", "ui", "main_window.ui")
        ui_path = os.path.abspath(ui_path)

        if not os.path.isfile(ui_path):
            alt_path = os.path.join(os.path.dirname(sys.argv[0]), "ui", "main_window.ui")
            alt_path = os.path.abspath(alt_path)
            if os.path.isfile(alt_path):
                ui_path = alt_path
            else:
                raise FileNotFoundError(f"No se encontró main_window.ui (buscado en: {ui_path} y {alt_path})")

        uic.loadUi(ui_path, self)
        self.setWindowTitle("TraductorPro")

    def _connect_signals(self) -> None:
        self.btnAddFiles.clicked.connect(self._on_add_files)
        self.btnRemoveFile.clicked.connect(self._on_remove_file)
        self.btnClearFiles.clicked.connect(self._on_clear_files)
        self.btnBrowseOutput.clicked.connect(self._on_browse_output)
        self.btnTranslate.clicked.connect(self._on_translate)
        self.btnCancel.clicked.connect(self._on_cancel)
        self.btnAddReplacement.clicked.connect(self._on_add_replacement)
        self.btnRemoveReplacement.clicked.connect(self._on_remove_replacement)
        self.btnClearCache.clicked.connect(self._on_clear_cache)
        self.actionExit.triggered.connect(self.close)
        self.actionApiKeys.triggered.connect(self._on_api_keys)
        self.actionClearCache.triggered.connect(self._on_clear_cache)
        self.actionAbout.triggered.connect(self._on_about)

    def _on_add_files(self) -> None:
        files, _ = QFileDialog.getOpenFileNames(
            self,
            "Seleccionar archivos",
            "",
            "Archivos soportados (*.cfg *.lang *.txt *.properties);;CFG (*.cfg);;LANG (*.lang);;TXT (*.txt);;Properties (*.properties);;Todos (*)",
        )
        for f in files:
            if len(self.listFiles.findItems(f, Qt.MatchExactly)) == 0:
                self.listFiles.addItem(f)

    def _on_remove_file(self) -> None:
        row = self.listFiles.currentRow()
        if row >= 0:
            self.listFiles.takeItem(row)

    def _on_clear_files(self) -> None:
        self.listFiles.clear()

    def _on_browse_output(self) -> None:
        directory = QFileDialog.getExistingDirectory(self, "Seleccionar directorio de salida")
        if directory:
            self.txtOutputDir.setText(directory)

    def _on_translate(self) -> None:
        if self.listFiles.count() == 0:
            QMessageBox.warning(self, "Atención", "No hay archivos seleccionados.")
            return

        jobs = self._build_jobs()
        if not jobs:
            QMessageBox.warning(self, "Atención", "No se pudieron crear tareas de traducción.")
            return

        self._worker = TranslationWorker(self._batch, jobs)
        self._worker.signals.progress.connect(self._on_progress)
        self._worker.signals.file_complete.connect(self._on_file_complete)
        self._worker.signals.error.connect(self._on_error_msg)
        self._worker.signals.finished.connect(self._on_finished)
        self._worker.start()

        self.btnTranslate.setEnabled(False)
        self.btnCancel.setEnabled(True)
        self.lblStatus.setText("Traduciendo...")

    def _on_cancel(self) -> None:
        if self._worker and self._worker.isRunning():
            self._worker.cancel()
            self._worker.quit()
            self._worker.wait(3000)
        self._reset_ui()

    def _build_jobs(self) -> List[FileTranslationJob]:
        engine = ENGINE_MAP.get(self.comboEngine.currentText(), TranslationEngine.GOOGLE)
        target_lang = LANG_CODES.get(self.comboTargetLang.currentText(), "en")
        source_lang = LANG_CODES.get(self.comboSourceLang.currentText(), None)
        output_dir = self.txtOutputDir.text().strip() or None
        protect = self.chkProtectPlaceholders.isChecked()
        backup = self.chkBackup.isChecked()
        replacements = self._get_replacements()

        jobs: List[FileTranslationJob] = []
        for i in range(self.listFiles.count()):
            path = self.listFiles.item(i).text()
            ext = os.path.splitext(path)[1].lower()
            file_type = EXT_TYPE_MAP.get(ext)
            if file_type is None:
                self._log(f"Tipo de archivo no soportado: {path}")
                continue

            if output_dir:
                base = os.path.basename(path)
                name, _ = os.path.splitext(base)
                out_path = os.path.join(output_dir, f"{name}_{target_lang}{ext}")
            else:
                directory = os.path.dirname(path)
                base = os.path.basename(path)
                name, _ = os.path.splitext(base)
                translations_dir = os.path.join(directory, "translations")
                os.makedirs(translations_dir, exist_ok=True)
                out_path = os.path.join(translations_dir, f"{name}_{target_lang}{ext}")

            jobs.append(FileTranslationJob(
                input_path=path,
                output_path=out_path,
                file_type=file_type,
                target_lang=target_lang,
                engine=engine,
                source_lang=source_lang,
                custom_replacements=replacements,
                protect_placeholders=protect,
                backup_original=backup,
            ))
        return jobs

    def _get_replacements(self) -> Dict[str, str]:
        replacements: Dict[str, str] = {}
        for row in range(self.tableReplacements.rowCount()):
            search_item = self.tableReplacements.item(row, 0)
            replace_item = self.tableReplacements.item(row, 1)
            if search_item and replace_item:
                s = search_item.text().strip()
                r = replace_item.text().strip()
                if s:
                    replacements[s] = r
        return replacements

    def _on_add_replacement(self) -> None:
        self.tableReplacements.insertRow(self.tableReplacements.rowCount())

    def _on_remove_replacement(self) -> None:
        row = self.tableReplacements.currentRow()
        if row >= 0:
            self.tableReplacements.removeRow(row)

    def _on_clear_cache(self) -> None:
        self._cache.clear()
        self._log("Caché limpiada.")
        QMessageBox.information(self, "Caché", "Caché limpiada exitosamente.")

    def _on_api_keys(self) -> None:
        ApiKeyDialog.show(self, self._keys)

    def _on_about(self) -> None:
        QMessageBox.about(
            self,
            "Acerca de TraductorPro",
            "TraductorPro v1.0.0\n\n"
            "Aplicación multiplataforma de traducción de archivos.\n"
            "Motores: Google Translate, DeepL, OpenAI\n\n"
            "Arquitectura: Clean Architecture\n"
            "GUI: PyQt5 + Qt Designer",
        )

    def _on_progress(self, current: int, total: int, message: str) -> None:
        if total > 0:
            self.progressBar.setMaximum(total)
            self.progressBar.setValue(current)
        self.lblStatus.setText(message)

    def _on_file_complete(self, report: TranslationReport) -> None:
        self._log(
            f"Archivo: {os.path.basename(report.input_path)} | "
            f"Exitosas: {report.succeeded} | Cacheadas: {report.cached} | "
            f"Fallidas: {report.failed}"
        )

    def _on_error_msg(self, error: str) -> None:
        self._log(f"ERROR: {error}")

    def _on_finished(self, report: GlobalReport) -> None:
        self._log("\n===== TRADUCCIÓN COMPLETADA =====")
        self._log(f"Archivos procesados: {report.total_files}")
        self._log(f"Exitosas: {report.total_succeeded} | Cacheadas: {report.total_cached} | Fallidas: {report.total_failed}")

        if report.reports:
            first_output_dir = os.path.dirname(report.reports[0].output_path)
            self._report_gen.save(report, first_output_dir)
            self._log(f"Reporte guardado en: {first_output_dir}")

        self._reset_ui()
        QMessageBox.information(
            self,
            "Completado",
            f"Traducción finalizada.\n\n"
            f"Archivos: {report.total_files}\n"
            f"Exitosas: {report.total_succeeded}\n"
            f"Cacheadas: {report.total_cached}\n"
            f"Fallidas: {report.total_failed}",
        )

    def _reset_ui(self) -> None:
        self.btnTranslate.setEnabled(True)
        self.btnCancel.setEnabled(False)
        self.progressBar.setValue(0)
        self.lblStatus.setText("Listo")

    def _log(self, message: str) -> None:
        self.txtLog.append(message)
        logger.info(message)
