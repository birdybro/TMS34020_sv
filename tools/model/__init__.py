"""Independent executable TMS34020 architectural model."""

from .cache import (
    CacheModelError,
    CacheWordResult,
    InstructionCache,
    MemoryReadRequest,
)
from .model import (
    ModelError,
    StepTrace,
    Tms34020Model,
    UnclassifiedEncoding,
    UnsupportedInstruction,
)
from .state import BitMemory, ProcessorState

__all__ = [
    "BitMemory",
    "CacheModelError",
    "CacheWordResult",
    "InstructionCache",
    "MemoryReadRequest",
    "ModelError",
    "ProcessorState",
    "StepTrace",
    "Tms34020Model",
    "UnclassifiedEncoding",
    "UnsupportedInstruction",
]
