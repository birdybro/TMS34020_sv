"""Structurally independent, deliberately partial TMS34020 reference model."""

from __future__ import annotations

from dataclasses import dataclass, field
from typing import Any, Callable

from tools.isa.isa_db import IsaDatabase, Instruction
from .cache import InstructionCache
from .state import (
    CONVDP_ADDRESS,
    CONVMP_ADDRESS,
    CONVSP_ADDRESS,
    CONTROL_ADDRESS,
    HSTCTLH_ADDRESS,
    MASK32,
    PSIZE_ADDRESS,
    ProcessorState,
)

N_BIT = 31
C_BIT = 30
Z_BIT = 29
V_BIT = 28
IE_BIT = 21


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
        cache: InstructionCache | None = None,
    ) -> None:
        self.state = state or ProcessorState()
        self.isa = isa or IsaDatabase.load()
        self.cache = cache or InstructionCache()
        self.trace: list[StepTrace] = []
        self._handlers: dict[str, Callable[[Instruction, list[int]], int | None]] = {
            "NOP": self._execute_nop,
            "ABS": self._execute_abs,
            "NEG": self._execute_neg,
            "NEGB": self._execute_negb,
            "NOT": self._execute_not,
            "CLRC": self._execute_clrc,
            "DINT": self._execute_dint,
            "EINT": self._execute_eint,
            "EXGF": self._execute_exgf,
            "EXGPC": self._execute_exgpc,
            "GETPC": self._execute_getpc,
            "GETST": self._execute_getst,
            "PUTST": self._execute_putst,
            "ADDK": self._execute_addk,
            "SUBK": self._execute_subk,
            "MOVK": self._execute_movk,
            "MOVI.W": self._execute_movi_word,
            "MOVI.L": self._execute_movi_long,
            "MOVE": self._execute_move,
            "MOVX": self._execute_movx,
            "MOVY": self._execute_movy,
            "RL.K": self._execute_rl_constant,
            "RL.R": self._execute_rl_register,
            "BTST.K": self._execute_btst_constant,
            "BTST.R": self._execute_btst_register,
            "SETF": self._execute_setf,
            "SEXT": self._execute_sext,
            "ZEXT": self._execute_zext,
            "SLA.K": self._execute_sla_constant,
            "SLA.R": self._execute_sla_register,
            "SLL.K": self._execute_sll_constant,
            "SLL.R": self._execute_sll_register,
            "SRA.K": self._execute_sra_constant,
            "SRA.R": self._execute_sra_register,
            "SRL.K": self._execute_srl_constant,
            "SRL.R": self._execute_srl_register,
            "SETC": self._execute_setc,
            "ADD": self._execute_add,
            "ADDC": self._execute_addc,
            "ADDXY": self._execute_addxy,
            "ADDI.W": self._execute_addi_word,
            "ADDI.L": self._execute_addi_long,
            "SUBI.W": self._execute_subi_word,
            "SUBI.L": self._execute_subi_long,
            "CMPI.W": self._execute_cmpi_word,
            "CMPI.L": self._execute_cmpi_long,
            "SUB": self._execute_sub,
            "SUBB": self._execute_subb,
            "SUBXY": self._execute_subxy,
            "CMP": self._execute_cmp,
            "AND": self._execute_and,
            "ANDN": self._execute_andn,
            "OR": self._execute_or,
            "XOR": self._execute_xor,
            "ANDNI": self._execute_andni,
            "BLMOVE": self._execute_blmove,
            "ORI": self._execute_ori,
            "XORI": self._execute_xori,
            "IDLE": self._execute_idle,
            "MWAIT": self._execute_mwait,
            "ADDXYI": self._execute_addxyi,
            "CMPK": self._execute_cmpk,
            "EXGPS": self._execute_exgps,
            "GETPS": self._execute_getps,
            "LMO": self._execute_lmo,
            "RMO": self._execute_rmo,
            "RPIX": self._execute_rpix,
            "SETCDP": self._execute_setcdp,
            "SETCMP": self._execute_setcmp,
            "SETCSP": self._execute_setcsp,
            "TRAPL": self._execute_trapl,
            "VLCOL": self._execute_vlcol,
        }
        self._active_trace: StepTrace | None = None
        self._new_hidden_write_states = 0

    @property
    def supported_mnemonics(self) -> tuple[str, ...]:
        return tuple(sorted(self._handlers))

    def load_program(
        self,
        words: list[int],
        bit_address: int = 0,
        set_pc: bool = True,
        flush_cache: bool = True,
    ) -> None:
        self.state.memory.load_words(bit_address, words)
        if flush_cache:
            self.cache.flush()
        if set_pc:
            self.state.pc = bit_address & MASK32

    def reset_from_vector(self, vector: int) -> None:
        self.state.reset_from_vector(vector)
        self.cache.reset()

    def snapshot(self) -> dict[str, Any]:
        return {
            "model_schema_version": 2,
            "state": self.state.snapshot(),
            "cache": self.cache.snapshot(),
            "trace": [event.snapshot() for event in self.trace],
            "supported_mnemonics": list(self.supported_mnemonics),
        }

    @classmethod
    def from_snapshot(cls, snapshot: dict[str, Any]) -> "Tms34020Model":
        version = snapshot.get("model_schema_version")
        if version not in (1, 2):
            raise ValueError("unsupported model snapshot")
        cache = (
            InstructionCache()
            if version == 1
            else InstructionCache.from_snapshot(snapshot["cache"])
        )
        model = cls(
            ProcessorState.from_snapshot(snapshot["state"]),
            cache=cache,
        )
        for raw in snapshot["trace"]:
            model.trace.append(StepTrace(**raw))
        if list(model.supported_mnemonics) != snapshot["supported_mnemonics"]:
            raise ValueError("snapshot model coverage differs from executable")
        return model

    def step(self) -> StepTrace:
        if self.state.halted:
            raise ModelError("processor is halted in IDLE")
        state_checkpoint = self.state.snapshot()
        cache_checkpoint = self.cache.snapshot()
        start_pc = self.state.pc
        try:
            fetch_transactions: list[dict[str, int | str]] = []
            first_word, first_fetch_complete = self._fetch_instruction_word(
                start_pc, fetch_transactions
            )
            instruction = self.isa.decode(first_word)
            if instruction is None:
                raise UnclassifiedEncoding(
                    f"unclassified first word {first_word:04X} "
                    f"at {start_pc:08X}"
                )
            handler = self._handlers.get(instruction.mnemonic)
            if handler is None:
                raise UnsupportedInstruction(
                    f"{instruction.mnemonic} is decoded but not modeled"
                )
            words = [first_word]
            fetch_timing_complete = first_fetch_complete
            for index in range(1, instruction.length_words):
                word, timing_complete = self._fetch_instruction_word(
                    (start_pc + index * 16) & MASK32,
                    fetch_transactions,
                )
                words.append(word)
                fetch_timing_complete &= timing_complete

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
                transactions=fetch_transactions,
            )
            if not fetch_timing_complete:
                event.notes.append(
                    "machine_states excludes cache miss or bypass-fetch timing"
                )
                self.state.timing_complete = False
            self._active_trace = event
            self._new_hidden_write_states = 0
            event.machine_states = handler(instruction, words)
        except Exception:
            self.state = ProcessorState.from_snapshot(state_checkpoint)
            self.cache = InstructionCache.from_snapshot(cache_checkpoint)
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

    def _fetch_instruction_word(
        self,
        bit_address: int,
        transactions: list[dict[str, int | str]],
    ) -> tuple[int, bool]:
        cache_disable = bool(
            self.state.read_io(CONTROL_ADDRESS) & (1 << 15)
        )
        cache_flush = bool(
            self.state.read_io(HSTCTLH_ADDRESS) & (1 << 14)
        )
        result = self.cache.request_word(
            bit_address,
            cache_disable=cache_disable,
            cache_flush=cache_flush,
        )
        transactions.append(
            {
                "class": "instruction_cache_lookup",
                "bit_address": bit_address,
                "width": 16,
                "result": result.classification,
                "segment": -1 if result.segment is None else result.segment,
                "subsegment": result.subsegment,
            }
        )
        timing_complete = result.classification == "hit"
        while not result.complete:
            request = result.request
            assert request is not None
            data = self.state.memory.read_bits(
                request.bit_address, request.width_bits
            )
            transactions.append(
                {
                    "class": request.kind,
                    "bit_address": request.bit_address,
                    "width": request.width_bits,
                    "sequence_index": request.sequence_index,
                    "sequence_length": request.sequence_length,
                    "value": data,
                }
            )
            result = self.cache.accept_read(data)
        assert result.word is not None
        return result.word, timing_complete

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

    def _decode_source_destination(
        self, first_word: int
    ) -> tuple[str, int, int]:
        register_file = "B" if first_word & 0x10 else "A"
        return register_file, (first_word >> 5) & 0xF, first_word & 0xF

    def _execute_nop(
        self, instruction: Instruction, words: list[int]
    ) -> int:
        del instruction, words
        return 1

    def _execute_abs(
        self, instruction: Instruction, words: list[int]
    ) -> int:
        del instruction
        register_file, index = self._decode_destination(words[0])
        value = self.state.read_reg(register_file, index)
        negated = (-value) & MASK32
        result = negated if value & 0x8000_0000 else value
        self.state.write_reg(register_file, index, result)
        self._set_status_bit(N_BIT, bool(negated & 0x8000_0000))
        self._set_status_bit(Z_BIT, value == 0)
        self._set_status_bit(V_BIT, value == 0x8000_0000)
        return 1

    def _execute_neg(
        self, instruction: Instruction, words: list[int]
    ) -> int:
        del instruction
        register_file, index = self._decode_destination(words[0])
        value = self.state.read_reg(register_file, index)
        result = (-value) & MASK32
        self.state.write_reg(register_file, index, result)
        self._set_status_bit(N_BIT, bool(result & 0x8000_0000))
        self._set_status_bit(C_BIT, value != 0)
        self._set_status_bit(Z_BIT, result == 0)
        self._set_status_bit(V_BIT, value == 0x8000_0000)
        return 1

    def _execute_negb(
        self, instruction: Instruction, words: list[int]
    ) -> int:
        del instruction
        register_file, index = self._decode_destination(words[0])
        value = self.state.read_reg(register_file, index)
        borrow_in = (self.state.st >> C_BIT) & 1
        result = (-value - borrow_in) & MASK32
        self.state.write_reg(register_file, index, result)
        self._set_status_bit(N_BIT, bool(result & 0x8000_0000))
        self._set_status_bit(C_BIT, value != 0 or borrow_in != 0)
        self._set_status_bit(Z_BIT, result == 0)
        self._set_status_bit(
            V_BIT,
            bool(value & result & 0x8000_0000),
        )
        return 1

    def _execute_not(
        self, instruction: Instruction, words: list[int]
    ) -> int:
        del instruction
        register_file, index = self._decode_destination(words[0])
        result = (~self.state.read_reg(register_file, index)) & MASK32
        self.state.write_reg(register_file, index, result)
        self._set_status_bit(Z_BIT, result == 0)
        return 1

    def _execute_clrc(
        self, instruction: Instruction, words: list[int]
    ) -> int:
        del instruction, words
        self._set_status_bit(C_BIT, False)
        return 1

    def _execute_dint(
        self, instruction: Instruction, words: list[int]
    ) -> int:
        del instruction, words
        self._set_status_bit(IE_BIT, False)
        return 3

    def _execute_eint(
        self, instruction: Instruction, words: list[int]
    ) -> int:
        del instruction, words
        self._set_status_bit(IE_BIT, True)
        return 3

    def _execute_exgpc(
        self, instruction: Instruction, words: list[int]
    ) -> int:
        del instruction
        register_file, index = self._decode_destination(words[0])
        old_register = self.state.read_reg(register_file, index)
        sequential_pc = self.state.pc
        self.state.write_reg(register_file, index, sequential_pc)
        self.state.pc = old_register & 0xFFFF_FFF0
        return 2

    def _execute_getpc(
        self, instruction: Instruction, words: list[int]
    ) -> int:
        del instruction
        register_file, index = self._decode_destination(words[0])
        self.state.write_reg(register_file, index, self.state.pc)
        return 1

    def _execute_getst(
        self, instruction: Instruction, words: list[int]
    ) -> int:
        del instruction
        register_file, index = self._decode_destination(words[0])
        self.state.write_reg(register_file, index, self.state.st)
        return 1

    def _execute_putst(
        self, instruction: Instruction, words: list[int]
    ) -> int:
        del instruction
        register_file, index = self._decode_destination(words[0])
        self.state.st = self.state.read_reg(register_file, index)
        return 3

    def _execute_addk(
        self, instruction: Instruction, words: list[int]
    ) -> int:
        del instruction
        register_file, index = self._decode_destination(words[0])
        destination = self.state.read_reg(register_file, index)
        encoded_constant = (words[0] >> 5) & 0x1F
        constant = encoded_constant or 32
        total = destination + constant
        result = total & MASK32
        carry_out = (total >> 32) & 1
        low_total = (destination & 0x7FFF_FFFF) + constant
        carry_into_sign = (low_total >> 31) & 1
        overflow = carry_into_sign ^ carry_out
        self.state.write_reg(register_file, index, result)
        self._set_status_bit(N_BIT, bool(result & 0x8000_0000))
        self._set_status_bit(C_BIT, bool(carry_out))
        self._set_status_bit(Z_BIT, result == 0)
        self._set_status_bit(V_BIT, bool(overflow))
        return 1

    def _execute_subk(
        self, instruction: Instruction, words: list[int]
    ) -> int:
        del instruction
        register_file, index = self._decode_destination(words[0])
        destination = self.state.read_reg(register_file, index)
        encoded_constant = (words[0] >> 5) & 0x1F
        constant = encoded_constant or 32
        result = (destination - constant) & MASK32
        borrow = destination < constant
        overflow = bool(
            (destination ^ constant)
            & (destination ^ result)
            & 0x8000_0000
        )
        self.state.write_reg(register_file, index, result)
        self._set_status_bit(N_BIT, bool(result & 0x8000_0000))
        self._set_status_bit(C_BIT, borrow)
        self._set_status_bit(Z_BIT, result == 0)
        self._set_status_bit(V_BIT, overflow)
        return 1

    def _execute_movk(
        self, instruction: Instruction, words: list[int]
    ) -> int:
        del instruction
        register_file, index = self._decode_destination(words[0])
        encoded_constant = (words[0] >> 5) & 0x1F
        constant = encoded_constant or 32
        self.state.write_reg(register_file, index, constant)
        return 1

    def _execute_immediate_move(
        self,
        words: list[int],
        long_form: bool,
    ) -> int:
        register_file, index = self._decode_destination(words[0])
        if long_form:
            result = words[1] | (words[2] << 16)
        else:
            result = words[1]
            if result & 0x8000:
                result |= 0xFFFF_0000

        self.state.write_reg(register_file, index, result)
        self._set_status_bit(N_BIT, bool(result & 0x8000_0000))
        self._set_status_bit(Z_BIT, result == 0)
        self._set_status_bit(V_BIT, False)

        if not long_form:
            return 2
        immediate_address = (self.state.pc - 32) & MASK32
        return 2 if immediate_address & 0x1F == 0 else 3

    def _execute_movi_word(
        self, instruction: Instruction, words: list[int]
    ) -> int:
        del instruction
        return self._execute_immediate_move(words, False)

    def _execute_movi_long(
        self, instruction: Instruction, words: list[int]
    ) -> int:
        del instruction
        return self._execute_immediate_move(words, True)

    def _execute_register_half_move(
        self,
        words: list[int],
        high_half: bool,
    ) -> int:
        register_file, source_index, destination_index = (
            self._decode_source_destination(words[0])
        )
        source = self.state.read_reg(register_file, source_index)
        destination = self.state.read_reg(register_file, destination_index)
        if high_half:
            result = (source & 0xFFFF_0000) | (destination & 0x0000_FFFF)
        else:
            result = (destination & 0xFFFF_0000) | (source & 0x0000_FFFF)
        self.state.write_reg(register_file, destination_index, result)
        return 1

    def _execute_movx(
        self, instruction: Instruction, words: list[int]
    ) -> int:
        del instruction
        return self._execute_register_half_move(words, False)

    def _execute_movy(
        self, instruction: Instruction, words: list[int]
    ) -> int:
        del instruction
        return self._execute_register_half_move(words, True)

    def _execute_move(
        self, instruction: Instruction, words: list[int]
    ) -> int:
        del instruction
        first_word = words[0]
        source_file = "B" if first_word & 0x10 else "A"
        cross_file = bool(first_word & 0x0200)
        destination_file = (
            ("A" if source_file == "B" else "B")
            if cross_file
            else source_file
        )
        source_index = (first_word >> 5) & 0xF
        destination_index = first_word & 0xF
        result = self.state.read_reg(source_file, source_index)
        self.state.write_reg(destination_file, destination_index, result)
        self._set_status_bit(N_BIT, bool(result & 0x8000_0000))
        self._set_status_bit(Z_BIT, result == 0)
        self._set_status_bit(V_BIT, False)
        return 1

    def _execute_rotate_left(
        self,
        register_file: str,
        destination_index: int,
        count: int,
    ) -> int:
        count &= 0x1F
        destination = self.state.read_reg(register_file, destination_index)
        if count == 0:
            result = destination
            carry = False
        else:
            result = (
                (destination << count) | (destination >> (32 - count))
            ) & MASK32
            carry = bool(result & 1)
        self.state.write_reg(register_file, destination_index, result)
        self._set_status_bit(C_BIT, carry)
        self._set_status_bit(Z_BIT, result == 0)
        return 1

    def _execute_rl_constant(
        self, instruction: Instruction, words: list[int]
    ) -> int:
        del instruction
        register_file, destination_index = self._decode_destination(words[0])
        count = (words[0] >> 5) & 0x1F
        return self._execute_rotate_left(
            register_file, destination_index, count
        )

    def _execute_rl_register(
        self, instruction: Instruction, words: list[int]
    ) -> int:
        del instruction
        register_file, source_index, destination_index = (
            self._decode_source_destination(words[0])
        )
        count = self.state.read_reg(register_file, source_index) & 0x1F
        return self._execute_rotate_left(
            register_file, destination_index, count
        )

    def _execute_btst_constant(
        self, instruction: Instruction, words: list[int]
    ) -> int:
        del instruction
        register_file, destination = self._decode_destination(words[0])
        encoded_bit = (words[0] >> 5) & 0x1F
        bit_index = (~encoded_bit) & 0x1F
        value = self.state.read_reg(register_file, destination)
        self._set_status_bit(Z_BIT, not bool(value & (1 << bit_index)))
        return 1

    def _execute_btst_register(
        self, instruction: Instruction, words: list[int]
    ) -> int:
        del instruction
        register_file, source, destination = (
            self._decode_source_destination(words[0])
        )
        bit_index = self.state.read_reg(register_file, source) & 0x1F
        value = self.state.read_reg(register_file, destination)
        self._set_status_bit(Z_BIT, not bool(value & (1 << bit_index)))
        return 1

    def _selected_field_size(self, first_word: int) -> int:
        field_bank = (first_word >> 9) & 1
        encoded_size = (self.state.st >> (field_bank * 6)) & 0x1F
        return encoded_size or 32

    def _execute_exgf(
        self, instruction: Instruction, words: list[int]
    ) -> int:
        del instruction
        first_word = words[0]
        register_file, destination = self._decode_destination(first_word)
        field_bank = (first_word >> 9) & 1
        shift = field_bank * 6
        mask = 0x3F << shift
        register_before = self.state.read_reg(register_file, destination)
        field_before = (self.state.st >> shift) & 0x3F
        self.state.st = (
            (self.state.st & ~mask)
            | ((register_before & 0x3F) << shift)
        ) & MASK32
        self.state.write_reg(register_file, destination, field_before)
        return field_bank + 1

    def _execute_setf(
        self, instruction: Instruction, words: list[int]
    ) -> int:
        del instruction
        first_word = words[0]
        field_bank = (first_word >> 9) & 1
        field_parameters = first_word & 0x3F
        shift = field_bank * 6
        mask = 0x3F << shift
        self.state.st = (
            (self.state.st & ~mask) | (field_parameters << shift)
        ) & MASK32
        return 1

    def _execute_field_extension(
        self,
        words: list[int],
        *,
        sign_extend: bool,
    ) -> int:
        first_word = words[0]
        register_file, destination = self._decode_destination(first_word)
        value = self.state.read_reg(register_file, destination)
        width = self._selected_field_size(first_word)
        mask = MASK32 if width == 32 else (1 << width) - 1
        result = value & mask
        if (
            sign_extend
            and width < 32
            and result & (1 << (width - 1))
        ):
            result |= MASK32 ^ mask
        self.state.write_reg(register_file, destination, result)
        if sign_extend:
            self._set_status_bit(N_BIT, bool(result & 0x8000_0000))
        self._set_status_bit(Z_BIT, result == 0)
        return 2 if sign_extend else 1

    def _execute_sext(
        self, instruction: Instruction, words: list[int]
    ) -> int:
        del instruction
        return self._execute_field_extension(words, sign_extend=True)

    def _execute_zext(
        self, instruction: Instruction, words: list[int]
    ) -> int:
        del instruction
        return self._execute_field_extension(words, sign_extend=False)

    def _execute_shift(
        self,
        register_file: str,
        destination_index: int,
        count: int,
        *,
        left: bool,
        arithmetic: bool,
    ) -> int:
        count &= 0x1F
        destination = self.state.read_reg(register_file, destination_index)

        if count == 0:
            result = destination
            carry = False
        elif left:
            result = (destination << count) & MASK32
            carry = bool((destination >> (32 - count)) & 1)
        elif arithmetic and destination & 0x8000_0000:
            signed_destination = destination - (1 << 32)
            result = (signed_destination >> count) & MASK32
            carry = bool((destination >> (count - 1)) & 1)
        else:
            result = destination >> count
            carry = bool((destination >> (count - 1)) & 1)

        self.state.write_reg(register_file, destination_index, result)
        self._set_status_bit(C_BIT, carry)
        self._set_status_bit(Z_BIT, result == 0)

        if arithmetic:
            self._set_status_bit(N_BIT, bool(result & 0x8000_0000))
        if arithmetic and left:
            if count == 0:
                overflow = False
            else:
                sign_window_width = count + 1
                sign_window = destination >> (32 - sign_window_width)
                sign_window_mask = (1 << sign_window_width) - 1
                if destination & 0x8000_0000:
                    overflow = sign_window != sign_window_mask
                else:
                    overflow = sign_window != 0
            self._set_status_bit(V_BIT, overflow)

        return 3 if arithmetic and left else 1

    def _execute_shift_constant(
        self,
        words: list[int],
        *,
        left: bool,
        arithmetic: bool,
    ) -> int:
        register_file, destination_index = self._decode_destination(words[0])
        encoded_count = (words[0] >> 5) & 0x1F
        count = encoded_count if left else (-encoded_count) & 0x1F
        return self._execute_shift(
            register_file,
            destination_index,
            count,
            left=left,
            arithmetic=arithmetic,
        )

    def _execute_shift_register(
        self,
        words: list[int],
        *,
        left: bool,
        arithmetic: bool,
    ) -> int:
        register_file, source_index, destination_index = (
            self._decode_source_destination(words[0])
        )
        encoded_count = self.state.read_reg(register_file, source_index) & 0x1F
        count = encoded_count if left else (-encoded_count) & 0x1F
        return self._execute_shift(
            register_file,
            destination_index,
            count,
            left=left,
            arithmetic=arithmetic,
        )

    def _execute_sla_constant(
        self, instruction: Instruction, words: list[int]
    ) -> int:
        del instruction
        return self._execute_shift_constant(
            words, left=True, arithmetic=True
        )

    def _execute_sla_register(
        self, instruction: Instruction, words: list[int]
    ) -> int:
        del instruction
        return self._execute_shift_register(
            words, left=True, arithmetic=True
        )

    def _execute_sll_constant(
        self, instruction: Instruction, words: list[int]
    ) -> int:
        del instruction
        return self._execute_shift_constant(
            words, left=True, arithmetic=False
        )

    def _execute_sll_register(
        self, instruction: Instruction, words: list[int]
    ) -> int:
        del instruction
        return self._execute_shift_register(
            words, left=True, arithmetic=False
        )

    def _execute_sra_constant(
        self, instruction: Instruction, words: list[int]
    ) -> int:
        del instruction
        return self._execute_shift_constant(
            words, left=False, arithmetic=True
        )

    def _execute_sra_register(
        self, instruction: Instruction, words: list[int]
    ) -> int:
        del instruction
        return self._execute_shift_register(
            words, left=False, arithmetic=True
        )

    def _execute_srl_constant(
        self, instruction: Instruction, words: list[int]
    ) -> int:
        del instruction
        return self._execute_shift_constant(
            words, left=False, arithmetic=False
        )

    def _execute_srl_register(
        self, instruction: Instruction, words: list[int]
    ) -> int:
        del instruction
        return self._execute_shift_register(
            words, left=False, arithmetic=False
        )

    def _execute_setc(
        self, instruction: Instruction, words: list[int]
    ) -> int:
        del instruction, words
        self._set_status_bit(C_BIT, True)
        return 1

    def _execute_binary_arithmetic(
        self,
        words: list[int],
        operation: str,
    ) -> int:
        register_file, source_index, destination_index = (
            self._decode_source_destination(words[0])
        )
        source = self.state.read_reg(register_file, source_index)
        destination = self.state.read_reg(register_file, destination_index)
        carry_or_borrow = (self.state.st >> C_BIT) & 1

        if operation in ("ADD", "ADDC"):
            carry_in = carry_or_borrow if operation == "ADDC" else 0
            total = destination + source + carry_in
            result = total & MASK32
            carry_out = (total >> 32) & 1
            status_c = carry_out
            low_total = (
                (destination & 0x7FFF_FFFF)
                + (source & 0x7FFF_FFFF)
                + carry_in
            )
            carry_into_sign = (low_total >> 31) & 1
            overflow = carry_into_sign ^ carry_out
        else:
            borrow_in = carry_or_borrow if operation == "SUBB" else 0
            result = (destination - source - borrow_in) & MASK32
            borrow_out = destination < source + borrow_in
            complement_add = (
                destination
                + ((~source) & MASK32)
                + (1 - borrow_in)
            )
            complement_carry_out = (complement_add >> 32) & 1
            low_complement_add = (
                (destination & 0x7FFF_FFFF)
                + ((~source) & 0x7FFF_FFFF)
                + (1 - borrow_in)
            )
            carry_into_sign = (low_complement_add >> 31) & 1
            overflow = carry_into_sign ^ complement_carry_out
            status_c = int(borrow_out)

        if operation != "CMP":
            self.state.write_reg(register_file, destination_index, result)
        self._set_status_bit(N_BIT, bool(result & 0x8000_0000))
        self._set_status_bit(C_BIT, bool(status_c))
        self._set_status_bit(Z_BIT, result == 0)
        self._set_status_bit(V_BIT, bool(overflow))
        return 1

    def _execute_add(
        self, instruction: Instruction, words: list[int]
    ) -> int:
        del instruction
        return self._execute_binary_arithmetic(words, "ADD")

    def _execute_addc(
        self, instruction: Instruction, words: list[int]
    ) -> int:
        del instruction
        return self._execute_binary_arithmetic(words, "ADDC")

    def _execute_xy_arithmetic(
        self, words: list[int], subtract: bool
    ) -> int:
        register_file, source_index, destination_index = (
            self._decode_source_destination(words[0])
        )
        source = self.state.read_reg(register_file, source_index)
        destination = self.state.read_reg(register_file, destination_index)
        source_x = source & 0xFFFF
        source_y = (source >> 16) & 0xFFFF
        destination_x = destination & 0xFFFF
        destination_y = (destination >> 16) & 0xFFFF

        if subtract:
            result_x = (destination_x - source_x) & 0xFFFF
            result_y = (destination_y - source_y) & 0xFFFF
            status_n = source_x == destination_x
            status_c = source_y > destination_y
            status_z = source_y == destination_y
            status_v = source_x > destination_x
        else:
            result_x = (destination_x + source_x) & 0xFFFF
            result_y = (destination_y + source_y) & 0xFFFF
            status_n = result_x == 0
            status_c = bool(result_y & 0x8000)
            status_z = result_y == 0
            status_v = bool(result_x & 0x8000)

        self.state.write_reg(
            register_file,
            destination_index,
            result_x | (result_y << 16),
        )
        self._set_status_bit(N_BIT, status_n)
        self._set_status_bit(C_BIT, status_c)
        self._set_status_bit(Z_BIT, status_z)
        self._set_status_bit(V_BIT, status_v)
        return 1

    def _execute_addxy(
        self, instruction: Instruction, words: list[int]
    ) -> int:
        del instruction
        return self._execute_xy_arithmetic(words, False)

    def _execute_immediate_add(
        self, words: list[int], long_form: bool
    ) -> int:
        register_file, index = self._decode_destination(words[0])
        destination = self.state.read_reg(register_file, index)
        if long_form:
            source = words[1] | (words[2] << 16)
        else:
            source = words[1]
            if source & 0x8000:
                source |= 0xFFFF_0000

        total = destination + source
        result = total & MASK32
        carry_out = (total >> 32) & 1
        low_total = (
            (destination & 0x7FFF_FFFF)
            + (source & 0x7FFF_FFFF)
        )
        carry_into_sign = (low_total >> 31) & 1
        overflow = carry_into_sign ^ carry_out

        self.state.write_reg(register_file, index, result)
        self._set_status_bit(N_BIT, bool(result & 0x8000_0000))
        self._set_status_bit(C_BIT, bool(carry_out))
        self._set_status_bit(Z_BIT, result == 0)
        self._set_status_bit(V_BIT, bool(overflow))

        if not long_form:
            return 2
        immediate_address = (self.state.pc - 32) & MASK32
        return 2 if immediate_address & 0x1F == 0 else 3

    def _execute_addi_word(
        self, instruction: Instruction, words: list[int]
    ) -> int:
        del instruction
        return self._execute_immediate_add(words, False)

    def _execute_addi_long(
        self, instruction: Instruction, words: list[int]
    ) -> int:
        del instruction
        return self._execute_immediate_add(words, True)

    def _execute_immediate_subtract(
        self,
        words: list[int],
        long_form: bool,
        write_result: bool = True,
    ) -> int:
        register_file, index = self._decode_destination(words[0])
        destination = self.state.read_reg(register_file, index)
        if long_form:
            encoded_immediate = words[1] | (words[2] << 16)
            source = (~encoded_immediate) & MASK32
        else:
            source = (~words[1]) & 0xFFFF
            if source & 0x8000:
                source |= 0xFFFF_0000

        result = (destination - source) & MASK32
        borrow = destination < source
        overflow = bool(
            (destination ^ source)
            & (destination ^ result)
            & 0x8000_0000
        )

        if write_result:
            self.state.write_reg(register_file, index, result)
        self._set_status_bit(N_BIT, bool(result & 0x8000_0000))
        self._set_status_bit(C_BIT, borrow)
        self._set_status_bit(Z_BIT, result == 0)
        self._set_status_bit(V_BIT, overflow)

        if not long_form:
            return 2
        immediate_address = (self.state.pc - 32) & MASK32
        return 2 if immediate_address & 0x1F == 0 else 3

    def _execute_subi_word(
        self, instruction: Instruction, words: list[int]
    ) -> int:
        del instruction
        return self._execute_immediate_subtract(words, False)

    def _execute_subi_long(
        self, instruction: Instruction, words: list[int]
    ) -> int:
        del instruction
        return self._execute_immediate_subtract(words, True)

    def _execute_cmpi_word(
        self, instruction: Instruction, words: list[int]
    ) -> int:
        del instruction
        return self._execute_immediate_subtract(
            words, False, write_result=False
        )

    def _execute_cmpi_long(
        self, instruction: Instruction, words: list[int]
    ) -> int:
        del instruction
        return self._execute_immediate_subtract(
            words, True, write_result=False
        )

    def _execute_sub(
        self, instruction: Instruction, words: list[int]
    ) -> int:
        del instruction
        return self._execute_binary_arithmetic(words, "SUB")

    def _execute_subb(
        self, instruction: Instruction, words: list[int]
    ) -> int:
        del instruction
        return self._execute_binary_arithmetic(words, "SUBB")

    def _execute_subxy(
        self, instruction: Instruction, words: list[int]
    ) -> int:
        del instruction
        return self._execute_xy_arithmetic(words, True)

    def _execute_cmp(
        self, instruction: Instruction, words: list[int]
    ) -> int:
        del instruction
        return self._execute_binary_arithmetic(words, "CMP")

    def _execute_logical(
        self,
        words: list[int],
        operation: str,
    ) -> int:
        register_file, source_index, destination_index = (
            self._decode_source_destination(words[0])
        )
        source = self.state.read_reg(register_file, source_index)
        destination = self.state.read_reg(register_file, destination_index)
        if operation == "AND":
            result = source & destination
        elif operation == "ANDN":
            result = (~source & MASK32) & destination
        elif operation == "OR":
            result = source | destination
        elif operation == "XOR":
            result = source ^ destination
        else:
            raise AssertionError(f"unknown logical operation {operation}")
        self.state.write_reg(register_file, destination_index, result)
        self._set_status_bit(Z_BIT, result == 0)
        return 1

    def _execute_and(
        self, instruction: Instruction, words: list[int]
    ) -> int:
        del instruction
        return self._execute_logical(words, "AND")

    def _execute_andn(
        self, instruction: Instruction, words: list[int]
    ) -> int:
        del instruction
        return self._execute_logical(words, "ANDN")

    def _execute_or(
        self, instruction: Instruction, words: list[int]
    ) -> int:
        del instruction
        return self._execute_logical(words, "OR")

    def _execute_xor(
        self, instruction: Instruction, words: list[int]
    ) -> int:
        del instruction
        return self._execute_logical(words, "XOR")

    def _execute_immediate_logical(
        self,
        words: list[int],
        operation: str,
    ) -> int:
        register_file, index = self._decode_destination(words[0])
        destination = self.state.read_reg(register_file, index)
        immediate = words[1] | (words[2] << 16)
        if operation == "ANDNI":
            result = (~immediate & MASK32) & destination
        elif operation == "ORI":
            result = immediate | destination
        elif operation == "XORI":
            result = immediate ^ destination
        else:
            raise AssertionError(
                f"unknown immediate logical operation {operation}"
            )
        self.state.write_reg(register_file, index, result)
        self._set_status_bit(Z_BIT, result == 0)
        immediate_address = (self.state.pc - 32) & MASK32
        return 2 if immediate_address & 0x1F == 0 else 3

    def _execute_andni(
        self, instruction: Instruction, words: list[int]
    ) -> int:
        del instruction
        return self._execute_immediate_logical(words, "ANDNI")

    def _execute_blmove(
        self, instruction: Instruction, words: list[int]
    ) -> None:
        del instruction
        source_unaligned = (words[0] >> 1) & 1
        destination_unaligned = words[0] & 1
        source_address = self.state.read_reg("B", 0)
        destination_address = self.state.read_reg("B", 2)
        bit_count = self.state.read_reg("B", 7)

        if source_unaligned == 0 and source_address & 0x1F:
            raise ModelError(
                "BLMOVE S=0 requires 32-bit-aligned B0/SADDR"
            )
        if destination_unaligned == 0 and destination_address & 0x1F:
            raise ModelError(
                "BLMOVE D=0 requires 32-bit-aligned B2/DADDR"
            )
        ranges_overlap = (
            bit_count != 0
            and source_address != destination_address
            and (
                (
                    (destination_address - source_address) & MASK32
                ) < bit_count
                or (
                    (source_address - destination_address) & MASK32
                ) < bit_count
            )
        )
        if ranges_overlap:
            raise ModelError(
                "overlapping BLMOVE ranges are outside the verified model"
            )

        offset = 0
        while offset < bit_count:
            width = min(32, bit_count - offset)
            value = self.state.memory.read_bits(
                (source_address + offset) & MASK32,
                width,
            )
            self.state.memory.write_bits(
                (destination_address + offset) & MASK32,
                width,
                value,
            )
            offset += width

        self.state.write_reg(
            "B", 0, (source_address + bit_count) & MASK32
        )
        self.state.write_reg(
            "B", 2, (destination_address + bit_count) & MASK32
        )
        self.state.write_reg("B", 7, 0)
        assert self._active_trace is not None
        self._active_trace.transactions.append(
            {
                "class": "abstract_block_move",
                "source_bit_address": source_address,
                "destination_bit_address": destination_address,
                "width": bit_count,
                "source_unaligned_mode": source_unaligned,
                "destination_unaligned_mode": destination_unaligned,
            }
        )
        self._active_trace.notes.append(
            "successful non-overlapping BLMOVE boundary; physical "
            "transactions, timing, interrupt, fault, and retry pending"
        )
        return None

    def _execute_ori(
        self, instruction: Instruction, words: list[int]
    ) -> int:
        del instruction
        return self._execute_immediate_logical(words, "ORI")

    def _execute_xori(
        self, instruction: Instruction, words: list[int]
    ) -> int:
        del instruction
        return self._execute_immediate_logical(words, "XORI")

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

    def _execute_lmo(
        self, instruction: Instruction, words: list[int]
    ) -> int:
        del instruction
        register_file, source, destination = (
            self._decode_source_destination(words[0])
        )
        value = self.state.read_reg(register_file, source)
        result = 0 if value == 0 else 32 - value.bit_length()
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

    @staticmethod
    def _pitch_conversion(pitch: int) -> tuple[int, int]:
        set_bits = tuple(
            bit_index
            for bit_index in range(32)
            if pitch & (1 << bit_index)
        )
        if len(set_bits) == 1:
            conversion_value_1 = (~set_bits[0]) & 0x1F
            if conversion_value_1 != 0:
                return conversion_value_1, 4
        elif len(set_bits) == 2:
            lesser_power, greater_power = set_bits
            conversion_value_1 = (~greater_power) & 0x1F
            conversion_value_2 = (~lesser_power) & 0x1F
            if conversion_value_1 != 0 and conversion_value_2 != 0:
                return (
                    conversion_value_1 |
                    (conversion_value_2 << 8),
                    6,
                )
        return 0, 3

    def _execute_set_pitch_conversion(
        self,
        source_index: int,
        destination_address: int,
    ) -> int:
        pitch = self.state.read_reg("B", source_index)
        conversion, machine_states = self._pitch_conversion(pitch)
        self.state.write_io(destination_address, conversion)
        assert self._active_trace is not None
        self._active_trace.transactions.append(
            {
                "class": "internal_io_write",
                "bit_address": destination_address,
                "width": 16,
                "value": conversion,
            }
        )
        self._new_hidden_write_states = 1
        self._active_trace.notes.append(
            "one hidden conversion-register write state remains"
        )
        return machine_states

    def _execute_setcdp(
        self, instruction: Instruction, words: list[int]
    ) -> int:
        del instruction, words
        return self._execute_set_pitch_conversion(3, CONVDP_ADDRESS)

    def _execute_setcmp(
        self, instruction: Instruction, words: list[int]
    ) -> int:
        del instruction, words
        return self._execute_set_pitch_conversion(11, CONVMP_ADDRESS)

    def _execute_setcsp(
        self, instruction: Instruction, words: list[int]
    ) -> int:
        del instruction, words
        return self._execute_set_pitch_conversion(1, CONVSP_ADDRESS)

    def _execute_trapl(
        self, instruction: Instruction, words: list[int]
    ) -> int:
        del instruction
        trap_number = words[1]
        if trap_number & 0x8000:
            trap_number -= 0x1_0000
        vector_address = (
            0xFFFF_FFE0 - (trap_number << 5)
        ) & MASK32
        return_pc = self.state.pc
        saved_st = self.state.st
        saved_pc_address = (self.state.sp - 32) & MASK32
        saved_st_address = (self.state.sp - 64) & MASK32

        self.state.memory.write_bits(saved_pc_address, 32, return_pc)
        self.state.memory.write_bits(saved_st_address, 32, saved_st)
        self.state.sp = saved_st_address
        vector = self.state.memory.read_bits(vector_address, 32)
        self.state.st = 0x0000_0010
        self.state.pc = vector & 0xFFFF_FFF0

        assert self._active_trace is not None
        self._active_trace.transactions.extend(
            [
                {
                    "class": "data_write",
                    "purpose": "trap_return_pc",
                    "bit_address": saved_pc_address,
                    "width": 32,
                    "value": return_pc,
                },
                {
                    "class": "data_write",
                    "purpose": "trap_saved_st",
                    "bit_address": saved_st_address,
                    "width": 32,
                    "value": saved_st,
                },
                {
                    "class": "interrupt_vector_fetch",
                    "bit_address": vector_address,
                    "width": 32,
                    "value": vector,
                },
            ]
        )
        self._active_trace.notes.append(
            "successful atomic TRAPL abstraction; stack/vector "
            "fault and retry pending"
        )
        return 10 if saved_st_address & 0x1F == 0 else 12

    def _execute_vlcol(
        self, instruction: Instruction, words: list[int]
    ) -> int:
        del instruction, words
        color = self.state.read_reg("B", 9)
        self.state.vram_color_latch = color
        assert self._active_trace is not None
        self._active_trace.transactions.append(
            {
                "class": "special_vram_color_load",
                "bit_address": 0,
                "width": 32,
                "value": color,
                "status_code": 0b0111,
            }
        )
        self._new_hidden_write_states = 1
        self._active_trace.notes.append(
            "successful VLCOL abstraction; special-cycle fault/retry pending"
        )
        return 2
