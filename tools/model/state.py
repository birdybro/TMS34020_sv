"""Architectural state and bit-addressed memory for the independent model."""

from __future__ import annotations

from dataclasses import dataclass, field
import random
from typing import Any

MASK32 = 0xFFFF_FFFF
CONFIG_ADDRESS = 0xC000_01A0
CONTROL_ADDRESS = 0xC000_00B0
DPYCTL_ADDRESS = 0xC000_0080
CONVSP_ADDRESS = 0xC000_0130
CONVDP_ADDRESS = 0xC000_0140
CONVMP_ADDRESS = 0xC000_0180
HSTCTLH_ADDRESS = 0xC000_0100
PSIZE_ADDRESS = 0xC000_0150
PMASKL_ADDRESS = 0xC000_0160
PMASKH_ADDRESS = 0xC000_0170


class BitMemory:
    """Sparse memory whose public addresses and widths are in bits."""

    def __init__(self) -> None:
        self._bytes: dict[int, int] = {}

    def read_bits(self, bit_address: int, width: int) -> int:
        if not 0 <= bit_address <= MASK32:
            raise ValueError("bit_address must fit in 32 bits")
        if not 1 <= width <= 32:
            raise ValueError("width must be in 1..32")
        value = 0
        for bit_index in range(width):
            address = (bit_address + bit_index) & MASK32
            byte = self._bytes.get(address >> 3, 0)
            value |= ((byte >> (address & 7)) & 1) << bit_index
        return value

    def write_bits(self, bit_address: int, width: int, value: int) -> None:
        if not 0 <= bit_address <= MASK32:
            raise ValueError("bit_address must fit in 32 bits")
        if not 1 <= width <= 32:
            raise ValueError("width must be in 1..32")
        if value < 0 or value >> width:
            raise ValueError("value does not fit requested width")
        for bit_index in range(width):
            address = (bit_address + bit_index) & MASK32
            byte_address = address >> 3
            byte = self._bytes.get(byte_address, 0)
            mask = 1 << (address & 7)
            if value & (1 << bit_index):
                byte |= mask
            else:
                byte &= ~mask
            if byte:
                self._bytes[byte_address] = byte
            else:
                self._bytes.pop(byte_address, None)

    def load_words(self, bit_address: int, words: list[int]) -> None:
        if bit_address & 0xF:
            raise ValueError("instruction load address must be 16-bit aligned")
        for index, word in enumerate(words):
            if not 0 <= word <= 0xFFFF:
                raise ValueError("instruction word must fit in 16 bits")
            self.write_bits((bit_address + 16 * index) & MASK32, 16, word)

    def snapshot(self) -> list[list[int]]:
        return [[address, value] for address, value in sorted(self._bytes.items())]

    @classmethod
    def from_snapshot(cls, snapshot: list[list[int]]) -> "BitMemory":
        memory = cls()
        for address, value in snapshot:
            if address < 0 or not 0 <= value <= 0xFF:
                raise ValueError("invalid memory snapshot")
            memory._bytes[int(address)] = int(value)
        return memory


