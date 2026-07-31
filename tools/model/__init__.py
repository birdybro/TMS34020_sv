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
from .state import (
    BitMemory,
    CONFIG_ADDRESS,
    CONTROL_ADDRESS,
    CONVDP_ADDRESS,
    CONVMP_ADDRESS,
    CONVSP_ADDRESS,
    HSTCTLH_ADDRESS,
    PSIZE_ADDRESS,
    ProcessorState,
)

__all__ = [
    "BitMemory",
    "CONFIG_ADDRESS",
    "CacheModelError",
    "CacheWordResult",
    "InstructionCache",
    "CONTROL_ADDRESS",
    "CONVDP_ADDRESS",
    "CONVMP_ADDRESS",
    "CONVSP_ADDRESS",
    "HSTCTLH_ADDRESS",
    "MemoryReadRequest",
    "ModelError",
    "ProcessorState",
    "PSIZE_ADDRESS",
    "StepTrace",
    "Tms34020Model",
    "UnclassifiedEncoding",
    "UnsupportedInstruction",
]
