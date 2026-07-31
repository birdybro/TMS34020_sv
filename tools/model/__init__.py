"""Independent executable TMS34020 architectural model."""

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
    "ModelError",
    "ProcessorState",
    "StepTrace",
    "Tms34020Model",
    "UnclassifiedEncoding",
    "UnsupportedInstruction",
]
