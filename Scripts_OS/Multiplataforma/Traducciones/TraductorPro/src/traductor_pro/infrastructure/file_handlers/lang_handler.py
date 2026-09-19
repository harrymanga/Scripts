import re
from typing import List

from traductor_pro.domain.entities import FileType, ParsedLine
from traductor_pro.domain.interfaces import FileHandlerPort


class LangFileHandler(FileHandlerPort):
    PLACEHOLDER_PATTERN = re.compile(r"<[^>]+>|%[sd]|\{[^}]+\}")

    def supported_type(self) -> FileType:
        return FileType.LANG

    def detect_type(self, path: str) -> bool:
        return path.lower().endswith(".lang")

    def read(self, path: str) -> List[ParsedLine]:
        lines: List[ParsedLine] = []
        with open(path, "r", encoding="utf-8") as f:
            for num, raw in enumerate(f, start=1):
                raw = raw.rstrip("\n\r")
                if "=" in raw:
                    key, value = raw.split("=", 1)
                    placeholders = self.PLACEHOLDER_PATTERN.findall(value)
                    lines.append(ParsedLine(
                        line_number=num,
                        raw_content=raw,
                        is_translatable=True,
                        key=key,
                        value=value,
                        placeholders=placeholders,
                    ))
                else:
                    lines.append(ParsedLine(
                        line_number=num,
                        raw_content=raw,
                        is_translatable=False,
                    ))
        return lines

    def write(self, path: str, lines: List[ParsedLine]) -> None:
        with open(path, "w", encoding="utf-8") as f:
            for line in lines:
                if line.is_translatable and line.key is not None:
                    f.write(f"{line.key}={line.value}\n")
                else:
                    f.write(f"{line.raw_content}\n")
