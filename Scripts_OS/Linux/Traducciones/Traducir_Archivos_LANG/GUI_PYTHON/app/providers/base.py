from abc import ABC, abstractmethod
from typing import List

class BaseProvider(ABC):

    @abstractmethod
    def translate_batch(self,
                        texts: List[str],
                        target_lang: str,
                        source_lang: str = "auto") -> List[str]:
        pass

    @property
    @abstractmethod
    def name(self) -> str:
        pass