@dataclass
class ProcessorState:
    """Programmer-visible seed state plus disclosed model bookkeeping."""

    a: list[int] = field(default_factory=lambda: [0] * 15)
    b: list[int] = field(default_factory=lambda: [0] * 15)
    sp: int = 0
    pc: int = 0
    st: int = 0x0000_0010
    io_regs: dict[int, int] = field(default_factory=dict)
    memory: BitMemory = field(default_factory=BitMemory)
    machine_states: int = 0
    timing_complete: bool = True
    pending_write_states: int = 0
    force_next_instruction_bypass: bool = False
    halted: bool = False
    vram_color_latch: int = 0

    def __post_init__(self) -> None:
        if len(self.a) != 15 or len(self.b) != 15:
            raise ValueError("A and B files must each contain registers 0..14")
        self.a = [value & MASK32 for value in self.a]
        self.b = [value & MASK32 for value in self.b]
        self.sp &= MASK32
        self.pc &= MASK32
        self.st &= MASK32
        if self.pc & 0xF:
            raise ValueError("PC must be 16-bit instruction-word aligned")
        self.io_regs = {
            int(address) & MASK32: int(value) & 0xFFFF
            for address, value in self.io_regs.items()
        }

    def read_reg(self, register_file: str, index: int) -> int:
        if register_file not in ("A", "B"):
            raise ValueError("register_file must be A or B")
        if not 0 <= index <= 15:
            raise ValueError("register index must be in 0..15")
        if index == 15:
            return self.sp
        return (self.a if register_file == "A" else self.b)[index]

    def write_reg(self, register_file: str, index: int, value: int) -> None:
        if register_file not in ("A", "B"):
            raise ValueError("register_file must be A or B")
        if not 0 <= index <= 15:
            raise ValueError("register index must be in 0..15")
        value &= MASK32
        if index == 15:
            self.sp = value
        else:
            (self.a if register_file == "A" else self.b)[index] = value

    def read_io(self, bit_address: int) -> int:
        return self.io_regs.get(bit_address & MASK32, 0)

    def write_io(self, bit_address: int, value: int) -> None:
        self.io_regs[bit_address & MASK32] = value & 0xFFFF

    def reset_from_vector(self, vector: int) -> None:
        """Apply only reset behavior already verified from the user's guide."""

        vector &= MASK32
        self.st = 0x0000_0010
        self.pc = vector & 0xFFFF_FFF0
        self.io_regs.clear()
        self.write_io(CONFIG_ADDRESS, vector & 0xF)
        self.machine_states = 0
        self.timing_complete = True
        self.pending_write_states = 0
        self.force_next_instruction_bypass = False
        self.halted = False
        self.vram_color_latch = 0

    @classmethod
    def randomized(cls, seed: int, pc: int = 0) -> "ProcessorState":
        generator = random.Random(seed)
        state = cls(
            a=[generator.getrandbits(32) for _ in range(15)],
            b=[generator.getrandbits(32) for _ in range(15)],
            sp=generator.getrandbits(32),
            pc=pc,
            st=generator.getrandbits(32),
        )
        state.write_io(
            PSIZE_ADDRESS, generator.choice((1, 2, 4, 8, 16, 32))
        )
        return state

    def snapshot(self) -> dict[str, Any]:
        return {
            "a": list(self.a),
            "b": list(self.b),
            "sp": self.sp,
            "pc": self.pc,
            "st": self.st,
            "io_regs": [
                [address, value]
                for address, value in sorted(self.io_regs.items())
            ],
            "memory": self.memory.snapshot(),
            "machine_states": self.machine_states,
            "timing_complete": self.timing_complete,
            "pending_write_states": self.pending_write_states,
            "force_next_instruction_bypass": self.force_next_instruction_bypass,
            "halted": self.halted,
            "vram_color_latch": self.vram_color_latch,
        }

    @classmethod
    def from_snapshot(cls, snapshot: dict[str, Any]) -> "ProcessorState":
        return cls(
            a=list(snapshot["a"]),
            b=list(snapshot["b"]),
            sp=int(snapshot["sp"]),
            pc=int(snapshot["pc"]),
            st=int(snapshot["st"]),
            io_regs={
                int(address): int(value)
                for address, value in snapshot["io_regs"]
            },
            memory=BitMemory.from_snapshot(snapshot["memory"]),
            machine_states=int(snapshot["machine_states"]),
            timing_complete=bool(snapshot["timing_complete"]),
            pending_write_states=int(snapshot["pending_write_states"]),
            force_next_instruction_bypass=bool(
                snapshot.get("force_next_instruction_bypass", False)
            ),
            halted=bool(snapshot["halted"]),
            vram_color_latch=int(snapshot["vram_color_latch"]),
        )
