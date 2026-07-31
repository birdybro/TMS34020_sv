"""Structurally independent, deliberately partial TMS34020 reference model."""

from __future__ import annotations

from dataclasses import dataclass, field
from typing import Any, Callable

from tools.isa.isa_db import IsaDatabase, Instruction
from .state import MASK32, PSIZE_ADDRESS, ProcessorState

N_BIT = 31
C_BIT = 30
Z_BIT = 29
V_BIT = 28


class ModelError(RuntimeError):
    """Base model execution error."""


class UnclassifiedEncoding(ModelError):
    """The incomplete ISA extraction has not classified this first word."""


class UnsupportedInstruction(ModelError):
    """The database knows this instruction but the model slice does not."""


@dataclass
class StepTrace:
    """One deterministic architectural checkpoint."""

    start_pc: int
    next_pc: int
    first_word: int
    mnemonic: str
    instruction_words: list[int]
    machine_states: int | None
    status_before: int
    status_after: int
    register_writes: list[dict[str, int | str]] = field(default_factory=list)
    transactions: list[dict[str, int | str]] = field(default_factory=list)
    notes: list[str] = field(default_factory=list)

    def snapshot(self) -> dict[str, Any]:
        return {
            "start_pc": self.start_pc,
            "next_pc": self.next_pc,
            "first_word": self.first_word,
            "mnemonic": self.mnemonic,
            "instruction_words": list(self.instruction_words),
            "machine_states": self.machine_states,
            "status_before": self.status_before,
            "status_after": self.status_after,
            "register_writes": list(self.register_writes),
            "transactions": list(self.transactions),
            "notes": list(self.notes),
        }


