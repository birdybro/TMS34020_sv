"""Structurally independent, deliberately partial TMS34020 reference model."""

from __future__ import annotations

from dataclasses import dataclass, field
from typing import Any, Callable

from tools.isa.isa_db import IsaDatabase, Instruction
from .cache import InstructionCache
from .state import (
    CONFIG_ADDRESS,
    CONVDP_ADDRESS,
    CONVMP_ADDRESS,
    CONVSP_ADDRESS,
    CONTROL_ADDRESS,
    DPYCTL_ADDRESS,
    HSTCTLH_ADDRESS,
    MASK32,
    PMASKH_ADDRESS,
    PMASKL_ADDRESS,
    PSIZE_ADDRESS,
    ProcessorState,
)

N_BIT = 31
C_BIT = 30
Z_BIT = 29
V_BIT = 28
IE_BIT = 21
IX_BIT = 25
BF_BIT = 26
MAX_BOUNDED_GRAPHICS_PIXELS = 65_536


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
            "DIVS": self._execute_divs,
            "DIVU": self._execute_divu,
            "MODS": self._execute_mods,
            "MODU": self._execute_modu,
            "MPYS": self._execute_mpys,
            "MPYU": self._execute_mpyu,
            "SWAPF": self._execute_swapf,
            "DSJ": self._execute_dsj_family,
            "DSJEQ": self._execute_dsj_family,
            "DSJNE": self._execute_dsj_family,
            "DSJS": self._execute_dsjs,
            "EINT": self._execute_eint,
            "EXGF": self._execute_exgf,
            "EXGPC": self._execute_exgpc,
            "GETPC": self._execute_getpc,
            "GETST": self._execute_getst,
            "CALL": self._execute_call,
            "CALLA": self._execute_calla,
            "CALLR": self._execute_callr,
            "JACC": self._execute_jacc,
            "JR.L": self._execute_jr_long,
            "JUMP": self._execute_jump,
            "POPST": self._execute_popst,
            "PUSHST": self._execute_pushst,
            "PUTST": self._execute_putst,
            "RETI": self._execute_reti,
            "RETM": self._execute_retm,
            "RETS": self._execute_rets,
            "MMFM": self._execute_mmfm,
            "MMTM": self._execute_mmtm,
            "ADDK": self._execute_addk,
            "SUBK": self._execute_subk,
            "MOVK": self._execute_movk,
            "MOVI.W": self._execute_movi_word,
            "MOVI.L": self._execute_movi_long,
            "MOVE": self._execute_move,
            "MOVE.MM": self._execute_move_memory_to_memory,
            "MOVE.MM.POST": (
                self._execute_move_memory_to_memory_postincrement
            ),
            "MOVE.MM.PRE": (
                self._execute_move_memory_to_memory_predecrement
            ),
            "MOVE.MM.OFFSET": self._execute_move_memory_to_memory_offset,
            "MOVE.MM.SOFF_POST": (
                self._execute_move_memory_to_memory_source_offset_postincrement
            ),
            "MOVE.MM.SABS_POST": (
                self._execute_move_memory_to_memory_absolute_source_postincrement
            ),
            "MOVE.MM.ABS": self._execute_move_memory_to_memory_absolute,
            "MOVE.MR": self._execute_move_memory_to_register,
            "MOVE.MR.POST": (
                self._execute_move_memory_to_register_postincrement
            ),
            "MOVE.MR.PRE": (
                self._execute_move_memory_to_register_predecrement
            ),
            "MOVE.MR.OFFSET": self._execute_move_memory_to_register_offset,
            "MOVE.MR.ABS": self._execute_move_memory_to_register_absolute,
            "MOVE.RM": self._execute_move_register_to_memory,
            "MOVE.RM.POST": (
                self._execute_move_register_to_memory_postincrement
            ),
            "MOVE.RM.PRE": (
                self._execute_move_register_to_memory_predecrement
            ),
            "MOVE.RM.OFFSET": self._execute_move_register_to_memory_offset,
            "MOVE.RM.ABS": self._execute_move_register_to_memory_absolute,
            "MOVB.RM": self._execute_movb_register_to_memory,
            "MOVB.RM.OFFSET": self._execute_movb_register_to_memory,
            "MOVB.RM.ABS": self._execute_movb_register_to_memory,
            "MOVB.MR": self._execute_movb_memory_to_register,
            "MOVB.MR.OFFSET": self._execute_movb_memory_to_register,
            "MOVB.MR.ABS": self._execute_movb_memory_to_register,
            "MOVB.MM": self._execute_movb_memory_to_memory,
            "MOVB.MM.OFFSET": self._execute_movb_memory_to_memory,
            "MOVB.MM.ABS": self._execute_movb_memory_to_memory,
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
            "CMPXY": self._execute_cmpxy,
            "CPW": self._execute_cpw,
            "CVDXYL": self._execute_cvdxyl,
            "CVMXYL": self._execute_cvmxyl,
            "CVSXYL": self._execute_cvsxyl,
            "CVXYL": self._execute_cvxyl,
            "AND": self._execute_and,
            "ANDN": self._execute_andn,
            "OR": self._execute_or,
            "XOR": self._execute_xor,
            "ANDNI": self._execute_andni,
            "BLMOVE": self._execute_blmove,
            "CEXEC.L": self._execute_cexec,
            "CEXEC.S": self._execute_cexec,
            "CLIP": self._execute_clip,
            "DRAV": self._execute_drav,
            "FILL.L": self._execute_fill,
            "FILL.XY": self._execute_fill,
            "FLINE": self._execute_fline,
            "FPIXEQ": self._execute_find_pixel,
            "FPIXNE": self._execute_find_pixel,
            "CMOVGC.1": self._execute_cmovgc,
            "CMOVGC.2": self._execute_cmovgc,
            "CMOVCG": self._execute_cmovcg,
            "CMOVMC.POST.C": self._execute_coprocessor_memory_transfer,
            "CMOVCM.POST.C": self._execute_coprocessor_memory_transfer,
            "CMOVCM.PRE.C": self._execute_coprocessor_memory_transfer,
            "CMOVMC.POST.R": self._execute_coprocessor_memory_transfer,
            "CMOVMC.PRE.C": self._execute_coprocessor_memory_transfer,
            "LINIT": self._execute_linit,
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
            "TRAP": self._execute_trap,
            "TRAPL": self._execute_trapl,
            "VLCOL": self._execute_vlcol,
        }
        self._active_trace: StepTrace | None = None
        self._new_hidden_write_states = 0
        self.coprocessor_read_data: list[int] = []

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

    def queue_coprocessor_read_data(self, values: list[int]) -> None:
        """Queue deterministic 32-bit words returned by a coprocessor."""

        if any(not 0 <= value <= MASK32 for value in values):
            raise ValueError("coprocessor data words must fit in 32 bits")
        self.coprocessor_read_data.extend(values)

    def snapshot(self) -> dict[str, Any]:
        return {
            "model_schema_version": 4,
            "state": self.state.snapshot(),
            "cache": self.cache.snapshot(),
            "trace": [event.snapshot() for event in self.trace],
            "supported_mnemonics": list(self.supported_mnemonics),
            "coprocessor_read_data": list(self.coprocessor_read_data),
        }

    @classmethod
    def from_snapshot(cls, snapshot: dict[str, Any]) -> "Tms34020Model":
        version = snapshot.get("model_schema_version")
        if version not in (1, 2, 3, 4):
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
        model.coprocessor_read_data = [
            int(value) for value in snapshot.get("coprocessor_read_data", [])
        ]
        if any(
            not 0 <= value <= MASK32
            for value in model.coprocessor_read_data
        ):
            raise ValueError("snapshot coprocessor data must fit in 32 bits")
        if list(model.supported_mnemonics) != snapshot["supported_mnemonics"]:
            raise ValueError("snapshot model coverage differs from executable")
        return model

    def step(self) -> StepTrace:
        if self.state.halted:
            raise ModelError("processor is halted in IDLE")
        state_checkpoint = self.state.snapshot()
        cache_checkpoint = self.cache.snapshot()
        coprocessor_checkpoint = list(self.coprocessor_read_data)
        start_pc = self.state.pc
        try:
            force_instruction_bypass = (
                self.state.force_next_instruction_bypass
            )
            fetch_transactions: list[dict[str, int | str]] = []
            first_word, first_fetch_complete = self._fetch_instruction_word(
                start_pc, fetch_transactions, force_instruction_bypass
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
                    force_instruction_bypass,
                )
                words.append(word)
                fetch_timing_complete &= timing_complete

            self.state.force_next_instruction_bypass = False

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
            self.coprocessor_read_data = coprocessor_checkpoint
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
        force_bypass: bool = False,
    ) -> tuple[int, bool]:
        cache_disable = bool(
            self.state.read_io(CONTROL_ADDRESS) & (1 << 15)
        ) or force_bypass
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
                "forced_bypass": int(force_bypass),
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

    @staticmethod
    def _signed_divmod_toward_zero(
        dividend: int, divisor: int
    ) -> tuple[int, int]:
        quotient_magnitude = abs(dividend) // abs(divisor)
        quotient = (
            -quotient_magnitude
            if (dividend < 0) != (divisor < 0)
            else quotient_magnitude
        )
        remainder = dividend - quotient * divisor
        return quotient, remainder

    def _record_divide_result(
        self,
        mnemonic: str,
        pair: bool,
        overflow: bool,
        raw_early_overflow: bool,
    ) -> None:
        assert self._active_trace is not None
        width = 64 if pair else 32
        result = "overflow; destination preserved" if overflow else "success"
        self._active_trace.notes.append(
            f"{mnemonic} {width}-bit dividend: {result}"
        )
        if raw_early_overflow:
            self._active_trace.notes.append(
                "divide terminated by divisor-zero/high-half early-overflow path"
            )

    def _execute_divu(
        self, instruction: Instruction, words: list[int]
    ) -> int:
        del instruction
        register_file, source_index, destination_index = (
            self._decode_source_destination(words[0])
        )
        divisor = self.state.read_reg(register_file, source_index)
        high_or_dividend = self.state.read_reg(
            register_file, destination_index
        )
        pair = destination_index & 1 == 0
        low = (
            self.state.read_reg(register_file, destination_index + 1)
            if pair
            else high_or_dividend
        )
        dividend = (
            (high_or_dividend << 32) | low
            if pair
            else high_or_dividend
        )
        divisor_zero = divisor == 0
        quotient = 0 if divisor_zero else dividend // divisor
        remainder = 0 if divisor_zero else dividend % divisor
        overflow = divisor_zero or quotient > MASK32

        if not overflow:
            self.state.write_reg(
                register_file, destination_index, quotient
            )
            if pair:
                self.state.write_reg(
                    register_file, destination_index + 1, remainder
                )
        self._set_status_bit(Z_BIT, not overflow and quotient == 0)
        self._set_status_bit(V_BIT, overflow)

        raw_early_overflow = divisor_zero or (pair and quotient > MASK32)
        self._record_divide_result(
            "DIVU", pair, overflow, raw_early_overflow
        )
        if pair and raw_early_overflow:
            return 5
        if not pair and divisor_zero:
            return 7
        return 37

    def _execute_divs(
        self, instruction: Instruction, words: list[int]
    ) -> int:
        del instruction
        register_file, source_index, destination_index = (
            self._decode_source_destination(words[0])
        )
        divisor_word = self.state.read_reg(register_file, source_index)
        high_or_dividend = self.state.read_reg(
            register_file, destination_index
        )
        pair = destination_index & 1 == 0
        low = (
            self.state.read_reg(register_file, destination_index + 1)
            if pair
            else high_or_dividend
        )
        divisor = self._signed_word(divisor_word)
        if pair:
            dividend_word = (high_or_dividend << 32) | low
            dividend = (
                dividend_word - (1 << 64)
                if dividend_word & (1 << 63)
                else dividend_word
            )
        else:
            dividend = self._signed_word(high_or_dividend)

        divisor_zero = divisor == 0
        if divisor_zero:
            quotient = 0
            remainder = 0
        else:
            quotient, remainder = self._signed_divmod_toward_zero(
                dividend, divisor
            )
        overflow = divisor_zero or not (
            -0x8000_0000 <= quotient <= 0x7FFF_FFFF
        )
        raw_early_overflow = divisor_zero or abs(quotient) > MASK32

        if not overflow:
            self.state.write_reg(
                register_file, destination_index, quotient
            )
            if pair:
                self.state.write_reg(
                    register_file, destination_index + 1, remainder
                )
        result_word = quotient & MASK32
        n_value = (
            not raw_early_overflow
            and (quotient < 0 or result_word == 0x8000_0000)
        )
        self._set_status_bit(N_BIT, n_value)
        self._set_status_bit(Z_BIT, not overflow and quotient == 0)
        self._set_status_bit(V_BIT, overflow)

        self._record_divide_result(
            "DIVS", pair, overflow, raw_early_overflow
        )
        if raw_early_overflow and not divisor_zero:
            assert self._active_trace is not None
            self._active_trace.notes.append(
                "7-state nonzero early-overflow timing provisionally uses "
                "the magnitude comparison tracked by RSC-0027/OQ-0018"
            )
            self.state.timing_complete = False
        if raw_early_overflow:
            return 7
        if result_word == 0x8000_0000:
            return 41
        return 40 if pair else 39

    def _execute_modu(
        self, instruction: Instruction, words: list[int]
    ) -> int:
        del instruction
        register_file, source_index, destination_index = (
            self._decode_source_destination(words[0])
        )
        divisor = self.state.read_reg(register_file, source_index)
        dividend = self.state.read_reg(register_file, destination_index)
        divisor_zero = divisor == 0
        remainder = dividend if divisor_zero else dividend % divisor

        self.state.write_reg(register_file, destination_index, remainder)
        self._set_status_bit(Z_BIT, not divisor_zero and remainder == 0)
        self._set_status_bit(V_BIT, divisor_zero)
        assert self._active_trace is not None
        self._active_trace.notes.append(
            "MODU 32-bit remainder: "
            + ("zero divisor; result equals old destination" if divisor_zero
               else "destination written")
        )
        return 3 if divisor_zero else 35

    def _execute_mods(
        self, instruction: Instruction, words: list[int]
    ) -> int:
        del instruction
        register_file, source_index, destination_index = (
            self._decode_source_destination(words[0])
        )
        divisor = self._signed_word(
            self.state.read_reg(register_file, source_index)
        )
        dividend = self._signed_word(
            self.state.read_reg(register_file, destination_index)
        )
        divisor_zero = divisor == 0
        if divisor_zero:
            remainder = dividend
        else:
            _, remainder = self._signed_divmod_toward_zero(
                dividend, divisor
            )

        self.state.write_reg(register_file, destination_index, remainder)
        result_word = remainder & MASK32
        self._set_status_bit(N_BIT, not divisor_zero and remainder < 0)
        self._set_status_bit(Z_BIT, not divisor_zero and remainder == 0)
        self._set_status_bit(V_BIT, divisor_zero)
        assert self._active_trace is not None
        self._active_trace.notes.append(
            "MODS signed remainder: "
            + ("zero divisor; result equals old destination" if divisor_zero
               else "destination written")
        )
        if divisor_zero:
            return 3
        return 41 if result_word == 0x8000_0000 else 40

    def _execute_multiply(
        self,
        words: list[int],
        *,
        signed_operation: bool,
    ) -> int:
        first_word = words[0]
        register_file, source_index, destination_index = (
            self._decode_source_destination(first_word)
        )
        encoded_field_size = self.state.st & 0x1F
        field_size = encoded_field_size or 32
        if field_size & 1:
            raise ModelError(
                "MPYS/MPYU behavior is undocumented for odd FS1"
            )

        raw_source = self.state.read_reg(register_file, source_index)
        raw_destination = self.state.read_reg(
            register_file, destination_index
        )
        field_mask = (
            MASK32 if field_size == 32 else (1 << field_size) - 1
        )
        multiplier = raw_source & field_mask
        if (
            signed_operation
            and multiplier & (1 << (field_size - 1))
        ):
            multiplier -= 1 << field_size
        multiplicand = (
            self._signed_word(raw_destination)
            if signed_operation
            else raw_destination
        )
        product = multiplier * multiplicand
        product_word = product & 0xFFFF_FFFF_FFFF_FFFF
        product_high = (product_word >> 32) & MASK32
        product_low = product_word & MASK32

        if destination_index & 1:
            self.state.write_reg(
                register_file, destination_index, product_low
            )
        else:
            self.state.write_reg(
                register_file, destination_index, product_high
            )
            self.state.write_reg(
                register_file, destination_index + 1, product_low
            )

        if signed_operation:
            self._set_status_bit(N_BIT, product < 0)
        self._set_status_bit(Z_BIT, product == 0)
        assert self._active_trace is not None
        self._active_trace.notes.append(
            ("signed" if signed_operation else "unsigned")
            + f" {field_size}-by-32 multiply; status from full product"
        )
        states = 5 + field_size // 2
        if not signed_operation and raw_source & 0x8000_0000:
            states += 1
        return states

    def _execute_mpys(
        self, instruction: Instruction, words: list[int]
    ) -> int:
        del instruction
        return self._execute_multiply(words, signed_operation=True)

    def _execute_mpyu(
        self, instruction: Instruction, words: list[int]
    ) -> int:
        del instruction
        return self._execute_multiply(words, signed_operation=False)

    def _execute_swapf(
        self, instruction: Instruction, words: list[int]
    ) -> int:
        del instruction
        register_file, source_index, destination_index = (
            self._decode_source_destination(words[0])
        )
        bit_address = self.state.read_reg(register_file, source_index)
        register_value = self.state.read_reg(
            register_file, destination_index
        )
        encoded_field_size = self.state.st & 0x1F
        field_size = encoded_field_size or 32
        bit_offset = bit_address & 0x1F
        if bit_offset + field_size > 32:
            raise ModelError(
                "SWAPF field spanning a 32-bit word is outside the "
                "documented valid domain"
            )

        word_address = bit_address & 0xFFFF_FFE0
        old_word = self.state.memory.read_bits(word_address, 32)
        field_mask = (
            MASK32 if field_size == 32 else (1 << field_size) - 1
        )
        old_field = (old_word >> bit_offset) & field_mask
        positioned_mask = (field_mask << bit_offset) & MASK32
        new_word = (
            (old_word & ~positioned_mask)
            | ((register_value & field_mask) << bit_offset)
        ) & MASK32
        result = old_field
        if (
            self.state.st & (1 << 5)
            and old_field & (1 << (field_size - 1))
        ):
            result |= ~field_mask & MASK32

        self.state.memory.write_bits(word_address, 32, new_word)
        self.state.write_reg(register_file, destination_index, result)
        self._set_status_bit(N_BIT, bool(result & 0x8000_0000))
        self._set_status_bit(Z_BIT, result == 0)
        self._set_status_bit(V_BIT, False)
        assert self._active_trace is not None
        self._active_trace.transactions.extend(
            (
                {
                    "class": "bus_locked_data_read",
                    "bit_address": word_address,
                    "width": 32,
                    "value": old_word,
                },
                {
                    "class": "bus_locked_data_write",
                    "bit_address": word_address,
                    "width": 32,
                    "value": new_word,
                },
            )
        )
        self._active_trace.notes.append(
            "successful 32-bit SWAPF boundary; physical lock, wait, "
            "interrupt, fault, retry, 16-bit-target, and I/O-register "
            "behavior remain pending"
        )
        self.state.timing_complete = False
        return 5

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

    def _complete_subroutine_call(
        self,
        target: int,
        mnemonic: str,
        machine_states: int | None,
        hidden_write_states: int | None,
    ) -> int | None:
        """Commit the architecturally visible part of a CALL-family operation."""
        return_pc = self.state.pc
        old_sp = self.state.sp
        new_sp = (old_sp - 32) & MASK32
        self.state.sp = new_sp
        self.state.memory.write_bits(new_sp, 32, return_pc)
        self.state.pc = target & 0xFFFF_FFF0
        assert self._active_trace is not None
        self._active_trace.transactions.append(
            {
                "class": "data_write",
                "purpose": "call_return_pc",
                "bit_address": new_sp,
                "width": 32,
                "value": return_pc,
            }
        )
        if hidden_write_states is not None:
            self._new_hidden_write_states = hidden_write_states
        self._active_trace.notes.append(
            f"successful atomic {mnemonic} abstraction; stack-write fault, "
            "retry, dynamic-width, and page-mode behavior pending"
        )
        if machine_states is None:
            self._active_trace.notes.append(
                "CALLA machine-state classification withheld because the "
                "primary alignment table is ambiguous (RSC-0024/OQ-0015)"
            )
        return machine_states

    def _execute_call(
        self, instruction: Instruction, words: list[int]
    ) -> int:
        del instruction
        register_file, index = self._decode_destination(words[0])
        # Capture the source before changing SP: CALL SP targets the old SP.
        target = self.state.read_reg(register_file, index)
        hidden_states = 1 if self.state.sp & 0x1F == 0 else 4
        result = self._complete_subroutine_call(
            target, "CALL", 3, hidden_states
        )
        assert result is not None
        return result

    def _execute_calla(
        self, instruction: Instruction, words: list[int]
    ) -> None:
        del instruction
        target = words[1] | (words[2] << 16)
        self._complete_subroutine_call(target, "CALLA", None, None)
        return None

    def _execute_callr(
        self, instruction: Instruction, words: list[int]
    ) -> int:
        del instruction
        displacement = words[1]
        if displacement & 0x8000:
            displacement -= 0x1_0000
        target = (self.state.pc + displacement * 16) & MASK32
        hidden_states = 1 if self.state.sp & 0x1F == 0 else 4
        result = self._complete_subroutine_call(
            target, "CALLR", 3, hidden_states
        )
        assert result is not None
        return result

    def _execute_jump(
        self, instruction: Instruction, words: list[int]
    ) -> int:
        del instruction
        register_file, index = self._decode_destination(words[0])
        target = self.state.read_reg(register_file, index)
        self.state.pc = target & 0xFFFF_FFF0
        return 2

    @staticmethod
    def _condition_true(condition_code: int, status: int) -> bool:
        n = bool(status & (1 << N_BIT))
        c = bool(status & (1 << C_BIT))
        z = bool(status & (1 << Z_BIT))
        v = bool(status & (1 << V_BIT))
        if condition_code == 0x0:
            return True
        if condition_code == 0x1:
            return not n and not z
        if condition_code == 0x2:
            return c or z
        if condition_code == 0x3:
            return not c and not z
        if condition_code == 0x4:
            return n != v
        if condition_code == 0x5:
            return n == v
        if condition_code == 0x6:
            return n != v or z
        if condition_code == 0x7:
            return n == v and not z
        if condition_code == 0x8:
            return c
        if condition_code == 0x9:
            return not c
        if condition_code == 0xA:
            return z
        if condition_code == 0xB:
            return not z
        if condition_code == 0xC:
            return v
        if condition_code == 0xD:
            return not v
        if condition_code == 0xE:
            return n
        if condition_code == 0xF:
            return not n
        raise ValueError("condition code must be four bits")

    def _execute_jr_long(
        self, instruction: Instruction, words: list[int]
    ) -> int:
        del instruction
        condition_code = (words[0] >> 8) & 0xF
        if not self._condition_true(condition_code, self.state.st):
            return 2

        displacement = words[1]
        if displacement & 0x8000:
            displacement -= 0x1_0000
        self.state.pc = (
            self.state.pc + displacement * 16
        ) & MASK32
        return 3

    def _execute_jacc(
        self, instruction: Instruction, words: list[int]
    ) -> int:
        del instruction
        condition_code = (words[0] >> 8) & 0xF
        if not self._condition_true(condition_code, self.state.st):
            return 3

        absolute_target = words[1] | (words[2] << 16)
        self.state.pc = absolute_target & 0xFFFF_FFF0
        return 4

    def _execute_dsj_family(
        self, instruction: Instruction, words: list[int]
    ) -> int:
        condition = (
            instruction.mnemonic == "DSJ"
            or (
                instruction.mnemonic == "DSJEQ"
                and bool(self.state.st & (1 << Z_BIT))
            )
            or (
                instruction.mnemonic == "DSJNE"
                and not bool(self.state.st & (1 << Z_BIT))
            )
        )
        if not condition:
            return 2

        register_file, index = self._decode_destination(words[0])
        result = (
            self.state.read_reg(register_file, index) - 1
        ) & MASK32
        self.state.write_reg(register_file, index, result)
        if result == 0:
            return 2

        displacement = words[1]
        if displacement & 0x8000:
            displacement -= 0x1_0000
        self.state.pc = (
            self.state.pc + displacement * 16
        ) & MASK32
        return 3

    def _execute_dsjs(
        self, instruction: Instruction, words: list[int]
    ) -> int:
        del instruction
        first_word = words[0]
        register_file, index = self._decode_destination(first_word)
        result = (
            self.state.read_reg(register_file, index) - 1
        ) & MASK32
        self.state.write_reg(register_file, index, result)
        if result == 0:
            return 2

        displacement = ((first_word >> 5) & 0x1F) * 16
        if first_word & 0x0400:
            displacement = -displacement
        self.state.pc = (self.state.pc + displacement) & MASK32
        return 3

    def _execute_putst(
        self, instruction: Instruction, words: list[int]
    ) -> int:
        del instruction
        register_file, index = self._decode_destination(words[0])
        self.state.st = self.state.read_reg(register_file, index)
        return 3

    def _execute_popst(
        self, instruction: Instruction, words: list[int]
    ) -> int:
        del instruction, words
        old_sp = self.state.sp
        value = self.state.memory.read_bits(old_sp, 32)
        self.state.st = value
        self.state.sp = (old_sp + 32) & MASK32
        assert self._active_trace is not None
        self._active_trace.transactions.append(
            {
                "class": "data_read",
                "purpose": "pop_status",
                "bit_address": old_sp,
                "width": 32,
                "value": value,
            }
        )
        self._active_trace.notes.append(
            "successful atomic POPST abstraction; stack-read fault, retry, "
            "dynamic-width, and page-mode behavior pending"
        )
        return 6 if old_sp & 0x1F == 0 else 7

    def _execute_pushst(
        self, instruction: Instruction, words: list[int]
    ) -> int:
        del instruction, words
        old_sp = self.state.sp
        new_sp = (old_sp - 32) & MASK32
        value = self.state.st
        self.state.sp = new_sp
        self.state.memory.write_bits(new_sp, 32, value)
        assert self._active_trace is not None
        self._active_trace.transactions.append(
            {
                "class": "data_write",
                "purpose": "push_status",
                "bit_address": new_sp,
                "width": 32,
                "value": value,
            }
        )
        self._new_hidden_write_states = 1 if old_sp & 0x1F == 0 else 2
        self._active_trace.notes.append(
            "successful atomic PUSHST abstraction; stack-write fault, retry, "
            "dynamic-width, and page-mode behavior pending"
        )
        return 2

    def _execute_rets(
        self, instruction: Instruction, words: list[int]
    ) -> int:
        del instruction
        old_sp = self.state.sp
        return_pc = self.state.memory.read_bits(old_sp, 32)
        argument_words = words[0] & 0x1F
        self.state.pc = return_pc & 0xFFFF_FFF0
        self.state.sp = (
            old_sp + 32 + argument_words * 16
        ) & MASK32
        assert self._active_trace is not None
        self._active_trace.transactions.append(
            {
                "class": "data_read",
                "purpose": "return_subroutine_pc",
                "bit_address": old_sp,
                "width": 32,
                "value": return_pc,
            }
        )
        self._active_trace.notes.append(
            "successful atomic RETS abstraction; stack-read fault, retry, "
            "dynamic-width, page-mode, and redirect timing pending"
        )
        return 5 if old_sp & 0x1F == 0 else 6

    def _execute_reti(
        self, instruction: Instruction, words: list[int]
    ) -> int:
        del instruction, words
        return self._execute_interrupt_return(monitor_return=False)

    def _execute_retm(
        self, instruction: Instruction, words: list[int]
    ) -> int:
        del instruction, words
        return self._execute_interrupt_return(monitor_return=True)

    def _execute_interrupt_return(self, monitor_return: bool) -> int:
        old_sp = self.state.sp
        restored_st = self.state.memory.read_bits(old_sp, 32)
        continuation_mask = (1 << IX_BIT) | (1 << BF_BIT)
        if restored_st & continuation_mask:
            context = "BF" if restored_st & (1 << BF_BIT) else "IX"
            mnemonic = "RETM" if monitor_return else "RETI"
            raise UnsupportedInstruction(
                f"{mnemonic} {context} internal-state continuation is classified "
                "but not implemented"
            )

        saved_pc_address = (old_sp + 32) & MASK32
        restored_pc = self.state.memory.read_bits(saved_pc_address, 32)
        self.state.st = restored_st
        self.state.pc = restored_pc & 0xFFFF_FFF0
        self.state.sp = (old_sp + 64) & MASK32
        self.state.force_next_instruction_bypass = monitor_return
        assert self._active_trace is not None
        self._active_trace.transactions.extend(
            [
                {
                    "class": "data_read",
                    "purpose": "return_interrupt_st",
                    "bit_address": old_sp,
                    "width": 32,
                    "value": restored_st,
                },
                {
                    "class": "data_read",
                    "purpose": "return_interrupt_pc",
                    "bit_address": saved_pc_address,
                    "width": 32,
                    "value": restored_pc,
                },
            ]
        )
        self._active_trace.notes.append(
            "successful atomic normal-context "
            f"{'RETM' if monitor_return else 'RETI'} abstraction; IX/BF "
            "internal-state restore, stack fault/retry, dynamic-width, "
            "page-mode, and final pending-interrupt recognition remain pending"
        )
        if monitor_return:
            self._active_trace.notes.append(
                "the next complete instruction packet is forced to the "
                "native memory bypass; one-instruction interrupt/single-step "
                "recognition delay is documented but not scheduled"
            )
        return 10 if monitor_return else 7

    @staticmethod
    def _multiple_register_indices(
        mask: int, memory_to_registers: bool
    ) -> list[int]:
        if not 0 <= mask <= 0xFFFF:
            raise ValueError("register-list mask must fit in 16 bits")
        if memory_to_registers:
            return [
                index for index in range(15, -1, -1)
                if mask & (1 << index)
            ]
        return [
            index for index in range(16)
            if mask & (1 << (15 - index))
        ]

    def _validate_multiple_register_list(
        self,
        pointer_index: int,
        mask: int,
        memory_to_registers: bool,
    ) -> list[int]:
        indices = self._multiple_register_indices(
            mask, memory_to_registers
        )
        if not indices:
            raise ModelError(
                "empty MMFM/MMTM register list is outside the documented "
                "portable model domain"
            )
        if pointer_index in indices:
            raise ModelError(
                "MMFM/MMTM pointer register in the register list has "
                "documented unpredictable results"
            )
        return indices

    def _execute_mmfm(
        self, instruction: Instruction, words: list[int]
    ) -> int:
        del instruction
        register_file, pointer_index = self._decode_destination(words[0])
        indices = self._validate_multiple_register_list(
            pointer_index, words[1], memory_to_registers=True
        )
        pointer = self.state.read_reg(register_file, pointer_index)
        reads: list[tuple[int, int, int]] = []
        for register_index in indices:
            value = self.state.memory.read_bits(pointer, 32)
            reads.append((register_index, pointer, value))
            pointer = (pointer + 32) & MASK32

        for register_index, bit_address, value in reads:
            self.state.write_reg(register_file, register_index, value)
            assert self._active_trace is not None
            self._active_trace.transactions.append(
                {
                    "class": "data_read",
                    "purpose": "multiple_register_restore",
                    "bit_address": bit_address,
                    "width": 32,
                    "value": value,
                    "register_index": register_index,
                }
            )
        self.state.write_reg(register_file, pointer_index, pointer)
        assert self._active_trace is not None
        self._active_trace.notes.append(
            "successful atomic MMFM abstraction; external page-mode, "
            "dynamic-width, wait, fault/retry, partial-list continuation, "
            "and physical timing remain pending (RSC-0033)"
        )
        self.state.timing_complete = False
        return len(indices) + 5

    def _execute_mmtm(
        self, instruction: Instruction, words: list[int]
    ) -> int:
        del instruction
        register_file, pointer_index = self._decode_destination(words[0])
        indices = self._validate_multiple_register_list(
            pointer_index, words[1], memory_to_registers=False
        )
        old_pointer = self.state.read_reg(register_file, pointer_index)
        values = [
            (register_index, self.state.read_reg(register_file, register_index))
            for register_index in indices
        ]
        pointer = old_pointer
        writes: list[tuple[int, int, int]] = []
        for register_index, value in values:
            pointer = (pointer - 32) & MASK32
            writes.append((register_index, pointer, value))

        for register_index, bit_address, value in writes:
            self.state.memory.write_bits(bit_address, 32, value)
            assert self._active_trace is not None
            self._active_trace.transactions.append(
                {
                    "class": "data_write",
                    "purpose": "multiple_register_save",
                    "bit_address": bit_address,
                    "width": 32,
                    "value": value,
                    "register_index": register_index,
                }
            )
        self.state.write_reg(register_file, pointer_index, pointer)
        self._set_status_bit(N_BIT, not bool(old_pointer & 0x8000_0000))

        register_count = len(indices)
        if old_pointer & 0x7:
            visible_states = 4 if register_count == 1 else register_count + 7
            hidden_states = 2 if register_count <= 4 else 1
            data_alignment = "bit"
        elif old_pointer & 0x1F:
            visible_states = 4 if register_count == 1 else register_count + 6
            hidden_states = 1
            data_alignment = "byte"
        else:
            visible_states = 4 if register_count == 1 else register_count + 4
            hidden_states = 1
            data_alignment = "long_word"
        assert self._active_trace is not None
        if self._active_trace.start_pc & 0x1F:
            visible_states += 1
        self._new_hidden_write_states = hidden_states
        self._active_trace.notes.append(
            f"successful atomic MMTM abstraction; {data_alignment}-aligned "
            "source pointer timing class selected, but external page-mode, "
            "dynamic-width, wait, fault/retry, partial-list continuation, "
            "and physical write retirement remain pending"
        )
        self.state.timing_complete = False
        return visible_states

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

    @staticmethod
    def _field_alignment_case(bit_address: int, width: int) -> int:
        bit_offset = bit_address & 0x1F
        crosses_long_word = bit_offset + width > 32
        start_byte_aligned = (bit_address & 0x7) == 0
        end_byte_aligned = ((bit_address + width) & 0x7) == 0
        if not crosses_long_word:
            return 1 if start_byte_aligned and end_byte_aligned else 2
        if start_byte_aligned and end_byte_aligned:
            return 3
        if start_byte_aligned or end_byte_aligned:
            return 4
        return 5

    def _execute_move_register_to_memory(
        self, instruction: Instruction, words: list[int]
    ) -> int:
        del instruction
        return self._execute_move_register_to_memory_common(words, "ordinary")

    def _execute_move_register_to_memory_postincrement(
        self, instruction: Instruction, words: list[int]
    ) -> int:
        del instruction
        return self._execute_move_register_to_memory_common(
            words, "postincrement"
        )

    def _execute_move_register_to_memory_predecrement(
        self, instruction: Instruction, words: list[int]
    ) -> int:
        del instruction
        return self._execute_move_register_to_memory_common(
            words, "predecrement"
        )

    def _execute_move_register_to_memory_offset(
        self, instruction: Instruction, words: list[int]
    ) -> int:
        del instruction
        return self._execute_move_register_to_memory_common(words, "offset")

    def _execute_move_register_to_memory_common(
        self, words: list[int], address_mode: str
    ) -> int:
        if self.state.read_io(CONFIG_ADDRESS) & 1:
            raise UnsupportedInstruction(
                "MOVE.RM big-endian field mapping is classified but not modeled"
            )
        first_word = words[0]
        register_file, source_index, pointer_index = (
            self._decode_source_destination(first_word)
        )
        width = self._selected_field_size(first_word)
        pointer_before = self.state.read_reg(register_file, pointer_index)
        bit_address = pointer_before
        if address_mode == "predecrement":
            bit_address = (pointer_before - width) & MASK32
            self.state.write_reg(register_file, pointer_index, bit_address)
        elif address_mode == "offset":
            signed_offset = words[1]
            if signed_offset & 0x8000:
                signed_offset -= 0x1_0000
            bit_address = (pointer_before + signed_offset) & MASK32
        source = self.state.read_reg(register_file, source_index)
        field_mask = MASK32 if width == 32 else (1 << width) - 1
        value = source & field_mask
        alignment_case = self._field_alignment_case(bit_address, width)
        hidden_states = (0, 1, 2, 2, 3, 4)[alignment_case]
        self.state.memory.write_bits(bit_address, width, value)
        pointer_after = bit_address
        if address_mode == "postincrement":
            pointer_after = (bit_address + width) & MASK32
            self.state.write_reg(register_file, pointer_index, pointer_after)
        self._new_hidden_write_states = hidden_states
        assert self._active_trace is not None
        transaction = {
            "class": "data_write",
            "purpose": (
                f"field_move_register_to_memory_{address_mode}"
                if address_mode != "ordinary"
                else "field_move_register_to_memory"
            ),
            "bit_address": bit_address,
            "width": width,
            "value": value,
            "alignment_case": alignment_case,
            "hidden_write_states": hidden_states,
        }
        if address_mode in ("postincrement", "predecrement"):
            transaction.update(
                {
                    "pointer_before": pointer_before,
                    "pointer_after": pointer_after,
                }
            )
            if address_mode == "predecrement":
                transaction["same_register_source_after_update"] = int(
                    source_index == pointer_index
                )
        elif address_mode == "offset":
            transaction.update(
                {
                    "base_address": pointer_before,
                    "signed_offset": signed_offset,
                }
            )
        self._active_trace.transactions.append(transaction)
        self._active_trace.notes.append(
            "logical little-endian field insertion"
            + (
                " with captured-address postincrement"
                if address_mode == "postincrement"
                else (
                    " with destination predecrement before source capture"
                    if address_mode == "predecrement"
                    else (
                        " with an unmodified base plus signed 16-bit offset"
                        if address_mode == "offset"
                        else ""
                    )
                )
            )
            + "; physical byte strobes, "
            "read/modify/write, dynamic width, wait, page, fault, and retry "
            "sequencing remain pending"
        )
        if address_mode == "offset":
            return 3
        return 2 if address_mode == "predecrement" else 1

    def _execute_move_memory_to_register(
        self, instruction: Instruction, words: list[int]
    ) -> int:
        del instruction
        return self._execute_move_memory_to_register_common(words, "ordinary")

    def _execute_move_memory_to_register_postincrement(
        self, instruction: Instruction, words: list[int]
    ) -> int:
        del instruction
        return self._execute_move_memory_to_register_common(
            words, "postincrement"
        )

    def _execute_move_memory_to_register_predecrement(
        self, instruction: Instruction, words: list[int]
    ) -> int:
        del instruction
        return self._execute_move_memory_to_register_common(
            words, "predecrement"
        )

    def _execute_move_memory_to_register_offset(
        self, instruction: Instruction, words: list[int]
    ) -> int:
        del instruction
        return self._execute_move_memory_to_register_common(words, "offset")

    def _execute_move_memory_to_register_common(
        self, words: list[int], address_mode: str
    ) -> int:
        if self.state.read_io(CONFIG_ADDRESS) & 1:
            raise UnsupportedInstruction(
                "MOVE.MR big-endian field mapping is classified but not modeled"
            )
        first_word = words[0]
        register_file, pointer_index, destination_index = (
            self._decode_source_destination(first_word)
        )
        field_bank = (first_word >> 9) & 1
        width = self._selected_field_size(first_word)
        sign_extend = bool(
            self.state.st & (1 << (field_bank * 6 + 5))
        )
        pointer_before = self.state.read_reg(register_file, pointer_index)
        bit_address = pointer_before
        if address_mode == "predecrement":
            bit_address = (pointer_before - width) & MASK32
            self.state.write_reg(register_file, pointer_index, bit_address)
        elif address_mode == "offset":
            signed_offset = words[1]
            if signed_offset & 0x8000:
                signed_offset -= 0x1_0000
            bit_address = (pointer_before + signed_offset) & MASK32
        raw_value = self.state.memory.read_bits(bit_address, width)
        result = raw_value
        if (
            sign_extend
            and width < 32
            and raw_value & (1 << (width - 1))
        ):
            result |= MASK32 ^ ((1 << width) - 1)
        result &= MASK32
        alignment_case = self._field_alignment_case(bit_address, width)
        if address_mode == "predecrement":
            machine_states = (4 if alignment_case <= 2 else 5) + int(
                sign_extend
            )
        elif address_mode == "offset":
            machine_states = (4 if alignment_case <= 2 else 5) + 2 * int(
                sign_extend
            )
        else:
            machine_states = (3 if alignment_case <= 2 else 4) + int(
                sign_extend
            )
        pointer_after = bit_address
        if address_mode == "postincrement":
            pointer_after = (bit_address + width) & MASK32
            self.state.write_reg(register_file, pointer_index, pointer_after)
        self.state.write_reg(register_file, destination_index, result)
        self._set_status_bit(N_BIT, bool(result & 0x8000_0000))
        self._set_status_bit(Z_BIT, result == 0)
        self._set_status_bit(V_BIT, False)
        assert self._active_trace is not None
        transaction = {
            "class": "data_read",
            "purpose": (
                f"field_move_memory_to_register_{address_mode}"
                if address_mode != "ordinary"
                else "field_move_memory_to_register"
            ),
            "bit_address": bit_address,
            "width": width,
            "value": raw_value,
            "extended_result": result,
            "alignment_case": alignment_case,
            "sign_extend": int(sign_extend),
        }
        if address_mode in ("postincrement", "predecrement"):
            transaction.update(
                {
                    "pointer_before": pointer_before,
                    "pointer_after": pointer_after,
                    "same_register_data_wins": int(
                        pointer_index == destination_index
                    ),
                }
            )
        elif address_mode == "offset":
            transaction.update(
                {
                    "base_address": pointer_before,
                    "signed_offset": signed_offset,
                }
            )
        self._active_trace.transactions.append(transaction)
        self._active_trace.notes.append(
            "logical little-endian field extraction"
            + (
                " with captured-source postincrement; Rs=Rd loaded-data "
                "priority is CORROBORATED under RSC-0036/OQ-0024"
                if address_mode == "postincrement"
                else (
                    " with source predecrement before read; TI explicitly "
                    "makes loaded data win when Rs=Rd"
                    if address_mode == "predecrement"
                    else (
                        " with an unmodified base plus signed 16-bit offset"
                        if address_mode == "offset"
                        else ""
                    )
                )
            )
            + "; physical dynamic-width, "
            "wait, page, fault, retry, interrupt, and I/O sequencing remain "
            "pending"
        )
        return machine_states

    def _execute_move_memory_to_memory(
        self, instruction: Instruction, words: list[int]
    ) -> int:
        del instruction
        return self._execute_move_memory_to_memory_common(words, "ordinary")

    def _execute_move_memory_to_memory_postincrement(
        self, instruction: Instruction, words: list[int]
    ) -> int:
        del instruction
        return self._execute_move_memory_to_memory_common(
            words, "postincrement"
        )

    def _execute_move_memory_to_memory_predecrement(
        self, instruction: Instruction, words: list[int]
    ) -> int:
        del instruction
        return self._execute_move_memory_to_memory_common(
            words, "predecrement"
        )

    def _execute_move_memory_to_memory_offset(
        self, instruction: Instruction, words: list[int]
    ) -> int:
        del instruction
        return self._execute_move_memory_to_memory_common(words, "offset")

    def _execute_move_memory_to_memory_source_offset_postincrement(
        self, instruction: Instruction, words: list[int]
    ) -> int:
        del instruction
        return self._execute_move_memory_to_memory_common(
            words, "source_offset_destination_postincrement"
        )

    def _execute_move_memory_to_memory_common(
        self, words: list[int], address_mode: str
    ) -> int:
        if self.state.read_io(CONFIG_ADDRESS) & 1:
            raise UnsupportedInstruction(
                "MOVE.MM big-endian field mapping is classified but not modeled"
            )
        first_word = words[0]
        register_file, source_index, destination_index = (
            self._decode_source_destination(first_word)
        )
        width = self._selected_field_size(first_word)
        source_address = self.state.read_reg(register_file, source_index)
        destination_address = self.state.read_reg(
            register_file, destination_index
        )
        source_pointer_after = source_address
        if address_mode == "postincrement":
            source_pointer_after = (source_address + width) & MASK32
        elif address_mode == "predecrement":
            source_pointer_after = (source_address - width) & MASK32
        same_register = source_index == destination_index
        effective_source_address = (
            source_pointer_after
            if address_mode == "predecrement"
            else source_address
        )
        effective_destination_address = destination_address
        destination_pointer_after = destination_address
        if address_mode == "postincrement":
            effective_destination_address = (
                source_pointer_after if same_register else destination_address
            )
            destination_pointer_after = (
                (source_pointer_after + width) & MASK32
                if same_register
                else (destination_address + width) & MASK32
            )
        elif address_mode == "predecrement":
            effective_destination_address = (
                (source_pointer_after - width) & MASK32
                if same_register
                else (destination_address - width) & MASK32
            )
            destination_pointer_after = effective_destination_address
        elif address_mode == "offset":
            source_offset = words[1]
            destination_offset = words[2]
            if source_offset & 0x8000:
                source_offset -= 0x1_0000
            if destination_offset & 0x8000:
                destination_offset -= 0x1_0000
            effective_source_address = (
                source_address + source_offset
            ) & MASK32
            effective_destination_address = (
                destination_address + destination_offset
            ) & MASK32
        elif address_mode == "source_offset_destination_postincrement":
            source_offset = self._signed_half(words[1])
            effective_source_address = (
                source_address + source_offset
            ) & MASK32
            destination_pointer_after = (
                destination_address + width
            ) & MASK32
        value = self.state.memory.read_bits(effective_source_address, width)
        source_case = self._field_alignment_case(
            effective_source_address, width
        )
        destination_case = self._field_alignment_case(
            effective_destination_address, width
        )
        machine_states = (3 if source_case <= 2 else 4) + (
            2
            if address_mode in (
                "offset",
                "source_offset_destination_postincrement",
            )
            else int(address_mode == "predecrement")
        )
        hidden_states = (0, 1, 2, 2, 3, 4)[destination_case]
        self.state.memory.write_bits(
            effective_destination_address, width, value
        )
        if address_mode in ("postincrement", "predecrement"):
            self.state.write_reg(
                register_file, source_index, source_pointer_after
            )
            self.state.write_reg(
                register_file, destination_index, destination_pointer_after
            )
        elif address_mode == "source_offset_destination_postincrement":
            self.state.write_reg(
                register_file, destination_index, destination_pointer_after
            )
        self._new_hidden_write_states = hidden_states
        assert self._active_trace is not None
        suffix = (
            f"_{address_mode}" if address_mode != "ordinary" else ""
        )
        read_transaction = {
            "class": "data_read",
            "purpose": f"field_move_memory_to_memory_source{suffix}",
            "bit_address": effective_source_address,
            "width": width,
            "value": value,
            "alignment_case": source_case,
        }
        write_transaction = {
            "class": "data_write",
            "purpose": f"field_move_memory_to_memory_destination{suffix}",
            "bit_address": effective_destination_address,
            "width": width,
            "value": value,
            "alignment_case": destination_case,
            "hidden_write_states": hidden_states,
        }
        if address_mode in ("postincrement", "predecrement"):
            read_transaction.update(
                {
                    "pointer_before": source_address,
                    "pointer_after": source_pointer_after,
                }
            )
            write_transaction.update(
                {
                    "pointer_before": destination_address,
                    "pointer_after": destination_pointer_after,
                }
            )
            write_transaction[
                "same_register_uses_incremented_destination"
                if address_mode == "postincrement"
                else "same_register_uses_decremented_destination"
            ] = int(same_register)
        elif address_mode == "offset":
            read_transaction.update(
                {
                    "base_address": source_address,
                    "signed_offset": source_offset,
                }
            )
            write_transaction.update(
                {
                    "base_address": destination_address,
                    "signed_offset": destination_offset,
                }
            )
        elif address_mode == "source_offset_destination_postincrement":
            read_transaction.update(
                {
                    "base_address": source_address,
                    "signed_offset": source_offset,
                }
            )
            write_transaction.update(
                {
                    "pointer_before": destination_address,
                    "pointer_after": destination_pointer_after,
                    "same_register_final_destination_update": int(
                        same_register
                    ),
                }
            )
        self._active_trace.transactions.extend(
            [read_transaction, write_transaction]
        )
        self._active_trace.notes.append(
            "logical little-endian read-before-write field copy"
            + (
                " with source/destination postincrement; Rs=Rd uses the "
                "once-incremented destination address and twice-incremented "
                "final shared pointer selected under RSC-0037/OQ-0025"
                if address_mode == "postincrement"
                else (
                    " with source then destination predecrement; Rs=Rd reads "
                    "at original minus one field and writes/finishes at "
                    "original minus two fields"
                    if address_mode == "predecrement"
                    else (
                        " with independent signed 16-bit source/destination "
                        "offsets and unmodified base registers"
                        if address_mode == "offset"
                        else (
                            " with a signed source offset and destination "
                            "postincrement after the write"
                            if address_mode
                            == "source_offset_destination_postincrement"
                            else ""
                        )
                    )
                )
            )
            + "; physical "
            "byte-strobe/RMW, dynamic-width, wait, page, fault, retry, "
            "interrupt, and I/O sequencing remain pending"
        )
        return machine_states

    @staticmethod
    def _absolute_bit_address(words: list[int], low_word_index: int) -> int:
        return words[low_word_index] | (words[low_word_index + 1] << 16)

    def _first_extension_long_word_aligned(self) -> bool:
        assert self._active_trace is not None
        return ((self._active_trace.start_pc + 16) & 0x1F) == 0

    def _execute_move_register_to_memory_absolute(
        self, instruction: Instruction, words: list[int]
    ) -> int:
        del instruction
        if self.state.read_io(CONFIG_ADDRESS) & 1:
            raise UnsupportedInstruction(
                "MOVE.RM.ABS big-endian field mapping is classified but not modeled"
            )
        first_word = words[0]
        register_file = "B" if first_word & 0x10 else "A"
        source_index = first_word & 0xF
        width = self._selected_field_size(first_word)
        destination_address = self._absolute_bit_address(words, 1)
        source = self.state.read_reg(register_file, source_index)
        field_mask = MASK32 if width == 32 else (1 << width) - 1
        value = source & field_mask
        destination_case = self._field_alignment_case(
            destination_address, width
        )
        hidden_states = (0, 1, 2, 2, 3, 4)[destination_case]
        immediate_aligned = self._first_extension_long_word_aligned()
        self.state.memory.write_bits(destination_address, width, value)
        self._new_hidden_write_states = hidden_states
        assert self._active_trace is not None
        self._active_trace.transactions.append(
            {
                "class": "data_write",
                "purpose": "field_move_register_to_absolute",
                "bit_address": destination_address,
                "width": width,
                "value": value,
                "alignment_case": destination_case,
                "hidden_write_states": hidden_states,
                "first_extension_long_word_aligned": int(
                    immediate_aligned
                ),
            }
        )
        self._active_trace.notes.append(
            "logical little-endian absolute field insertion; physical "
            "byte strobes, read/modify/write, dynamic width, wait, page, "
            "fault, retry, and I/O sequencing remain pending"
        )
        return 2 if immediate_aligned else 3

    def _execute_movb_register_to_memory(
        self, instruction: Instruction, words: list[int]
    ) -> int:
        if self.state.read_io(CONFIG_ADDRESS) & 1:
            raise UnsupportedInstruction(
                f"{instruction.mnemonic} big-endian byte mapping is "
                "classified but not modeled"
            )
        first_word = words[0]
        register_file = "B" if first_word & 0x10 else "A"
        if instruction.mnemonic == "MOVB.RM.ABS":
            source_index = first_word & 0xF
            destination_address = self._absolute_bit_address(words, 1)
            immediate_aligned = self._first_extension_long_word_aligned()
            machine_states = 2 if immediate_aligned else 3
        else:
            source_index = (first_word >> 5) & 0xF
            destination_index = first_word & 0xF
            destination_address = self.state.read_reg(
                register_file, destination_index
            )
            immediate_aligned = None
            if instruction.mnemonic == "MOVB.RM.OFFSET":
                destination_offset = words[1]
                if destination_offset & 0x8000:
                    destination_offset -= 0x1_0000
                destination_address = (
                    destination_address + destination_offset
                ) & MASK32
                machine_states = 3
            else:
                machine_states = 1
        value = self.state.read_reg(register_file, source_index) & 0xFF
        destination_case = self._field_alignment_case(
            destination_address, 8
        )
        hidden_states = (0, 1, 2, 0, 0, 4)[destination_case]
        self.state.memory.write_bits(destination_address, 8, value)
        self._new_hidden_write_states = hidden_states
        assert self._active_trace is not None
        transaction = {
            "class": "data_write",
            "purpose": "byte_move_register_to_memory",
            "bit_address": destination_address,
            "width": 8,
            "value": value,
            "alignment_case": destination_case,
            "hidden_write_states": hidden_states,
            "addressing_mode": instruction.mnemonic,
        }
        if immediate_aligned is not None:
            transaction["first_extension_long_word_aligned"] = int(
                immediate_aligned
            )
        self._active_trace.transactions.append(transaction)
        self._active_trace.notes.append(
            "logical little-endian fixed-byte insertion; physical byte "
            "strobes, read/modify/write, dynamic width, wait, page, fault, "
            "retry, interrupt, and I/O sequencing remain pending"
        )
        return machine_states

    def _execute_move_memory_to_register_absolute(
        self, instruction: Instruction, words: list[int]
    ) -> int:
        del instruction
        if self.state.read_io(CONFIG_ADDRESS) & 1:
            raise UnsupportedInstruction(
                "MOVE.MR.ABS big-endian field mapping is classified but not modeled"
            )
        first_word = words[0]
        register_file = "B" if first_word & 0x10 else "A"
        destination_index = first_word & 0xF
        field_bank = (first_word >> 9) & 1
        width = self._selected_field_size(first_word)
        sign_extend = bool(
            self.state.st & (1 << (field_bank * 6 + 5))
        )
        source_address = self._absolute_bit_address(words, 1)
        raw_value = self.state.memory.read_bits(source_address, width)
        result = raw_value
        if (
            sign_extend
            and width < 32
            and raw_value & (1 << (width - 1))
        ):
            result |= MASK32 ^ ((1 << width) - 1)
        result &= MASK32
        source_case = self._field_alignment_case(source_address, width)
        immediate_aligned = self._first_extension_long_word_aligned()
        machine_states = (4 if source_case <= 2 else 5) + int(
            not immediate_aligned
        ) + int(sign_extend)
        self.state.write_reg(register_file, destination_index, result)
        self._set_status_bit(N_BIT, bool(result & 0x8000_0000))
        self._set_status_bit(Z_BIT, result == 0)
        self._set_status_bit(V_BIT, False)
        assert self._active_trace is not None
        self._active_trace.transactions.append(
            {
                "class": "data_read",
                "purpose": "field_move_absolute_to_register",
                "bit_address": source_address,
                "width": width,
                "value": raw_value,
                "extended_result": result,
                "alignment_case": source_case,
                "sign_extend": int(sign_extend),
                "first_extension_long_word_aligned": int(
                    immediate_aligned
                ),
            }
        )
        self._active_trace.notes.append(
            "logical little-endian absolute field extraction; physical "
            "dynamic-width, wait, page, fault, retry, interrupt, and I/O "
            "sequencing remain pending"
        )
        return machine_states

    def _execute_movb_memory_to_register(
        self, instruction: Instruction, words: list[int]
    ) -> int:
        if self.state.read_io(CONFIG_ADDRESS) & 1:
            raise UnsupportedInstruction(
                f"{instruction.mnemonic} big-endian byte mapping is "
                "classified but not modeled"
            )
        first_word = words[0]
        register_file = "B" if first_word & 0x10 else "A"
        destination_index = first_word & 0xF
        if instruction.mnemonic == "MOVB.MR.ABS":
            source_address = self._absolute_bit_address(words, 1)
            immediate_aligned = self._first_extension_long_word_aligned()
        else:
            source_index = (first_word >> 5) & 0xF
            source_address = self.state.read_reg(register_file, source_index)
            immediate_aligned = None
            if instruction.mnemonic == "MOVB.MR.OFFSET":
                source_offset = words[1]
                if source_offset & 0x8000:
                    source_offset -= 0x1_0000
                source_address = (source_address + source_offset) & MASK32
        raw_value = self.state.memory.read_bits(source_address, 8)
        result = raw_value
        if raw_value & 0x80:
            result |= 0xFFFF_FF00
        source_case = self._field_alignment_case(source_address, 8)
        if instruction.mnemonic == "MOVB.MR":
            machine_states = 4 if source_case <= 2 else 5
        elif instruction.mnemonic == "MOVB.MR.OFFSET":
            machine_states = 6 if source_case <= 2 else 7
        else:
            machine_states = (5 if source_case <= 2 else 6) + int(
                not immediate_aligned
            )
        self.state.write_reg(register_file, destination_index, result)
        self._set_status_bit(N_BIT, bool(result & 0x8000_0000))
        self._set_status_bit(Z_BIT, result == 0)
        self._set_status_bit(V_BIT, False)
        assert self._active_trace is not None
        transaction = {
            "class": "data_read",
            "purpose": "byte_move_memory_to_register",
            "bit_address": source_address,
            "width": 8,
            "value": raw_value,
            "alignment_case": source_case,
            "addressing_mode": instruction.mnemonic,
            "sign_extended_result": result,
        }
        if immediate_aligned is not None:
            transaction["first_extension_long_word_aligned"] = int(
                immediate_aligned
            )
        self._active_trace.transactions.append(transaction)
        self._active_trace.notes.append(
            "logical little-endian fixed-byte extraction; physical dynamic "
            "width, wait, page, fault, retry, interrupt, and I/O sequencing "
            "remain pending"
        )
        return machine_states

    def _execute_movb_memory_to_memory(
        self, instruction: Instruction, words: list[int]
    ) -> int:
        if self.state.read_io(CONFIG_ADDRESS) & 1:
            raise UnsupportedInstruction(
                f"{instruction.mnemonic} big-endian byte mapping is "
                "classified but not modeled"
            )
        first_word = words[0]
        immediate_aligned: bool | None = None
        source_base: int | None = None
        destination_base: int | None = None
        source_offset: int | None = None
        destination_offset: int | None = None
        if instruction.mnemonic == "MOVB.MM.ABS":
            source_address = self._absolute_bit_address(words, 1)
            destination_address = self._absolute_bit_address(words, 3)
            immediate_aligned = self._first_extension_long_word_aligned()
        else:
            register_file, source_index, destination_index = (
                self._decode_source_destination(first_word)
            )
            source_base = self.state.read_reg(register_file, source_index)
            destination_base = self.state.read_reg(
                register_file, destination_index
            )
            source_address = source_base
            destination_address = destination_base
            if instruction.mnemonic == "MOVB.MM.OFFSET":
                source_offset = self._signed_half(words[1])
                destination_offset = self._signed_half(words[2])
                source_address = (source_base + source_offset) & MASK32
                destination_address = (
                    destination_base + destination_offset
                ) & MASK32
        value = self.state.memory.read_bits(source_address, 8)
        source_case = self._field_alignment_case(source_address, 8)
        destination_case = self._field_alignment_case(destination_address, 8)
        source_crosses = source_case == 5
        if destination_case == 1:
            timing_column = "B" if source_crosses else "A"
        elif destination_case == 2:
            timing_column = "D" if source_crosses else "C"
        else:
            timing_column = "F" if source_crosses else "E"
        if instruction.mnemonic == "MOVB.MM":
            machine_states = 3 + int(source_crosses)
        elif instruction.mnemonic == "MOVB.MM.OFFSET":
            machine_states = 5 + int(source_crosses)
        else:
            machine_states = (
                5 + 2 * int(not immediate_aligned) + int(source_crosses)
            )
        hidden_states = {1: 1, 2: 2, 5: 4}[destination_case]
        offset_case_e_override = (
            instruction.mnemonic == "MOVB.MM.OFFSET"
            and timing_column == "E"
        )
        if offset_case_e_override:
            hidden_states = 2
        self.state.memory.write_bits(destination_address, 8, value)
        self._new_hidden_write_states = hidden_states
        assert self._active_trace is not None
        read_transaction = {
            "class": "data_read",
            "purpose": "byte_move_memory_to_memory_source",
            "bit_address": source_address,
            "width": 8,
            "value": value,
            "alignment_case": source_case,
            "addressing_mode": instruction.mnemonic,
            "timing_column": timing_column,
        }
        write_transaction = {
            "class": "data_write",
            "purpose": "byte_move_memory_to_memory_destination",
            "bit_address": destination_address,
            "width": 8,
            "value": value,
            "alignment_case": destination_case,
            "addressing_mode": instruction.mnemonic,
            "timing_column": timing_column,
            "hidden_write_states": hidden_states,
            "offset_case_e_override": int(offset_case_e_override),
        }
        if source_base is not None:
            read_transaction["base_address"] = source_base
            write_transaction["base_address"] = destination_base
        if source_offset is not None:
            read_transaction["signed_offset"] = source_offset
            write_transaction["signed_offset"] = destination_offset
        if immediate_aligned is not None:
            read_transaction["first_extension_long_word_aligned"] = int(
                immediate_aligned
            )
            write_transaction["first_extension_long_word_aligned"] = int(
                immediate_aligned
            )
        self._active_trace.transactions.extend(
            [read_transaction, write_transaction]
        )
        self._active_trace.notes.append(
            "logical little-endian fixed-byte read-before-write copy; the "
            "offset column-E 5(2) timing cell is preserved provisionally "
            "under RSC-0039/OQ-0026; physical byte strobes, RMW, dynamic "
            "width, wait, page, fault, retry, interrupt, and I/O sequencing "
            "remain pending"
        )
        return machine_states

    def _execute_cexec(
        self, instruction: Instruction, words: list[int]
    ) -> int:
        if instruction.mnemonic == "CEXEC.L":
            if words[1] & 0x007F:
                raise UnsupportedInstruction(
                    "CEXEC.L reserved extension bits 6:0 must be zero"
                )
            size = (words[1] >> 7) & 1
            command = ((words[2] & 0x1FFF) << 8) | (words[1] >> 8)
            coprocessor_id = (words[2] >> 13) & 7
            immediate_aligned = self._first_extension_long_word_aligned()
            machine_states = 2 if immediate_aligned else 3
        else:
            size = words[0] & 1
            command = (
                ((words[1] & 0x1FFF) << 8) |
                ((words[0] >> 1) & 0x3F)
            )
            coprocessor_id = (words[1] >> 13) & 7
            immediate_aligned = None
            machine_states = 2
        command_word = (
            (coprocessor_id << 29) |
            (command << 8) |
            (size << 7)
        ) & MASK32
        self._new_hidden_write_states = 1
        assert self._active_trace is not None
        transaction: dict[str, int | str] = {
            "class": "coprocessor_command",
            "purpose": "internal_operation_no_data_transfer",
            "coprocessor_id": coprocessor_id,
            "command": command,
            "size_64": size,
            "parameter_index": 0,
            "bus_status": 0,
            "special_function": 1,
            "word_select_16": 0,
            "lad_command": command_word,
            "addressing_mode": instruction.mnemonic,
        }
        if immediate_aligned is not None:
            transaction["first_extension_long_word_aligned"] = int(
                immediate_aligned
            )
        self._active_trace.transactions.append(transaction)
        self._active_trace.notes.append(
            "logical successful 32-bit CEXEC command cycle with no data "
            "transfer; external coprocessor acceptance, LRDY/BUSFLT, retry, "
            "fault continuation, page interruption, pin phases and interrupt "
            "recognition remain pending"
        )
        return machine_states

    def _execute_cmovgc(
        self, instruction: Instruction, words: list[int]
    ) -> int:
        first_word = words[0]
        extension = words[1]
        two_registers = instruction.mnemonic == "CMOVGC.2"
        if two_registers:
            if extension & 0x0060:
                raise UnsupportedInstruction(
                    "CMOVGC.2 reserved extension bits 6:5 must be zero"
                )
            size = (extension >> 7) & 1
            source2_file = "B" if extension & 0x10 else "A"
            source2_index = extension & 0xF
        else:
            if extension & 0x00FF:
                raise UnsupportedInstruction(
                    "CMOVGC.1 reserved extension bits 7:0 must be zero"
                )
            size = 0
            source2_file = "A"
            source2_index = 0
        source1_file = "B" if first_word & 0x10 else "A"
        source1_index = first_word & 0xF
        source_values = [
            self.state.read_reg(source1_file, source1_index)
        ]
        source_locations = [(source1_file, source1_index)]
        if two_registers:
            source_values.append(
                self.state.read_reg(source2_file, source2_index)
            )
            source_locations.append((source2_file, source2_index))
        command = ((words[2] & 0x1FFF) << 8) | (extension >> 8)
        coprocessor_id = (words[2] >> 13) & 7
        command_word = (
            (coprocessor_id << 29) |
            (command << 8) |
            (size << 7)
        ) & MASK32
        immediate_aligned = self._first_extension_long_word_aligned()
        machine_states = (
            (3 if immediate_aligned else 4)
            if two_registers
            else (2 if immediate_aligned else 3)
        )
        self._new_hidden_write_states = 1
        assert self._active_trace is not None
        self._active_trace.transactions.append(
            {
                "class": "coprocessor_command",
                "purpose": "register_to_coprocessor_transfer",
                "coprocessor_id": coprocessor_id,
                "command": command,
                "size_64": size,
                "parameter_index": 0,
                "bus_status": 0,
                "special_function": 1,
                "word_select_16": 0,
                "lad_command": command_word,
                "addressing_mode": instruction.mnemonic,
                "first_extension_long_word_aligned": int(immediate_aligned),
            }
        )
        for parameter_index, (value, location) in enumerate(
            zip(source_values, source_locations, strict=True)
        ):
            self._active_trace.transactions.append(
                {
                    "class": "coprocessor_data_out",
                    "purpose": "register_parameter",
                    "parameter_index": parameter_index,
                    "value": value,
                    "source_file": location[0],
                    "source_index": location[1],
                    "width": 32,
                    "addressing_mode": instruction.mnemonic,
                }
            )
        self._active_trace.notes.append(
            "logical successful command followed by ordered captured 32-bit "
            "register parameter transfer(s); a physical two-word non-page "
            "sequence must reissue the command with I=1 before parameter 1; "
            "external acceptance, page interruption, LRDY/BUSFLT, retry, "
            "fault continuation, pin phases and interrupt recognition remain "
            "pending"
        )
        return machine_states

    def _execute_cmovcg(
        self, instruction: Instruction, words: list[int]
    ) -> int:
        del instruction
        first_word = words[0]
        extension = words[1]
        status_only = first_word == 0x0660 and (extension & 0xFF) == 1
        size = 0 if status_only else ((extension >> 7) & 1)
        if not status_only:
            if extension & 0x0060:
                raise UnsupportedInstruction(
                    "CMOVCG reserved extension bits 6:5 must be zero"
                )
            if not size and extension & 0x001F:
                raise UnsupportedInstruction(
                    "CMOVCG size-zero second destination bits must be zero"
                )
        data_count = 2 if size else 1
        if len(self.coprocessor_read_data) < data_count:
            raise ModelError(
                "coprocessor inbound data underflow for CMOVCG/CMOVCS"
            )
        data_words = self.coprocessor_read_data[:data_count]
        del self.coprocessor_read_data[:data_count]
        command = ((words[2] & 0x1FFF) << 8) | (extension >> 8)
        coprocessor_id = (words[2] >> 13) & 7
        command_word = (
            (coprocessor_id << 29) |
            (command << 8) |
            (size << 7)
        ) & MASK32
        immediate_aligned = self._first_extension_long_word_aligned()
        machine_states = (
            (5 if immediate_aligned else 6)
            if size
            else (4 if immediate_aligned else 5)
        )
        assert self._active_trace is not None
        if status_only:
            self._active_trace.mnemonic = "CMOVCS"
        self._active_trace.transactions.append(
            {
                "class": "coprocessor_command",
                "purpose": (
                    "coprocessor_to_status"
                    if status_only
                    else "coprocessor_to_register"
                ),
                "coprocessor_id": coprocessor_id,
                "command": command,
                "size_64": size,
                "parameter_index": 0,
                "bus_status": 0,
                "special_function": 1,
                "word_select_16": 0,
                "lad_command": command_word,
                "lad_second_reissue": command_word | 0x40,
                "addressing_mode": (
                    "CMOVCS" if status_only else "CMOVCG"
                ),
                "first_extension_long_word_aligned": int(immediate_aligned),
            }
        )
        for parameter_index, value in enumerate(data_words):
            self._active_trace.transactions.append(
                {
                    "class": "coprocessor_data_in",
                    "purpose": (
                        "status_nczv"
                        if status_only
                        else "register_parameter"
                    ),
                    "parameter_index": parameter_index,
                    "value": value,
                    "width": 32,
                    "addressing_mode": (
                        "CMOVCS" if status_only else "CMOVCG"
                    ),
                }
            )
        if status_only:
            self.state.st = (
                (self.state.st & 0x0FFF_FFFF) |
                (data_words[0] & 0xF000_0000)
            ) & MASK32
        else:
            destination1_file = "B" if first_word & 0x10 else "A"
            destination1_index = first_word & 0xF
            self.state.write_reg(
                destination1_file, destination1_index, data_words[0]
            )
            if size:
                destination2_file = "B" if extension & 0x10 else "A"
                destination2_index = extension & 0xF
                self.state.write_reg(
                    destination2_file, destination2_index, data_words[1]
                )
            last_value = data_words[-1]
            self._set_status_bit(N_BIT, bool(last_value & 0x8000_0000))
            self._set_status_bit(Z_BIT, last_value == 0)
            self._set_status_bit(V_BIT, False)
        self._active_trace.notes.append(
            "logical successful inbound coprocessor transfer from a "
            "deterministic queued response; a physical two-word non-page "
            "sequence must reissue the command with I=1 before parameter 1; "
            "external drive timing, page interruption, LRDY/BUSFLT, retry, "
            "fault continuation and interrupt recognition remain pending"
        )
        return machine_states

    def _execute_coprocessor_memory_transfer(
        self, instruction: Instruction, words: list[int]
    ) -> int:
        if self.state.read_io(CONFIG_ADDRESS) & 1:
            raise UnsupportedInstruction(
                f"{instruction.mnemonic} big-endian memory mapping is "
                "classified but not modeled"
            )
        first_word = words[0]
        extension = words[1]
        if extension & 0x0060:
            raise UnsupportedInstruction(
                f"{instruction.mnemonic} reserved extension bits 6:5 "
                "must be zero"
            )
        size = (extension >> 7) & 1
        to_memory = instruction.mnemonic.startswith("CMOVCM")
        predecrement = ".PRE." in instruction.mnemonic
        register_count = instruction.mnemonic == "CMOVMC.POST.R"
        if to_memory:
            pointer_selector = first_word & 0x1F
            encoded_count = extension & 0x1F
        else:
            pointer_selector = extension & 0x1F
            if register_count:
                count_file = "B" if first_word & 0x10 else "A"
                count_index = first_word & 0xF
                encoded_count = self.state.read_reg(
                    count_file, count_index
                ) & 0x1F
            else:
                encoded_count = first_word & 0x1F
        if not register_count and size and (encoded_count & 1):
            raise UnsupportedInstruction(
                f"{instruction.mnemonic} size-one constant transfer "
                "encoding must be even"
            )
        transfer_count = encoded_count if encoded_count else 32
        if to_memory and len(self.coprocessor_read_data) < transfer_count:
            raise ModelError(
                "coprocessor inbound data underflow for CMOVCM"
            )
        pointer_file = "B" if pointer_selector & 0x10 else "A"
        pointer_index = pointer_selector & 0xF
        pointer_before = self.state.read_reg(pointer_file, pointer_index)
        command = ((words[2] & 0x1FFF) << 8) | (extension >> 8)
        coprocessor_id = (words[2] >> 13) & 7
        command_word = (
            (coprocessor_id << 29) |
            (command << 8) |
            (size << 7)
        ) & MASK32
        immediate_aligned = self._first_extension_long_word_aligned()
        machine_states = transfer_count + (
            4 if immediate_aligned else 5
        )
        inbound_values: list[int] = []
        if to_memory:
            inbound_values = self.coprocessor_read_data[:transfer_count]
            del self.coprocessor_read_data[:transfer_count]
        assert self._active_trace is not None
        self._active_trace.transactions.append(
            {
                "class": "coprocessor_command",
                "purpose": (
                    "coprocessor_to_memory"
                    if to_memory else "memory_to_coprocessor"
                ),
                "coprocessor_id": coprocessor_id,
                "command": command,
                "size_64": size,
                "parameter_index": 0,
                "bus_status": 0,
                "special_function": 1,
                "word_select_16": 0,
                "lad_command": command_word,
                "transfer_count": transfer_count,
                "addressing_mode": instruction.mnemonic,
                "first_extension_long_word_aligned": int(
                    immediate_aligned
                ),
                "command_reissued_after_page_break": 0,
            }
        )
        pointer = pointer_before
        for transfer_index in range(transfer_count):
            if predecrement:
                pointer = (pointer - 32) & MASK32
            address = pointer
            if to_memory:
                value = inbound_values[transfer_index]
                self._active_trace.transactions.append(
                    {
                        "class": "coprocessor_data_in",
                        "purpose": "memory_parameter",
                        "parameter_index": transfer_index,
                        "value": value,
                        "width": 32,
                        "addressing_mode": instruction.mnemonic,
                    }
                )
                self.state.memory.write_bits(address, 32, value)
                self._active_trace.transactions.append(
                    {
                        "class": "data_write",
                        "purpose": "coprocessor_memory_transfer",
                        "bit_address": address,
                        "width": 32,
                        "value": value,
                        "transfer_index": transfer_index,
                    }
                )
            else:
                value = self.state.memory.read_bits(address, 32)
                self._active_trace.transactions.extend(
                    [
                        {
                            "class": "data_read",
                            "purpose": "coprocessor_memory_transfer",
                            "bit_address": address,
                            "width": 32,
                            "value": value,
                            "transfer_index": transfer_index,
                        },
                        {
                            "class": "coprocessor_data_out",
                            "purpose": "memory_parameter",
                            "parameter_index": transfer_index,
                            "value": value,
                            "width": 32,
                            "addressing_mode": instruction.mnemonic,
                        },
                    ]
                )
            if not predecrement:
                pointer = (pointer + 32) & MASK32
        self.state.write_reg(pointer_file, pointer_index, pointer)
        self._active_trace.notes.append(
            "logical successful 32-bit coprocessor/local-memory sequence; "
            "physical address/status, page continuation, turnaround spacer, "
            "LRDY/BUSFLT, dynamic sizing, retry, fault/interrupt continuation "
            "and partial pointer retirement remain pending; after a physical "
            "page break the next memory address is issued without reissuing "
            "the coprocessor command"
        )
        return machine_states

    def _execute_move_memory_to_memory_absolute_source_postincrement(
        self, instruction: Instruction, words: list[int]
    ) -> int:
        del instruction
        if self.state.read_io(CONFIG_ADDRESS) & 1:
            raise UnsupportedInstruction(
                "MOVE.MM.SABS_POST big-endian field mapping is classified "
                "but not modeled"
            )
        first_word = words[0]
        register_file = "B" if first_word & 0x10 else "A"
        destination_index = first_word & 0xF
        width = self._selected_field_size(first_word)
        source_address = self._absolute_bit_address(words, 1)
        destination_address = self.state.read_reg(
            register_file, destination_index
        )
        destination_after = (destination_address + width) & MASK32
        value = self.state.memory.read_bits(source_address, width)
        source_case = self._field_alignment_case(source_address, width)
        destination_case = self._field_alignment_case(
            destination_address, width
        )
        immediate_aligned = self._first_extension_long_word_aligned()
        machine_states = (4 if source_case <= 2 else 5) + int(
            not immediate_aligned
        )
        hidden_states = (0, 1, 2, 2, 3, 4)[destination_case]
        self.state.memory.write_bits(destination_address, width, value)
        self.state.write_reg(
            register_file, destination_index, destination_after
        )
        self._new_hidden_write_states = hidden_states
        assert self._active_trace is not None
        self._active_trace.transactions.extend(
            [
                {
                    "class": "data_read",
                    "purpose": "field_move_absolute_source",
                    "bit_address": source_address,
                    "width": width,
                    "value": value,
                    "alignment_case": source_case,
                    "first_extension_long_word_aligned": int(
                        immediate_aligned
                    ),
                },
                {
                    "class": "data_write",
                    "purpose": "field_move_destination_postincrement",
                    "bit_address": destination_address,
                    "width": width,
                    "value": value,
                    "alignment_case": destination_case,
                    "hidden_write_states": hidden_states,
                    "pointer_before": destination_address,
                    "pointer_after": destination_after,
                },
            ]
        )
        self._active_trace.notes.append(
            "logical little-endian absolute-source read-before-write copy "
            "with destination postincrement; physical byte-strobe/RMW, "
            "dynamic-width, wait, page, fault, retry, interrupt, and I/O "
            "sequencing remain pending"
        )
        return machine_states

    def _execute_move_memory_to_memory_absolute(
        self, instruction: Instruction, words: list[int]
    ) -> int:
        del instruction
        if self.state.read_io(CONFIG_ADDRESS) & 1:
            raise UnsupportedInstruction(
                "MOVE.MM.ABS big-endian field mapping is classified but not modeled"
            )
        first_word = words[0]
        width = self._selected_field_size(first_word)
        source_address = self._absolute_bit_address(words, 1)
        destination_address = self._absolute_bit_address(words, 3)
        value = self.state.memory.read_bits(source_address, width)
        source_case = self._field_alignment_case(source_address, width)
        destination_case = self._field_alignment_case(
            destination_address, width
        )
        immediate_aligned = self._first_extension_long_word_aligned()
        machine_states = (5 if source_case <= 2 else 6) + (
            0 if immediate_aligned else 2
        )
        hidden_states = (0, 1, 2, 2, 3, 4)[destination_case]
        self.state.memory.write_bits(destination_address, width, value)
        self._new_hidden_write_states = hidden_states
        assert self._active_trace is not None
        self._active_trace.transactions.extend(
            [
                {
                    "class": "data_read",
                    "purpose": "field_move_absolute_source",
                    "bit_address": source_address,
                    "width": width,
                    "value": value,
                    "alignment_case": source_case,
                    "first_extension_long_word_aligned": int(
                        immediate_aligned
                    ),
                },
                {
                    "class": "data_write",
                    "purpose": "field_move_absolute_destination",
                    "bit_address": destination_address,
                    "width": width,
                    "value": value,
                    "alignment_case": destination_case,
                    "hidden_write_states": hidden_states,
                },
            ]
        )
        self._active_trace.notes.append(
            "logical little-endian absolute read-before-write field copy; "
            "physical byte-strobe/RMW, dynamic-width, wait, page, fault, "
            "retry, interrupt, and I/O sequencing remain pending"
        )
        return machine_states

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

    def _execute_cmpxy(
        self, instruction: Instruction, words: list[int]
    ) -> int:
        del instruction
        register_file, source_index, destination_index = (
            self._decode_source_destination(words[0])
        )
        source = self.state.read_reg(register_file, source_index)
        destination = self.state.read_reg(register_file, destination_index)
        source_x = source & 0xFFFF
        source_y = (source >> 16) & 0xFFFF
        destination_x = destination & 0xFFFF
        destination_y = (destination >> 16) & 0xFFFF
        result_x = (destination_x - source_x) & 0xFFFF
        result_y = (destination_y - source_y) & 0xFFFF

        self._set_status_bit(N_BIT, source_x == destination_x)
        self._set_status_bit(C_BIT, bool(result_y & 0x8000))
        self._set_status_bit(Z_BIT, source_y == destination_y)
        self._set_status_bit(V_BIT, bool(result_x & 0x8000))
        return 1

    @staticmethod
    def _signed_half(value: int) -> int:
        value &= 0xFFFF
        return value - 0x1_0000 if value & 0x8000 else value

    def _xy_window_outcode(
        self, point: int, window_start: int, window_end: int
    ) -> int:
        point_x = self._signed_half(point)
        point_y = self._signed_half(point >> 16)
        start_x = self._signed_half(window_start)
        start_y = self._signed_half(window_start >> 16)
        end_x = self._signed_half(window_end)
        end_y = self._signed_half(window_end >> 16)
        result = 0
        if start_x > point_x:
            result |= 1 << 5
        if point_x > end_x:
            result |= 1 << 6
        if start_y > point_y:
            result |= 1 << 7
        if point_y > end_y:
            result |= 1 << 8
        return result

    def _execute_cpw(
        self, instruction: Instruction, words: list[int]
    ) -> int:
        del instruction
        register_file, source_index, destination_index = (
            self._decode_source_destination(words[0])
        )
        # All operands are captured before Rd is written; Rd may be B5/B6.
        point = self.state.read_reg(register_file, source_index)
        window_start = self.state.read_reg("B", 5)
        window_end = self.state.read_reg("B", 6)
        result = self._xy_window_outcode(point, window_start, window_end)
        self.state.write_reg(register_file, destination_index, result)
        self._set_status_bit(V_BIT, result != 0)
        return 1

    def _execute_linit(
        self, instruction: Instruction, words: list[int]
    ) -> int:
        del instruction, words
        # Capture all implied inputs before B7 changes from endpoint to b:a.
        start = self.state.read_reg("B", 2)
        endpoint = self.state.read_reg("B", 7)
        window_start = self.state.read_reg("B", 5)
        window_end = self.state.read_reg("B", 6)
        start_x = self._signed_half(start)
        start_y = self._signed_half(start >> 16)
        end_x = self._signed_half(endpoint)
        end_y = self._signed_half(endpoint >> 16)
        delta_x = end_x - start_x
        delta_y = end_y - start_y
        extent_x = abs(delta_x)
        extent_y = abs(delta_y)
        major = max(extent_x, extent_y)
        minor = min(extent_x, extent_y)
        step_x = -1 if delta_x < 0 else (1 if delta_x > 0 else 0)
        step_y = -1 if delta_y < 0 else (1 if delta_y > 0 else 0)
        diagonal_increment = (
            ((step_y & 0xFFFF) << 16) | (step_x & 0xFFFF)
        )
        if extent_x >= extent_y:
            major_increment = step_x & 0xFFFF
        else:
            major_increment = (step_y & 0xFFFF) << 16
        start_outcode = self._xy_window_outcode(
            start, window_start, window_end
        )
        end_outcode = self._xy_window_outcode(
            endpoint, window_start, window_end
        )
        self.state.write_reg("B", 0, 2 * minor - major)
        self.state.write_reg("B", 7, (minor << 16) | major)
        self.state.write_reg("B", 10, major + 1)
        self.state.write_reg("B", 11, diagonal_increment)
        self.state.write_reg("B", 12, major_increment)
        self._set_status_bit(N_BIT, start_x == end_x)
        self._set_status_bit(C_BIT, bool(start_outcode & end_outcode))
        self._set_status_bit(Z_BIT, start_y == end_y)
        self._set_status_bit(V_BIT, bool(start_outcode | end_outcode))
        assert self._active_trace is not None
        self._active_trace.notes.append(
            "LINIT captured B2/B7 endpoints and B5/B6 signed inclusive "
            "window bounds before atomically replacing B0/B7/B10/B11/B12 "
            "and NCZV; it performs no pixel or data-memory transaction"
        )
        return 9

    def _execute_clip(
        self, instruction: Instruction, words: list[int]
    ) -> None:
        del instruction, words
        origin = self.state.read_reg("B", 2)
        window_start = self.state.read_reg("B", 5)
        window_end = self.state.read_reg("B", 6)
        dimensions = self.state.read_reg("B", 7)
        origin_x = self._signed_half(origin)
        origin_y = self._signed_half(origin >> 16)
        window_start_x = self._signed_half(window_start)
        window_start_y = self._signed_half(window_start >> 16)
        window_end_x = self._signed_half(window_end)
        window_end_y = self._signed_half(window_end >> 16)
        width = dimensions & 0xFFFF
        height = (dimensions >> 16) & 0xFFFF
        if width == 0 or height == 0:
            raise ModelError(
                "CLIP zero-dimension Z/V behavior is not documented"
            )
        if (
            window_start_x > window_end_x
            or window_start_y > window_end_y
        ):
            raise ModelError("CLIP requires ordered inclusive window bounds")

        # Do not wrap an overflowing array endpoint back into signed XY space.
        array_end_x = origin_x + width - 1
        array_end_y = origin_y + height - 1
        clipped_start_x = max(origin_x, window_start_x)
        clipped_start_y = max(origin_y, window_start_y)
        clipped_end_x = min(array_end_x, window_end_x)
        clipped_end_y = min(array_end_y, window_end_y)
        no_intersection = (
            clipped_start_x > clipped_end_x
            or clipped_start_y > clipped_end_y
        )
        any_outside = (
            origin_x < window_start_x
            or origin_y < window_start_y
            or array_end_x > window_end_x
            or array_end_y > window_end_y
        )
        if not no_intersection:
            adjusted_origin = (
                ((clipped_start_y & 0xFFFF) << 16)
                | (clipped_start_x & 0xFFFF)
            )
            adjusted_dimensions = (
                ((clipped_end_y - clipped_start_y + 1) << 16)
                | (clipped_end_x - clipped_start_x + 1)
            )
            self.state.write_reg("B", 2, adjusted_origin)
            self.state.write_reg("B", 7, adjusted_dimensions)
        self._set_status_bit(Z_BIT, no_intersection)
        self._set_status_bit(V_BIT, any_outside)
        assert self._active_trace is not None
        self._active_trace.notes.append(
            "CLIP computed the positive-dimension common rectangle in "
            "extended signed-coordinate space; no pixel or data-memory "
            "transaction occurs and complex internal timing is not modeled"
        )
        return None

    def _execute_find_pixel(
        self, instruction: Instruction, words: list[int]
    ) -> None:
        del words
        config = self.state.read_io(CONFIG_ADDRESS)
        if config & 1:
            raise UnsupportedInstruction(
                f"{instruction.mnemonic} big-endian pixel mapping is "
                "classified but not modeled"
            )
        if self.state.read_io(DPYCTL_ADDRESS) & (1 << 11):
            raise UnsupportedInstruction(
                f"{instruction.mnemonic} CST-converted VRAM transfer is "
                "classified but not modeled"
            )
        pixel_size = self._read_legal_psize()
        pixel_mask = MASK32 if pixel_size == 32 else (1 << pixel_size) - 1
        plane_mask = (
            self.state.read_io(PMASKL_ADDRESS)
            | (self.state.read_io(PMASKH_ADDRESS) << 16)
        )
        color0 = self.state.read_reg("B", 8)
        maddr = self.state.read_reg("B", 10)
        raw_count = self.state.read_reg("B", 11)
        count = self._signed_word(raw_count)
        found = False
        assert self._active_trace is not None

        while count != 0:
            if count > 0:
                effective_address = maddr
                maddr = (maddr + pixel_size) & MASK32
                count -= 1
                direction = "postincrement"
            else:
                maddr = (maddr - pixel_size) & MASK32
                effective_address = maddr
                count += 1
                direction = "predecrement"

            lane = effective_address & 0x1F
            if effective_address & (pixel_size - 1):
                raise ModelError(
                    f"{instruction.mnemonic} requires a pixel-aligned MADDR"
                )
            if lane + pixel_size > 32:
                raise ModelError(
                    f"{instruction.mnemonic} pixel crosses a long-word boundary"
                )
            raw_pixel = self.state.memory.read_bits(
                effective_address, pixel_size
            )
            pixel_plane_mask = (plane_mask >> lane) & pixel_mask
            masked_pixel = raw_pixel & (~pixel_plane_mask & pixel_mask)
            comparison_pixel = (color0 >> lane) & pixel_mask
            equal = masked_pixel == comparison_pixel
            found = equal if instruction.mnemonic == "FPIXEQ" else not equal
            self._active_trace.transactions.append(
                {
                    "class": "pixel_read",
                    "purpose": "find_pixel_compare",
                    "bit_address": effective_address,
                    "width": pixel_size,
                    "raw_value": raw_pixel,
                    "plane_mask": pixel_plane_mask,
                    "masked_value": masked_pixel,
                    "comparison_value": comparison_pixel,
                    "direction": direction,
                    "found": int(found),
                }
            )
            if found:
                break

        self.state.write_reg("B", 10, maddr)
        self.state.write_reg("B", 11, count & MASK32)
        self._set_status_bit(Z_BIT, found)
        self._active_trace.notes.append(
            f"successful atomic {instruction.mnemonic} logical pixel scan; "
            "COLOR0 and PMASK lanes follow the pixel's long-word position; "
            "physical read grouping, page mode, wait, fault/retry, and "
            "interrupt continuation remain pending"
        )
        return None

    def _execute_drav(
        self, instruction: Instruction, words: list[int]
    ) -> int:
        del instruction
        config = self.state.read_io(CONFIG_ADDRESS)
        if config & 1:
            raise UnsupportedInstruction(
                "DRAV big-endian pixel mapping is classified but not modeled"
            )
        if self.state.read_io(DPYCTL_ADDRESS) & (1 << 11):
            raise UnsupportedInstruction(
                "DRAV CST-converted VRAM transfer is classified but not modeled"
            )
        control = self.state.read_io(CONTROL_ADDRESS)
        if (control >> 10) & 0x1F:
            raise UnsupportedInstruction(
                "DRAV pixel processing is currently limited to replace"
            )
        if control & (1 << 5):
            raise UnsupportedInstruction(
                "DRAV transparency is classified but not modeled"
            )
        if (control >> 6) & 0x3:
            raise UnsupportedInstruction(
                "DRAV window checking is classified but not modeled"
            )

        first_word = words[0]
        register_file = "B" if first_word & 0x10 else "A"
        source_index = (first_word >> 5) & 0xF
        destination_index = first_word & 0xF
        source_xy = self.state.read_reg(register_file, source_index)
        destination_xy = self.state.read_reg(
            register_file, destination_index
        )
        dptch = self.state.read_reg("B", 3)
        offset = self.state.read_reg("B", 4)
        color1 = self.state.read_reg("B", 9)
        pixel_size = self._read_legal_psize()
        pixel_mask = MASK32 if pixel_size == 32 else (1 << pixel_size) - 1
        plane_mask = (
            self.state.read_io(PMASKL_ADDRESS)
            | (self.state.read_io(PMASKH_ADDRESS) << 16)
        )
        linear_address, pitch_class = self._xy_linear_result(
            destination_xy,
            CONVDP_ADDRESS,
            dptch,
            pixel_size,
            offset,
        )
        if linear_address & (pixel_size - 1):
            raise ModelError("DRAV produces a non-pixel-aligned address")
        lane = linear_address & 0x1F
        if lane + pixel_size > 32:
            raise ModelError("DRAV pixel crosses a long-word boundary")
        raw_destination = self.state.memory.read_bits(
            linear_address, pixel_size
        )
        source_pixel = (color1 >> lane) & pixel_mask
        pixel_plane_mask = (plane_mask >> lane) & pixel_mask
        result_pixel = (
            (raw_destination & pixel_plane_mask)
            | (source_pixel & (~pixel_plane_mask & pixel_mask))
        )
        next_x = (
            (destination_xy & 0xFFFF) + (source_xy & 0xFFFF)
        ) & 0xFFFF
        next_y = (
            ((destination_xy >> 16) & 0xFFFF)
            + ((source_xy >> 16) & 0xFFFF)
        ) & 0xFFFF
        next_destination = (next_y << 16) | next_x

        self.state.memory.write_bits(
            linear_address, pixel_size, result_pixel
        )
        self.state.write_reg(
            register_file, destination_index, next_destination
        )
        assert self._active_trace is not None
        self._active_trace.transactions.append(
            {
                "class": "pixel_write",
                "purpose": "drav_replace",
                "bit_address": linear_address,
                "width": pixel_size,
                "raw_destination": raw_destination,
                "source_value": source_pixel,
                "plane_mask": pixel_plane_mask,
                "value": result_pixel,
                "xy_before": destination_xy,
                "xy_increment": source_xy,
                "xy_after": next_destination,
            }
        )
        self._record_xy_pitch_class(pitch_class)
        conversion = {
            "power_of_two": 0,
            "two_powers_of_two": 1,
            "arbitrary": 12,
        }[pitch_class]
        self._active_trace.notes.append(
            "successful atomic DRAV W0 replace/no-transparency logical write; "
            "physical read/modify/write, waits, page mode, fault/retry, and "
            "hidden-write overlap remain pending"
        )
        return 4 + conversion

    def _execute_fill(
        self, instruction: Instruction, words: list[int]
    ) -> None:
        del words
        config = self.state.read_io(CONFIG_ADDRESS)
        if config & 1:
            raise UnsupportedInstruction(
                f"{instruction.mnemonic} big-endian pixel mapping is "
                "classified but not modeled"
            )
        if self.state.read_io(DPYCTL_ADDRESS) & (1 << 11):
            raise UnsupportedInstruction(
                f"{instruction.mnemonic} CST-converted VRAM transfers are "
                "classified but not modeled"
            )
        control = self.state.read_io(CONTROL_ADDRESS)
        if (control >> 10) & 0x1F:
            raise UnsupportedInstruction(
                f"{instruction.mnemonic} pixel processing is currently "
                "limited to replace"
            )
        if control & (1 << 5):
            raise UnsupportedInstruction(
                f"{instruction.mnemonic} transparency is classified but "
                "not modeled"
            )
        xy_destination = instruction.mnemonic == "FILL.XY"
        if xy_destination and ((control >> 6) & 0x3):
            raise UnsupportedInstruction(
                "FILL.XY window checking is classified but not modeled"
            )

        pixel_size = self._read_legal_psize()
        pixel_mask = MASK32 if pixel_size == 32 else (1 << pixel_size) - 1
        plane_mask = (
            self.state.read_io(PMASKL_ADDRESS)
            | (self.state.read_io(PMASKH_ADDRESS) << 16)
        )
        daddr = self.state.read_reg("B", 2)
        dptch = self.state.read_reg("B", 3)
        dimensions = self.state.read_reg("B", 7)
        color1 = self.state.read_reg("B", 9)
        width = dimensions & 0xFFFF
        height = (dimensions >> 16) & 0xFFFF
        total_pixels = width * height
        if total_pixels > MAX_BOUNDED_GRAPHICS_PIXELS:
            raise UnsupportedInstruction(
                f"{instruction.mnemonic} atomic model is limited to "
                f"{MAX_BOUNDED_GRAPHICS_PIXELS} pixels"
            )
        if dptch & (pixel_size - 1):
            raise ModelError(
                f"{instruction.mnemonic} requires a pixel-aligned DPTCH"
            )

        pitch_class: str | None = None
        if xy_destination:
            linear_start, pitch_class = self._xy_linear_result(
                daddr,
                CONVDP_ADDRESS,
                dptch,
                pixel_size,
                self.state.read_reg("B", 4),
            )
        else:
            linear_start = daddr
        if linear_start & (pixel_size - 1):
            raise ModelError(
                f"{instruction.mnemonic} requires a pixel-aligned DADDR"
            )

        assert self._active_trace is not None
        purpose = "fill_xy_replace" if xy_destination else "fill_l_replace"
        for row in range(height):
            row_start = (linear_start + row * dptch) & MASK32
            for column in range(width):
                address = (row_start + column * pixel_size) & MASK32
                lane = address & 0x1F
                if lane + pixel_size > 32:
                    raise ModelError(
                        f"{instruction.mnemonic} pixel crosses a long-word "
                        "boundary"
                    )
                raw_destination = self.state.memory.read_bits(
                    address, pixel_size
                )
                source_pixel = (color1 >> lane) & pixel_mask
                pixel_plane_mask = (plane_mask >> lane) & pixel_mask
                result_pixel = (
                    (raw_destination & pixel_plane_mask)
                    | (source_pixel & (~pixel_plane_mask & pixel_mask))
                )
                self.state.memory.write_bits(
                    address, pixel_size, result_pixel
                )
                self._active_trace.transactions.append(
                    {
                        "class": "pixel_write",
                        "purpose": purpose,
                        "bit_address": address,
                        "width": pixel_size,
                        "row": row,
                        "column": column,
                        "raw_destination": raw_destination,
                        "source_value": source_pixel,
                        "plane_mask": pixel_plane_mask,
                        "value": result_pixel,
                    }
                )

        if total_pixels != 0:
            self.state.write_reg(
                "B", 2, (linear_start + height * dptch) & MASK32
            )
        if pitch_class is not None:
            self._record_xy_pitch_class(pitch_class)
        self._active_trace.notes.append(
            f"successful atomic {instruction.mnemonic} W0 replace/"
            "no-transparency logical array; dimensions above the bounded "
            "model limit, physical grouping, hidden writes, page mode, waits, "
            "fault/retry, and interrupt continuation remain pending"
        )
        return None

    def _execute_fline(
        self, instruction: Instruction, words: list[int]
    ) -> int:
        del instruction
        config = self.state.read_io(CONFIG_ADDRESS)
        if config & 1:
            raise UnsupportedInstruction(
                "FLINE big-endian pixel mapping is classified but not modeled"
            )
        if self.state.read_io(DPYCTL_ADDRESS) & (1 << 11):
            raise UnsupportedInstruction(
                "FLINE CST-converted VRAM transfer is classified but not modeled"
            )
        control = self.state.read_io(CONTROL_ADDRESS)
        if (control >> 10) & 0x1F:
            raise UnsupportedInstruction(
                "FLINE pixel processing is currently limited to replace"
            )
        if control & (1 << 5):
            raise UnsupportedInstruction(
                "FLINE transparency is classified but not modeled"
            )

        pixel_size = self._read_legal_psize()
        pixel_mask = MASK32 if pixel_size == 32 else (1 << pixel_size) - 1
        plane_mask = (
            self.state.read_io(PMASKL_ADDRESS)
            | (self.state.read_io(PMASKH_ADDRESS) << 16)
        )
        decision = self._signed_word(self.state.read_reg("B", 0))
        daddr = self.state.read_reg("B", 2)
        dptch = self.state.read_reg("B", 3)
        dimensions = self.state.read_reg("B", 7)
        minor = (dimensions >> 16) & 0xFFFF
        major = dimensions & 0xFFFF
        color0 = self.state.read_reg("B", 8)
        color1 = self.state.read_reg("B", 9)
        count = self._signed_word(self.state.read_reg("B", 10))
        inc1 = self.state.read_reg("B", 11)
        inc2 = self.state.read_reg("B", 12)
        pattern = self.state.read_reg("B", 13)
        inc1_linear, pitch_class = self._xy_linear_result(
            inc1, CONVDP_ADDRESS, dptch, pixel_size, 0
        )
        inc2_linear, inc2_pitch_class = self._xy_linear_result(
            inc2, CONVDP_ADDRESS, dptch, pixel_size, 0
        )
        assert pitch_class == inc2_pitch_class
        algorithm_one = bool(words[0] & (1 << 7))
        pixels_drawn = max(count, 0)
        assert self._active_trace is not None

        while count > 0:
            if daddr & (pixel_size - 1):
                raise ModelError("FLINE requires a pixel-aligned DADDR")
            lane = daddr & 0x1F
            if lane + pixel_size > 32:
                raise ModelError("FLINE pixel crosses a long-word boundary")
            raw_destination = self.state.memory.read_bits(daddr, pixel_size)
            source_word = color1 if pattern & 1 else color0
            source_pixel = (source_word >> lane) & pixel_mask
            pixel_plane_mask = (plane_mask >> lane) & pixel_mask
            result_pixel = (
                (raw_destination & pixel_plane_mask)
                | (source_pixel & (~pixel_plane_mask & pixel_mask))
            )
            diagonal = decision > 0 if algorithm_one else decision >= 0
            decision_before = decision
            count -= 1
            self.state.memory.write_bits(daddr, pixel_size, result_pixel)
            self._active_trace.transactions.append(
                {
                    "class": "pixel_write",
                    "purpose": "fline_replace",
                    "bit_address": daddr,
                    "width": pixel_size,
                    "raw_destination": raw_destination,
                    "pattern_bit": pattern & 1,
                    "source_value": source_pixel,
                    "plane_mask": pixel_plane_mask,
                    "value": result_pixel,
                    "decision_before": decision_before & MASK32,
                    "diagonal": int(diagonal),
                }
            )
            pattern = ((pattern >> 1) | ((pattern & 1) << 31)) & MASK32
            if diagonal:
                decision += 2 * minor - 2 * major
                daddr = (daddr + inc1_linear) & MASK32
            else:
                decision += 2 * minor
                daddr = (daddr + inc2_linear) & MASK32
            decision = self._signed_word(decision)

        self.state.write_reg("B", 0, decision & MASK32)
        self.state.write_reg("B", 2, daddr)
        self.state.write_reg("B", 10, count & MASK32)
        self.state.write_reg("B", 13, pattern)
        self._record_xy_pitch_class(pitch_class)
        pixel_processing = 1 if pixel_size <= 4 else 0
        conversion = {
            "power_of_two": 0,
            "two_powers_of_two": 1,
            "arbitrary": 12,
        }[pitch_class]
        self._active_trace.notes.append(
            "successful atomic FLINE replace/no-transparency logical draw; "
            "physical reads/writes, page mode, waits, fault/retry, and "
            "interrupt continuation remain pending"
        )
        return 15 + 3 * conversion + (2 + pixel_processing) * pixels_drawn

    @staticmethod
    def _signed_word(value: int) -> int:
        value &= MASK32
        return value - 0x1_0000_0000 if value & 0x8000_0000 else value

    def _xy_pitch_product(
        self,
        y_coordinate: int,
        conversion: int,
        pitch: int,
    ) -> tuple[int, str]:
        conversion_value_1 = conversion & 0x1F
        conversion_value_2 = (conversion >> 8) & 0x1F
        if conversion_value_1 == 0:
            product = y_coordinate * self._signed_word(pitch)
            return product & MASK32, "arbitrary"

        shift_1 = (~conversion_value_1) & 0x1F
        product = y_coordinate << shift_1
        if conversion_value_2 == 0:
            return product & MASK32, "power_of_two"

        shift_2 = (~conversion_value_2) & 0x1F
        product += y_coordinate << shift_2
        return product & MASK32, "two_powers_of_two"

    def _xy_linear_result(
        self,
        xy_value: int,
        conversion_address: int,
        pitch: int,
        x_scale: int,
        offset: int,
    ) -> tuple[int, str]:
        x_coordinate = self._signed_half(xy_value)
        y_coordinate = self._signed_half(xy_value >> 16)
        y_product, pitch_class = self._xy_pitch_product(
            y_coordinate,
            self.state.read_io(conversion_address),
            pitch,
        )
        result = y_product + x_coordinate * x_scale + offset
        return result & MASK32, pitch_class

    def _record_xy_pitch_class(self, pitch_class: str) -> None:
        assert self._active_trace is not None
        self._active_trace.notes.append(
            f"XY conversion pitch class: {pitch_class}"
        )

    def _execute_cvdxyl(
        self, instruction: Instruction, words: list[int]
    ) -> int:
        del instruction
        register_file, destination = self._decode_destination(words[0])
        xy_value = self.state.read_reg(register_file, destination)
        offset = self.state.read_reg(register_file, 4)
        pitch = self.state.read_reg("B", 3)
        result, pitch_class = self._xy_linear_result(
            xy_value,
            CONVDP_ADDRESS,
            pitch,
            self._read_legal_psize(),
            offset,
        )
        self.state.write_reg(register_file, destination, result)
        self._record_xy_pitch_class(pitch_class)
        return {
            "power_of_two": 2,
            "two_powers_of_two": 3,
            "arbitrary": 14,
        }[pitch_class]

    def _execute_cvmxyl(
        self, instruction: Instruction, words: list[int]
    ) -> int:
        del instruction
        register_file, destination = self._decode_destination(words[0])
        xy_value = self.state.read_reg(register_file, destination)
        pitch = self.state.read_reg("B", 11)
        result, pitch_class = self._xy_linear_result(
            xy_value,
            CONVMP_ADDRESS,
            pitch,
            1,
            0,
        )
        self.state.write_reg(register_file, destination, result)
        self._record_xy_pitch_class(pitch_class)
        return {
            "power_of_two": 2,
            "two_powers_of_two": 3,
            "arbitrary": 14,
        }[pitch_class]

    def _execute_cvsxyl(
        self, instruction: Instruction, words: list[int]
    ) -> int:
        del instruction
        register_file, source, destination = (
            self._decode_source_destination(words[0])
        )
        offset = self.state.read_reg(register_file, source)
        xy_value = self.state.read_reg(register_file, destination)
        pitch = self.state.read_reg("B", 1)
        result, pitch_class = self._xy_linear_result(
            xy_value,
            CONVSP_ADDRESS,
            pitch,
            self._read_legal_psize(),
            offset,
        )
        self.state.write_reg(register_file, destination, result)
        self._record_xy_pitch_class(pitch_class)
        return {
            "power_of_two": 2,
            "two_powers_of_two": 3,
            "arbitrary": 14,
        }[pitch_class]

    def _execute_cvxyl(
        self, instruction: Instruction, words: list[int]
    ) -> int:
        del instruction
        register_file, source, destination = (
            self._decode_source_destination(words[0])
        )
        xy_value = self.state.read_reg(register_file, source)
        offset = self.state.read_reg("B", 4)
        pitch = self.state.read_reg("B", 3)
        result, pitch_class = self._xy_linear_result(
            xy_value,
            CONVDP_ADDRESS,
            pitch,
            self._read_legal_psize(),
            offset,
        )
        self.state.write_reg(register_file, destination, result)
        self._record_xy_pitch_class(pitch_class)
        return {
            "power_of_two": 3,
            "two_powers_of_two": 4,
            "arbitrary": 14,
        }[pitch_class]

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

    def _execute_software_trap(
        self,
        trap_number: int,
        save_return_state: bool,
        mnemonic: str,
    ) -> int:
        vector_address = (
            0xFFFF_FFE0 - (trap_number << 5)
        ) & MASK32
        return_pc = self.state.pc
        saved_st = self.state.st
        saved_pc_address = self.state.sp
        saved_st_address = self.state.sp

        assert self._active_trace is not None
        if save_return_state:
            saved_pc_address = (self.state.sp - 32) & MASK32
            saved_st_address = (self.state.sp - 64) & MASK32
            self.state.memory.write_bits(saved_pc_address, 32, return_pc)
            self.state.memory.write_bits(saved_st_address, 32, saved_st)
            self.state.sp = saved_st_address
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
                ]
            )
        vector = self.state.memory.read_bits(vector_address, 32)
        self.state.st = 0x0000_0010
        self.state.pc = vector & 0xFFFF_FFF0

        self._active_trace.transactions.append(
            {
                "class": "interrupt_vector_fetch",
                "bit_address": vector_address,
                "width": 32,
                "value": vector,
            }
        )
        self._active_trace.notes.append(
            f"successful atomic {mnemonic} abstraction; stack/vector "
            "fault and retry pending"
        )
        if not save_return_state:
            return 7
        return 10 if saved_st_address & 0x1F == 0 else 12

    def _execute_trap(
        self, instruction: Instruction, words: list[int]
    ) -> int:
        del instruction
        trap_number = words[0] & 0x1F
        return self._execute_software_trap(
            trap_number,
            trap_number != 0,
            "TRAP",
        )

    def _execute_trapl(
        self, instruction: Instruction, words: list[int]
    ) -> int:
        del instruction
        trap_number = words[1]
        if trap_number & 0x8000:
            trap_number -= 0x1_0000
        return self._execute_software_trap(
            trap_number,
            True,
            "TRAPL",
        )

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