class Tms34020Model:
    """Instruction-boundary model for the primary-verified seed slice."""

    def __init__(
        self,
        state: ProcessorState | None = None,
        isa: IsaDatabase | None = None,
    ) -> None:
        self.state = state or ProcessorState()
        self.isa = isa or IsaDatabase.load()
        self.trace: list[StepTrace] = []
        self._handlers: dict[str, Callable[[Instruction, list[int]], int | None]] = {
            "NOP": self._execute_nop,
            "IDLE": self._execute_idle,
            "MWAIT": self._execute_mwait,
            "ADDXYI": self._execute_addxyi,
            "CMPK": self._execute_cmpk,
            "EXGPS": self._execute_exgps,
            "GETPS": self._execute_getps,
            "RMO": self._execute_rmo,
            "RPIX": self._execute_rpix,
        }
        self._active_trace: StepTrace | None = None
        self._new_hidden_write_states = 0

    @property
    def supported_mnemonics(self) -> tuple[str, ...]:
        return tuple(sorted(self._handlers))

    def load_program(
        self, words: list[int], bit_address: int = 0, set_pc: bool = True
    ) -> None:
        self.state.memory.load_words(bit_address, words)
        if set_pc:
            self.state.pc = bit_address & MASK32

    def snapshot(self) -> dict[str, Any]:
        return {
            "model_schema_version": 1,
            "state": self.state.snapshot(),
            "trace": [event.snapshot() for event in self.trace],
            "supported_mnemonics": list(self.supported_mnemonics),
        }

    @classmethod
    def from_snapshot(cls, snapshot: dict[str, Any]) -> "Tms34020Model":
        if snapshot.get("model_schema_version") != 1:
            raise ValueError("unsupported model snapshot")
        model = cls(ProcessorState.from_snapshot(snapshot["state"]))
        for raw in snapshot["trace"]:
            model.trace.append(StepTrace(**raw))
        if list(model.supported_mnemonics) != snapshot["supported_mnemonics"]:
            raise ValueError("snapshot model coverage differs from executable")
        return model

    def step(self) -> StepTrace:
        if self.state.halted:
            raise ModelError("processor is halted in IDLE")
        state_checkpoint = self.state.snapshot()
        start_pc = self.state.pc
        first_word = self.state.memory.read_bits(start_pc, 16)
        instruction = self.isa.decode(first_word)
        if instruction is None:
            raise UnclassifiedEncoding(
                f"unclassified first word {first_word:04X} at {start_pc:08X}"
            )
        handler = self._handlers.get(instruction.mnemonic)
        if handler is None:
            raise UnsupportedInstruction(
                f"{instruction.mnemonic} is decoded but not modeled"
            )
        words = [
            self.state.memory.read_bits((start_pc + index * 16) & MASK32, 16)
            for index in range(instruction.length_words)
        ]
        before_registers = self._register_snapshot()
        status_before = self.state.st
        pending_write_states_before = self.state.pending_write_states
        default_next_pc = (
            start_pc + instruction.length_words * 16
        ) & MASK32
        self.state.pc = default_next_pc
        event = StepTrace(
            start_pc=start_pc,
            next_pc=default_next_pc,
            first_word=first_word,
            mnemonic=instruction.mnemonic,
            instruction_words=words,
            machine_states=None,
            status_before=status_before,
            status_after=status_before,
        )
        self._active_trace = event
        self._new_hidden_write_states = 0
        try:
            event.machine_states = handler(instruction, words)
        except Exception:
            self.state = ProcessorState.from_snapshot(state_checkpoint)
            raise
        finally:
            self._active_trace = None
        event.next_pc = self.state.pc
        event.status_after = self.state.st
        event.register_writes = self._register_changes(before_registers)
        if event.machine_states is None:
            self.state.timing_complete = False
        else:
            if instruction.mnemonic != "MWAIT":
                self.state.pending_write_states = (
                    max(
                        0,
                        pending_write_states_before - event.machine_states,
                    )
                    + self._new_hidden_write_states
                )
            self.state.machine_states += event.machine_states
        self.trace.append(event)
        return event

    def _register_snapshot(self) -> dict[tuple[str, int], int]:
        snapshot = {
            (register_file, index): self.state.read_reg(register_file, index)
            for register_file in ("A", "B")
            for index in range(15)
        }
        snapshot[("SP", 15)] = self.state.sp
        return snapshot

    def _register_changes(
        self, before: dict[tuple[str, int], int]
    ) -> list[dict[str, int | str]]:
        changes: list[dict[str, int | str]] = []
        for (register_file, index), old_value in before.items():
            new_value = (
                self.state.sp
                if register_file == "SP"
                else self.state.read_reg(register_file, index)
            )
            if new_value != old_value:
                changes.append(
                    {
                        "file": register_file,
                        "index": index,
                        "old": old_value,
                        "new": new_value,
                    }
                )
        return changes

    def _set_status_bit(self, bit: int, value: bool) -> None:
        if value:
            self.state.st |= 1 << bit
        else:
            self.state.st &= ~(1 << bit)
        self.state.st &= MASK32

    def _decode_destination(self, first_word: int) -> tuple[str, int]:
        register_file = "B" if first_word & 0x10 else "A"
        return register_file, first_word & 0xF

    def _execute_nop(
        self, instruction: Instruction, words: list[int]
    ) -> int:
        del instruction, words
        return 1

    def _execute_idle(
        self, instruction: Instruction, words: list[int]
    ) -> None:
        del instruction, words
        self.state.pc = (self.state.pc - 16) & MASK32
        self.state.halted = True
        assert self._active_trace is not None
        self._active_trace.notes.append(
            "IDLE wait duration/interrupt completion is not yet modeled"
        )
        return None

    def _execute_mwait(
        self, instruction: Instruction, words: list[int]
    ) -> int:
        del instruction, words
        pending = self.state.pending_write_states
        self.state.pending_write_states = 0
        return max(2, pending + 1)

    def _execute_addxyi(
        self, instruction: Instruction, words: list[int]
    ) -> int:
        del instruction
        register_file, index = self._decode_destination(words[0])
        old_value = self.state.read_reg(register_file, index)
        immediate = words[1] | (words[2] << 16)
        result_x = ((old_value & 0xFFFF) + (immediate & 0xFFFF)) & 0xFFFF
        result_y = (
            ((old_value >> 16) + (immediate >> 16)) & 0xFFFF
        )
        result = result_x | (result_y << 16)
        self.state.write_reg(register_file, index, result)
        self._set_status_bit(N_BIT, result_x == 0)
        self._set_status_bit(C_BIT, bool(result_y & 0x8000))
        self._set_status_bit(Z_BIT, result_y == 0)
        self._set_status_bit(V_BIT, bool(result_x & 0x8000))
        immediate_address = (self.state.pc - 32) & MASK32
        return 2 if immediate_address & 0x1F == 0 else 3

    def _execute_cmpk(
        self, instruction: Instruction, words: list[int]
    ) -> int:
        del instruction
        register_file, index = self._decode_destination(words[0])
        value = self.state.read_reg(register_file, index)
        encoded_constant = (words[0] >> 5) & 0x1F
        constant = encoded_constant or 32
        result = (value - constant) & MASK32
        self._set_status_bit(N_BIT, bool(result & 0x8000_0000))
        self._set_status_bit(C_BIT, value < constant)
        self._set_status_bit(Z_BIT, result == 0)
        overflow = bool(
            (value ^ constant) & (value ^ result) & 0x8000_0000
        )
        self._set_status_bit(V_BIT, overflow)
        return 1

    def _execute_exgps(
        self, instruction: Instruction, words: list[int]
    ) -> int:
        del instruction
        register_file, index = self._decode_destination(words[0])
        old_register = self.state.read_reg(register_file, index)
        old_psize = self._read_legal_psize()
        self.state.write_reg(register_file, index, old_psize)
        self.state.write_io(PSIZE_ADDRESS, old_register & 0xFFFF)
        assert self._active_trace is not None
        self._active_trace.transactions.append(
            {
                "class": "internal_io_write",
                "bit_address": PSIZE_ADDRESS,
                "width": 16,
                "value": old_register & 0xFFFF,
            }
        )
        self._new_hidden_write_states = 1
        self._active_trace.notes.append(
            "one hidden PSIZE write state remains after EXGPS"
        )
        return 2

    def _execute_getps(
        self, instruction: Instruction, words: list[int]
    ) -> int:
        del instruction
        register_file, index = self._decode_destination(words[0])
        self.state.write_reg(register_file, index, self._read_legal_psize())
        return 2

    def _execute_rmo(
        self, instruction: Instruction, words: list[int]
    ) -> int:
        del instruction
        register_file, destination = self._decode_destination(words[0])
        source = (words[0] >> 5) & 0xF
        value = self.state.read_reg(register_file, source)
        result = 0 if value == 0 else (value & -value).bit_length() - 1
        self.state.write_reg(register_file, destination, result)
        self._set_status_bit(Z_BIT, value == 0)
        return 1

    def _read_legal_psize(self) -> int:
        pixel_size = self.state.read_io(PSIZE_ADDRESS)
        if pixel_size not in (1, 2, 4, 8, 16, 32):
            raise ModelError(f"illegal/unmodeled PSIZE {pixel_size}")
        return pixel_size

    def _execute_rpix(
        self, instruction: Instruction, words: list[int]
    ) -> int:
        del instruction
        register_file, index = self._decode_destination(words[0])
        pixel_size = self._read_legal_psize()
        cycles = {32: 2, 16: 4, 8: 5, 4: 6, 2: 7, 1: 8}
        old_value = self.state.read_reg(register_file, index)
        mask = MASK32 if pixel_size == 32 else (1 << pixel_size) - 1
        pixel = old_value & mask
        result = 0
        for offset in range(0, 32, pixel_size):
            result |= pixel << offset
        self.state.write_reg(register_file, index, result)
        return cycles[pixel_size]
