"""Primary-source ISA schema, fixture, and partial-space checks."""

from __future__ import annotations

import json
import unittest
from pathlib import Path

from tools.isa.isa_db import IsaDatabase

ROOT = Path(__file__).resolve().parents[2]
ISA_PATH = ROOT / "docs/generated/tms34020_isa.yaml"

REQUIRED_FIELDS = {
    "mnemonic",
    "aliases",
    "instruction_length_words",
    "opcode_mask",
    "opcode_value",
    "operand_fields",
    "register_file",
    "immediate_fields",
    "condition_fields",
    "addressing_modes",
    "source_registers",
    "destination_registers",
    "status_bits_read",
    "status_bits_written",
    "undefined_status_bits",
    "memory_transactions",
    "graphics_register_dependencies",
    "cache_interactions",
    "pipeline_interactions",
    "interruptibility",
    "restartability",
    "bus_fault_behavior",
    "documented_cycles",
    "cache_hit_cycles",
    "cache_miss_cycles",
    "bus_16_effects",
    "bus_32_effects",
    "page_mode_effects",
    "source_citations",
    "compatible_with_tms34010",
    "confidence",
}


class IsaTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.raw = json.loads(ISA_PATH.read_text(encoding="utf-8"))
        cls.database = IsaDatabase(cls.raw)

    def test_schema_fields_and_claim_boundary(self) -> None:
        self.assertEqual(
            self.raw["coverage"]["status"], "INCOMPLETE_PRIMARY_EXTRACTION"
        )
        self.assertFalse(
            self.raw["coverage"]["unmatched_first_words_are_reserved"]
        )
        self.assertEqual(
            self.raw["coverage"]["entry_count"],
            len(self.raw["instructions"]),
        )
        for instruction in self.raw["instructions"]:
            with self.subTest(mnemonic=instruction["mnemonic"]):
                self.assertEqual(set(instruction), REQUIRED_FIELDS)
                self.assertTrue(instruction["source_citations"])
                self.assertIn(
                    instruction["confidence"],
                    {"VERIFIED_PRIMARY", "PROVISIONAL"},
                )
                if instruction["confidence"] == "PROVISIONAL":
                    self.assertIn(
                        instruction["mnemonic"],
                        {
                            "CVXYL", "DIVS", "MMFM", "MPYS", "MPYU",
                            "RETI", "RETM",
                        },
                    )

    def test_independent_hand_checked_first_words(self) -> None:
        fixtures = {
            0x0020: ("REV", 1),
            0x003F: ("REV", 1),
            0x0300: ("NOP", 1),
            0x0380: ("ABS", 1),
            0x039F: ("ABS", 1),
            0x03A0: ("NEG", 1),
            0x03BF: ("NEG", 1),
            0x03C0: ("NEGB", 1),
            0x03DF: ("NEGB", 1),
            0x03E0: ("NOT", 1),
            0x03FF: ("NOT", 1),
            0x0320: ("CLRC", 1),
            0x0360: ("DINT", 1),
            0x0D60: ("EINT", 1),
            0x0D80: ("DSJ", 2),
            0x0D9F: ("DSJ", 2),
            0x0DA0: ("DSJEQ", 2),
            0x0DBF: ("DSJEQ", 2),
            0x0DC0: ("DSJNE", 2),
            0x0DDF: ("DSJNE", 2),
            0x0DE0: ("SETC", 1),
            0x3800: ("DSJS", 1),
            0x3BFF: ("DSJS", 1),
            0x3C00: ("DSJS", 1),
            0x3FFF: ("DSJS", 1),
            0xC000: ("JR.L", 2),
            0xC100: ("JR.L", 2),
            0xC800: ("JR.L", 2),
            0xCF00: ("JR.L", 2),
            0xC080: ("JACC", 3),
            0xC780: ("JACC", 3),
            0xCF80: ("JACC", 3),
            0x0120: ("EXGPC", 1),
            0x013F: ("EXGPC", 1),
            0x0140: ("GETPC", 1),
            0x015F: ("GETPC", 1),
            0x0160: ("JUMP", 1),
            0x017F: ("JUMP", 1),
            0x0180: ("GETST", 1),
            0x019F: ("GETST", 1),
            0x01A0: ("PUTST", 1),
            0x01AF: ("PUTST", 1),
            0x01B0: ("PUTST", 1),
            0x01BF: ("PUTST", 1),
            0x01C0: ("POPST", 1),
            0x01E0: ("PUSHST", 1),
            0x1000: ("ADDK", 1),
            0x1020: ("ADDK", 1),
            0x13FF: ("ADDK", 1),
            0x1400: ("SUBK", 1),
            0x1420: ("SUBK", 1),
            0x17FF: ("SUBK", 1),
            0x1800: ("MOVK", 1),
            0x1820: ("MOVK", 1),
            0x1BFF: ("MOVK", 1),
            0x1C00: ("BTST.K", 1),
            0x1E00: ("BTST.K", 1),
            0x1FE0: ("BTST.K", 1),
            0x1FFF: ("BTST.K", 1),
            0x0500: ("SEXT", 1),
            0x051F: ("SEXT", 1),
            0x0700: ("SEXT", 1),
            0x071F: ("SEXT", 1),
            0x0520: ("ZEXT", 1),
            0x053F: ("ZEXT", 1),
            0x0720: ("ZEXT", 1),
            0x073F: ("ZEXT", 1),
            0x0540: ("SETF", 1),
            0x057F: ("SETF", 1),
            0x0740: ("SETF", 1),
            0x077F: ("SETF", 1),
            0xD500: ("EXGF", 1),
            0xD50F: ("EXGF", 1),
            0xD510: ("EXGF", 1),
            0xD51F: ("EXGF", 1),
            0xD700: ("EXGF", 1),
            0xD70F: ("EXGF", 1),
            0xD710: ("EXGF", 1),
            0xD71F: ("EXGF", 1),
            0x09C0: ("MOVI.W", 2),
            0x09DF: ("MOVI.W", 2),
            0x09E0: ("MOVI.L", 3),
            0x09FF: ("MOVI.L", 3),
            0x0980: ("MMTM", 2),
            0x099F: ("MMTM", 2),
            0x09A0: ("MMFM", 2),
            0x09BF: ("MMFM", 2),
            0x4C00: ("MOVE", 1),
            0x4FFF: ("MOVE", 1),
            0x3000: ("RL.K", 1),
            0x33FF: ("RL.K", 1),
            0x6800: ("RL.R", 1),
            0x69FF: ("RL.R", 1),
            0x2000: ("SLA.K", 1),
            0x23FF: ("SLA.K", 1),
            0x6000: ("SLA.R", 1),
            0x61FF: ("SLA.R", 1),
            0x2400: ("SLL.K", 1),
            0x27FF: ("SLL.K", 1),
            0x6200: ("SLL.R", 1),
            0x63FF: ("SLL.R", 1),
            0x2800: ("SRA.K", 1),
            0x2BFF: ("SRA.K", 1),
            0x6400: ("SRA.R", 1),
            0x65FF: ("SRA.R", 1),
            0x2C00: ("SRL.K", 1),
            0x2FFF: ("SRL.K", 1),
            0x6600: ("SRL.R", 1),
            0x67FF: ("SRL.R", 1),
            0xEC00: ("MOVX", 1),
            0xEDFF: ("MOVX", 1),
            0xEE00: ("MOVY", 1),
            0xEFFF: ("MOVY", 1),
            0x4000: ("ADD", 1),
            0x41FF: ("ADD", 1),
            0x4200: ("ADDC", 1),
            0x43FF: ("ADDC", 1),
            0xE000: ("ADDXY", 1),
            0xE1FF: ("ADDXY", 1),
            0x0B00: ("ADDI.W", 2),
            0x0B1F: ("ADDI.W", 2),
            0x0B20: ("ADDI.L", 3),
            0x0B3F: ("ADDI.L", 3),
            0x0B40: ("CMPI.W", 2),
            0x0B5F: ("CMPI.W", 2),
            0x0B60: ("CMPI.L", 3),
            0x0B7F: ("CMPI.L", 3),
            0x0BE0: ("SUBI.W", 2),
            0x0BFF: ("SUBI.W", 2),
            0x0D00: ("SUBI.L", 3),
            0x0D1F: ("SUBI.L", 3),
            0x4400: ("SUB", 1),
            0x45FF: ("SUB", 1),
            0x4600: ("SUBB", 1),
            0x47FF: ("SUBB", 1),
            0xE200: ("SUBXY", 1),
            0xE3FF: ("SUBXY", 1),
            0x4800: ("CMP", 1),
            0x49FF: ("CMP", 1),
            0xE400: ("CMPXY", 1),
            0xE5FF: ("CMPXY", 1),
            0xE600: ("CPW", 1),
            0xE7FF: ("CPW", 1),
            0x0A60: ("CVMXYL", 1),
            0x0A7F: ("CVMXYL", 1),
            0x0A80: ("CVDXYL", 1),
            0x0A9F: ("CVDXYL", 1),
            0xE800: ("CVXYL", 1),
            0xE9FF: ("CVXYL", 1),
            0xEA00: ("CVSXYL", 1),
            0xEBFF: ("CVSXYL", 1),
            0x4A00: ("BTST.R", 1),
            0x4A20: ("BTST.R", 1),
            0x4BFF: ("BTST.R", 1),
            0x5000: ("AND", 1),
            0x51FF: ("AND", 1),
            0x5200: ("ANDN", 1),
            0x53FF: ("ANDN", 1),
            0x5400: ("OR", 1),
            0x55FF: ("OR", 1),
            0x5600: ("XOR", 1),
            0x57FF: ("XOR", 1),
            0x0B80: ("ANDNI", 3),
            0x0B9F: ("ANDNI", 3),
            0x0BA0: ("ORI", 3),
            0x0BBF: ("ORI", 3),
            0x0BC0: ("XORI", 3),
            0x0BDF: ("XORI", 3),
            0x0040: ("IDLE", 1),
            0x0080: ("MWAIT", 1),
            0x0900: ("TRAP", 1),
            0x091F: ("TRAP", 1),
            0x0860: ("RETM", 1),
            0x0920: ("CALL", 1),
            0x093F: ("CALL", 1),
            0x0940: ("RETI", 1),
            0x0960: ("RETS", 1),
            0x097F: ("RETS", 1),
            0x0D3F: ("CALLR", 2),
            0x0D5F: ("CALLA", 3),
            0x0C00: ("ADDXYI", 3),
            0x0C1E: ("ADDXYI", 3),
            0x00F0: ("BLMOVE", 1),
            0x00F3: ("BLMOVE", 1),
            0x0280: ("RPIX", 1),
            0x029E: ("RPIX", 1),
            0x3400: ("CMPK", 1),
            0x37FF: ("CMPK", 1),
            0x02A0: ("EXGPS", 1),
            0x02BF: ("EXGPS", 1),
            0x02C0: ("GETPS", 1),
            0x02DF: ("GETPS", 1),
            0x6A00: ("LMO", 1),
            0x6BFF: ("LMO", 1),
            0x7A00: ("RMO", 1),
            0x7BFF: ("RMO", 1),
            0x0273: ("SETCDP", 1),
            0x02FB: ("SETCMP", 1),
            0x0251: ("SETCSP", 1),
            0x080F: ("TRAPL", 2),
            0x0A00: ("VLCOL", 1),
            0x5800: ("DIVS", 1),
            0x59FF: ("DIVS", 1),
            0x5A00: ("DIVU", 1),
            0x5BFF: ("DIVU", 1),
            0x5C00: ("MPYS", 1),
            0x5DFF: ("MPYS", 1),
            0x5E00: ("MPYU", 1),
            0x5FFF: ("MPYU", 1),
            0x7E00: ("SWAPF", 1),
            0x7FFF: ("SWAPF", 1),
            0x8000: ("MOVE.RM", 1),
            0x83FF: ("MOVE.RM", 1),
            0x8400: ("MOVE.MR", 1),
            0x87FF: ("MOVE.MR", 1),
            0x8800: ("MOVE.MM", 1),
            0x8BFF: ("MOVE.MM", 1),
            0x6C00: ("MODS", 1),
            0x6DFF: ("MODS", 1),
            0x6E00: ("MODU", 1),
            0x6FFF: ("MODU", 1),
        }
        for word, expected in fixtures.items():
            with self.subTest(word=f"{word:04X}"):
                decoded = self.database.decode(word)
                self.assertIsNotNone(decoded)
                self.assertEqual(
                    (decoded.mnemonic, decoded.length_words), expected
                )

    def test_nearby_reserved_or_other_words_do_not_alias_fixed_opcodes(self) -> None:
        for word in (0x0041, 0x0081, 0x0250, 0x0252,
                     0x0272, 0x0274, 0x02FA, 0x02FC, 0x0301, 0x0321,
                     0x0361, 0x080E, 0x081F, 0x0861, 0x0941, 0x0A01,
                     0x0D61, 0x0DE1,
                     0x0FFF, 0xBFFF, 0xC001, 0xC081, 0xCFFF, 0xD000,
                     0x0AFF, 0x0C20,
                     0x79FF, 0x7C00,
                     0xD4FF, 0xD520, 0xD6FF, 0xD720):
            with self.subTest(word=f"{word:04X}"):
                self.assertIsNone(self.database.decode(word))

    def test_partial_65536_word_sweep_is_unique_and_disclosed(self) -> None:
        matched, unclassified = self.database.coverage()
        self.assertEqual(matched, 34262)
        self.assertEqual(unclassified, 65536 - 34262)
        self.assertGreater(unclassified, 0)

    def test_rev_records_device_profile_result_and_no_status_write(self) -> None:
        for word in range(0x0020, 0x0040):
            with self.subTest(word=f"{word:04X}"):
                decoded = self.database.decode(word)
                self.assertIsNotNone(decoded)
                self.assertEqual(decoded.mnemonic, "REV")
        instruction = self.database.decode(0x0020)
        self.assertIsNotNone(instruction)
        self.assertEqual(instruction.mnemonic, "REV")
        self.assertEqual(instruction.length_words, 1)
        self.assertEqual(instruction.opcode_mask, 0xFFE0)
        self.assertEqual(instruction.opcode_value, 0x0020)
        self.assertEqual(instruction.metadata["destination_registers"], ["Rd"])
        self.assertEqual(instruction.metadata["status_bits_read"], [])
        self.assertEqual(instruction.metadata["status_bits_written"], [])
        self.assertEqual(
            instruction.metadata["documented_cycles"],
            {"kind": "fixed", "machine_states": 1},
        )
        self.assertFalse(instruction.metadata["compatible_with_tms34010"])
        self.assertIn(
            "selected physical-device revision identity",
            instruction.metadata["source_registers"],
        )

    def test_trap_records_reset_exception_stack_and_timing_cases(self) -> None:
        for word in range(0x0900, 0x0920):
            with self.subTest(word=f"{word:04X}"):
                decoded = self.database.decode(word)
                self.assertIsNotNone(decoded)
                self.assertEqual(decoded.mnemonic, "TRAP")
        instruction = self.database.decode(0x0900)
        self.assertEqual(instruction.opcode_mask, 0xFFE0)
        self.assertEqual(instruction.opcode_value, 0x0900)
        self.assertEqual(instruction.length_words, 1)
        self.assertEqual(
            instruction.metadata["status_bits_written"],
            ["entire ST becomes 00000010h"],
        )
        self.assertEqual(
            instruction.metadata["documented_cycles"]["cases"],
            [
                {"when": "N=0", "machine_states": 7},
                {
                    "when": "N!=0 and saved ST is 32-bit aligned",
                    "machine_states": 10,
                },
                {
                    "when": "N!=0 and saved ST is not 32-bit aligned",
                    "machine_states": 12,
                },
            ],
        )
        self.assertTrue(instruction.metadata["compatible_with_tms34010"])
        self.assertIn(
            "does not save PC/ST or change SP",
            instruction.metadata["pipeline_interactions"][0],
        )

    def test_rets_records_stack_increment_and_alignment_timing(self) -> None:
        for word in range(0x0960, 0x0980):
            with self.subTest(word=f"{word:04X}"):
                decoded = self.database.decode(word)
                self.assertIsNotNone(decoded)
                self.assertEqual(decoded.mnemonic, "RETS")
        instruction = self.database.decode(0x0960)
        self.assertEqual(instruction.opcode_mask, 0xFFE0)
        self.assertEqual(instruction.opcode_value, 0x0960)
        self.assertEqual(instruction.length_words, 1)
        self.assertEqual(instruction.metadata["status_bits_written"], [])
        self.assertEqual(
            instruction.metadata["immediate_fields"][0][
                "stack_increment_bits"
            ],
            "32 + 16*N",
        )
        self.assertEqual(
            instruction.metadata["documented_cycles"],
            {
                "kind": "alignment_cases",
                "aligned_machine_states": 5,
                "unaligned_machine_states": 6,
                "alignment_address": "old SP stack-read address",
            },
        )
        self.assertTrue(instruction.metadata["compatible_with_tms34010"])

    def test_reti_records_context_selection_and_timing_contracts(self) -> None:
        instruction = self.database.decode(0x0940)
        self.assertIsNotNone(instruction)
        self.assertEqual(instruction.mnemonic, "RETI")
        self.assertEqual(instruction.opcode_mask, 0xFFFF)
        self.assertEqual(instruction.opcode_value, 0x0940)
        self.assertEqual(instruction.length_words, 1)
        self.assertEqual(
            instruction.metadata["status_bits_written"],
            [
                "entire ST from the stack; restored IX/BF is cleared after "
                "its corresponding internal state is restored"
            ],
        )
        self.assertEqual(
            instruction.metadata["memory_transactions"][0],
            "read 32-bit saved ST at old SP, then saved PC at old SP+32",
        )
        self.assertEqual(
            instruction.metadata["documented_cycles"],
            {
                "kind": "saved_context_cases",
                "normal_machine_states": 7,
                "ix_machine_states": 38,
                "bf_machine_states": 52,
                "selection": (
                    "BF has the longest published case; otherwise IX; "
                    "otherwise normal"
                ),
            },
        )
        self.assertTrue(instruction.metadata["compatible_with_tms34010"])
        self.assertEqual(instruction.metadata["confidence"], "PROVISIONAL")

    def test_retm_records_forced_fetch_and_interrupt_delay_contracts(self) -> None:
        instruction = self.database.decode(0x0860)
        self.assertIsNotNone(instruction)
        self.assertEqual(instruction.mnemonic, "RETM")
        self.assertEqual(instruction.opcode_mask, 0xFFFF)
        self.assertEqual(instruction.opcode_value, 0x0860)
        self.assertEqual(instruction.length_words, 1)
        self.assertEqual(
            instruction.metadata["documented_cycles"],
            {
                "kind": "saved_context_cases",
                "normal_machine_states": 10,
                "ix_machine_states": 38,
                "bf_machine_states": 52,
                "selection": "BF first; otherwise IX; otherwise normal",
            },
        )
        self.assertIn(
            "forced directly to memory",
            instruction.metadata["cache_interactions"][1],
        )
        self.assertIn(
            "one instruction executes",
            instruction.metadata["pipeline_interactions"][2],
        )
        self.assertFalse(instruction.metadata["compatible_with_tms34010"])
        self.assertEqual(instruction.metadata["confidence"], "PROVISIONAL")

    def test_call_family_records_primary_stack_and_timing_contracts(self) -> None:
        for word in range(0x0920, 0x0940):
            with self.subTest(word=f"{word:04X}"):
                decoded = self.database.decode(word)
                self.assertIsNotNone(decoded)
                self.assertEqual(decoded.mnemonic, "CALL")
        call = self.database.decode(0x0920)
        self.assertEqual(call.opcode_mask, 0xFFE0)
        self.assertEqual(call.length_words, 1)
        self.assertEqual(call.metadata["status_bits_written"], [])
        self.assertEqual(
            call.metadata["documented_cycles"],
            {
                "kind": "visible_plus_hidden_write",
                "visible_machine_states": 3,
                "aligned_hidden_write_states": 1,
                "unaligned_hidden_write_states": 4,
                "alignment_address": (
                    "SP/new stack-write address; predecrement by 32 "
                    "preserves alignment"
                ),
            },
        )

        callr = self.database.decode(0x0D3F)
        self.assertEqual(callr.mnemonic, "CALLR")
        self.assertEqual(callr.length_words, 2)
        self.assertTrue(callr.metadata["immediate_fields"][0]["signed"])
        self.assertEqual(
            callr.metadata["documented_cycles"],
            call.metadata["documented_cycles"],
        )

        calla = self.database.decode(0x0D5F)
        self.assertEqual(calla.mnemonic, "CALLA")
        self.assertEqual(calla.length_words, 3)
        self.assertEqual(
            calla.metadata["immediate_fields"][0]["word_order"],
            "low_then_high",
        )
        self.assertEqual(
            calla.metadata["documented_cycles"]["kind"],
            "ambiguous_primary_table",
        )
        self.assertEqual(
            len(calla.metadata["documented_cycles"]["printed_clauses"]),
            4,
        )
        self.assertIn(
            "do not map",
            calla.metadata["documented_cycles"]["resolution"],
        )

    def test_lmo_records_primary_register_and_status_contract(self) -> None:
        lmo = self.database.decode(0x6A00)
        self.assertIsNotNone(lmo)
        self.assertEqual(lmo.mnemonic, "LMO")
        self.assertEqual(lmo.length_words, 1)
        self.assertEqual(lmo.metadata["status_bits_written"], ["Z"])
        self.assertEqual(
            lmo.metadata["documented_cycles"],
            {"kind": "fixed", "machine_states": 1},
        )
        self.assertTrue(lmo.metadata["compatible_with_tms34010"])
        self.assertIn(
            "same file",
            lmo.metadata["register_file"],
        )

    def test_xy_register_arithmetic_records_primary_contract(self) -> None:
        for opcode, mnemonic in ((0xE000, "ADDXY"), (0xE200, "SUBXY")):
            instruction = self.database.decode(opcode)
            with self.subTest(mnemonic=mnemonic):
                self.assertIsNotNone(instruction)
                self.assertEqual(instruction.mnemonic, mnemonic)
                self.assertEqual(instruction.length_words, 1)
                self.assertEqual(
                    instruction.metadata["status_bits_written"],
                    ["N", "C", "Z", "V"],
                )
                self.assertEqual(
                    instruction.metadata["documented_cycles"],
                    {"kind": "fixed", "machine_states": 1},
                )
                self.assertTrue(
                    instruction.metadata["compatible_with_tms34010"]
                )
                self.assertIn(
                    "same file",
                    instruction.metadata["register_file"],
                )

    def test_cmpxy_records_nondestructive_primary_status_contract(self) -> None:
        instruction = self.database.decode(0xE400)
        self.assertIsNotNone(instruction)
        self.assertEqual(instruction.mnemonic, "CMPXY")
        self.assertEqual(instruction.length_words, 1)
        self.assertEqual(instruction.opcode_mask, 0xFE00)
        self.assertEqual(instruction.opcode_value, 0xE400)
        self.assertEqual(
            instruction.metadata["status_bits_written"],
            ["N", "C", "Z", "V"],
        )
        self.assertEqual(instruction.metadata["destination_registers"], [])
        self.assertEqual(
            instruction.metadata["documented_cycles"],
            {"kind": "fixed", "machine_states": 1},
        )
        self.assertTrue(instruction.metadata["compatible_with_tms34010"])
        self.assertIn("same file", instruction.metadata["register_file"])
        self.assertIn(
            "X=bits 15:0",
            instruction.metadata["graphics_register_dependencies"][0],
        )

    def test_cpw_records_signed_window_outcode_and_v_only_contract(self) -> None:
        for word in range(0xE600, 0xE800):
            with self.subTest(word=f"{word:04X}"):
                decoded = self.database.decode(word)
                self.assertIsNotNone(decoded)
                self.assertEqual(decoded.mnemonic, "CPW")
        instruction = self.database.decode(0xE600)
        self.assertEqual(instruction.opcode_mask, 0xFE00)
        self.assertEqual(instruction.opcode_value, 0xE600)
        self.assertEqual(instruction.length_words, 1)
        self.assertEqual(instruction.metadata["status_bits_written"], ["V"])
        self.assertEqual(
            instruction.metadata["source_registers"],
            ["Rs", "B5/WSTART old value", "B6/WEND old value"],
        )
        self.assertEqual(
            instruction.metadata["documented_cycles"],
            {"kind": "fixed", "machine_states": 1},
        )
        self.assertIn(
            "capture Rs, WSTART, and WEND before writing Rd",
            instruction.metadata["pipeline_interactions"][0],
        )
        self.assertTrue(instruction.metadata["compatible_with_tms34010"])

    def test_xy_conversion_family_records_pitch_classes_and_boundaries(self) -> None:
        ranges = (
            (0x0A60, 0x0A80, "CVMXYL"),
            (0x0A80, 0x0AA0, "CVDXYL"),
            (0xE800, 0xEA00, "CVXYL"),
            (0xEA00, 0xEC00, "CVSXYL"),
        )
        for start, end, mnemonic in ranges:
            for word in range(start, end):
                with self.subTest(word=f"{word:04X}"):
                    decoded = self.database.decode(word)
                    self.assertIsNotNone(decoded)
                    self.assertEqual(decoded.mnemonic, mnemonic)

        expected_cycles = {
            "CVDXYL": (2, 3, 14),
            "CVMXYL": (2, 3, 14),
            "CVSXYL": (2, 3, 14),
            "CVXYL": (3, 4, None),
        }
        for mnemonic, cycles in expected_cycles.items():
            instruction = next(
                item
                for item in self.database.instructions
                if item.mnemonic == mnemonic
            )
            self.assertEqual(instruction.metadata["status_bits_written"], [])
            timing = instruction.metadata["documented_cycles"]
            self.assertEqual(
                (
                    timing["power_of_two_machine_states"],
                    timing["two_powers_of_two_machine_states"],
                    timing.get("arbitrary_pitch_machine_states"),
                ),
                cycles,
            )
        cvxyl_timing = self.database.decode(0xE800).metadata[
            "documented_cycles"
        ]
        self.assertEqual(cvxyl_timing["kind"],
                         "pitch_class_cases_with_primary_conflict")
        self.assertEqual(cvxyl_timing[
            "arbitrary_instruction_page_machine_states"
        ], 14)
        self.assertEqual(cvxyl_timing[
            "arbitrary_chapter15_machine_states"
        ], 15)
        self.assertEqual(cvxyl_timing[
            "implemented_provisional_machine_states"
        ], 14)
        self.assertTrue(self.database.decode(0xE800).metadata[
            "compatible_with_tms34010"
        ])
        for word in (0x0A60, 0x0A80, 0xEA00):
            self.assertFalse(self.database.decode(word).metadata[
                "compatible_with_tms34010"
            ])

    def test_divide_family_records_pair_status_and_timing_contracts(self) -> None:
        for start, end, mnemonic in (
            (0x5800, 0x5A00, "DIVS"),
            (0x5A00, 0x5C00, "DIVU"),
        ):
            for word in range(start, end):
                with self.subTest(word=f"{word:04X}"):
                    decoded = self.database.decode(word)
                    self.assertIsNotNone(decoded)
                    self.assertEqual(decoded.mnemonic, mnemonic)

        divs = self.database.decode(0x5800)
        divu = self.database.decode(0x5A00)
        self.assertEqual(divs.metadata["confidence"], "PROVISIONAL")
        self.assertEqual(divu.metadata["confidence"], "VERIFIED_PRIMARY")
        self.assertEqual(divs.metadata["status_bits_written"], ["N", "Z", "V"])
        self.assertEqual(divu.metadata["status_bits_written"], ["Z", "V"])
        for instruction in (divs, divu):
            self.assertIn("Rd+1 remainder", instruction.metadata[
                "destination_registers"
            ][1])
            self.assertIn("Rd=14 pairs Rd with SP", instruction.metadata[
                "register_file"
            ])
            self.assertTrue(instruction.metadata[
                "compatible_with_tms34010"
            ])
        self.assertEqual(
            divs.metadata["documented_cycles"]["result_80000000_machine_states"],
            41,
        )
        self.assertEqual(
            divu.metadata["documented_cycles"][
                "even_divisor_zero_or_early_overflow_machine_states"
            ],
            5,
        )
        self.assertIn(
            "unscaled X",
            self.database.decode(0x0A60).metadata[
                "graphics_register_dependencies"
            ][2],
        )

    def test_modulus_family_records_remainder_status_and_timing(self) -> None:
        for start, end, mnemonic in (
            (0x6C00, 0x6E00, "MODS"),
            (0x6E00, 0x7000, "MODU"),
        ):
            for word in range(start, end):
                with self.subTest(word=f"{word:04X}"):
                    decoded = self.database.decode(word)
                    self.assertIsNotNone(decoded)
                    self.assertEqual(decoded.mnemonic, mnemonic)

        mods = self.database.decode(0x6C00)
        modu = self.database.decode(0x6E00)
        self.assertEqual(
            mods.metadata["status_bits_written"], ["N", "Z", "V"]
        )
        self.assertEqual(modu.metadata["status_bits_written"], ["Z", "V"])
        for instruction in (mods, modu):
            self.assertIn("remainder", instruction.metadata[
                "destination_registers"
            ][0])
            self.assertIn("same A or B", instruction.metadata[
                "register_file"
            ])
            self.assertTrue(instruction.metadata[
                "compatible_with_tms34010"
            ])
        self.assertEqual(
            mods.metadata["documented_cycles"]["divisor_zero_machine_states"],
            3,
        )
        self.assertIn(
            "mathematically unreachable",
            mods.metadata["documented_cycles"][
                "result_80000000_reachability"
            ],
        )
        self.assertEqual(
            modu.metadata["documented_cycles"]["normal_machine_states"],
            35,
        )

    def test_multiply_family_records_full_product_flags_and_conflict(self) -> None:
        for start, end, mnemonic in (
            (0x5C00, 0x5E00, "MPYS"),
            (0x5E00, 0x6000, "MPYU"),
        ):
            for word in range(start, end):
                with self.subTest(word=f"{word:04X}"):
                    decoded = self.database.decode(word)
                    self.assertIsNotNone(decoded)
                    self.assertEqual(decoded.mnemonic, mnemonic)

        mpys = self.database.decode(0x5C00)
        mpyu = self.database.decode(0x5E00)
        self.assertEqual(mpys.metadata["status_bits_written"], ["N", "Z"])
        self.assertEqual(mpyu.metadata["status_bits_written"], ["Z"])
        for instruction in (mpys, mpyu):
            self.assertIn(
                "full",
                instruction.metadata["destination_registers"][1],
            )
            self.assertIn(
                "RSC-0030",
                instruction.metadata["documented_cycles"]["conflict"],
            )
            self.assertEqual(instruction.metadata["confidence"], "PROVISIONAL")
            self.assertTrue(instruction.metadata["compatible_with_tms34010"])
        self.assertIn(
            "raw Rs bit31",
            mpyu.metadata["documented_cycles"]["selected_machine_states"],
        )

    def test_swapf_records_locked_rmw_and_valid_field_restriction(self) -> None:
        for word in range(0x7E00, 0x8000):
            with self.subTest(word=f"{word:04X}"):
                decoded = self.database.decode(word)
                self.assertIsNotNone(decoded)
                self.assertEqual(decoded.mnemonic, "SWAPF")
        swapf = self.database.decode(0x7E00)
        self.assertEqual(swapf.metadata["status_bits_written"], ["N", "Z", "V"])
        self.assertEqual(
            swapf.metadata["documented_cycles"]["base_machine_states"], 5
        )
        self.assertIn("bus-locked", swapf.metadata["memory_transactions"][0])
        self.assertIn("SIZE16", swapf.metadata["bus_16_effects"])
        self.assertIn(
            "fit wholly",
            swapf.metadata["pipeline_interactions"][1],
        )
        self.assertFalse(swapf.metadata["compatible_with_tms34010"])

    def test_multiple_register_moves_record_opposite_masks_and_timing(self) -> None:
        for word in range(0x0980, 0x09A0):
            with self.subTest(word=f"{word:04X}"):
                decoded = self.database.decode(word)
                self.assertIsNotNone(decoded)
                self.assertEqual(decoded.mnemonic, "MMTM")
        for word in range(0x09A0, 0x09C0):
            with self.subTest(word=f"{word:04X}"):
                decoded = self.database.decode(word)
                self.assertIsNotNone(decoded)
                self.assertEqual(decoded.mnemonic, "MMFM")

        mmtm = self.database.decode(0x0980)
        mmfm = self.database.decode(0x09A0)
        self.assertEqual(mmtm.length_words, 2)
        self.assertEqual(mmfm.length_words, 2)
        self.assertIn("bit 15=A0/B0", mmtm.metadata["operand_fields"][2]["encoding"])
        self.assertIn("bit 0=A0/B0", mmfm.metadata["operand_fields"][2]["encoding"])
        self.assertEqual(mmtm.metadata["status_bits_written"], ["N"])
        self.assertEqual(mmfm.metadata["status_bits_written"], [])
        self.assertIn(
            "n+5", mmfm.metadata["documented_cycles"]["machine_states"]
        )
        self.assertIn(
            "RSC-0033", mmfm.metadata["documented_cycles"]["primary_conflict"]
        )

    def test_btst_forms_record_complemented_constant_and_status_only(self) -> None:
        constant = self.database.decode(0x1FE0)
        register = self.database.decode(0x4A20)
        self.assertEqual(constant.mnemonic, "BTST.K")
        self.assertEqual(register.mnemonic, "BTST.R")
        self.assertEqual(
            constant.metadata["immediate_fields"][0]["object_encoding"],
            "ones_complement_of_bit_index",
        )
        self.assertIn("same file", register.metadata["register_file"])
        for instruction in (constant, register):
            self.assertEqual(instruction.length_words, 1)
            self.assertEqual(
                instruction.metadata["status_bits_written"], ["Z"]
            )
            self.assertEqual(instruction.metadata["destination_registers"], [])
            self.assertEqual(
                instruction.metadata["documented_cycles"],
                {"kind": "fixed", "machine_states": 1},
            )
            self.assertTrue(
                instruction.metadata["compatible_with_tms34010"]
            )

    def test_field_parameter_forms_record_banks_status_and_timing(self) -> None:
        setf = self.database.decode(0x0760)
        sext0 = self.database.decode(0x0500)
        sext1 = self.database.decode(0x0700)
        zext0 = self.database.decode(0x0520)
        zext1 = self.database.decode(0x0720)

        self.assertEqual(setf.mnemonic, "SETF")
        self.assertEqual(
            setf.metadata["status_bits_written"],
            ["FS0", "FE0", "FS1", "FE1"],
        )
        self.assertEqual(
            setf.metadata["immediate_fields"][0]["zero_encoding"], 32
        )
        self.assertEqual(
            setf.metadata["documented_cycles"],
            {"kind": "fixed", "machine_states": 1},
        )

        for instruction, mnemonic, states, status_bits in (
            (sext0, "SEXT", 2, ["N", "Z"]),
            (sext1, "SEXT", 2, ["N", "Z"]),
            (zext0, "ZEXT", 1, ["Z"]),
            (zext1, "ZEXT", 1, ["Z"]),
        ):
            with self.subTest(opcode=instruction.opcode_value):
                self.assertEqual(instruction.mnemonic, mnemonic)
                self.assertEqual(
                    instruction.metadata["status_bits_written"], status_bits
                )
                self.assertEqual(
                    instruction.metadata["documented_cycles"],
                    {"kind": "fixed", "machine_states": states},
                )
                self.assertTrue(
                    instruction.metadata["compatible_with_tms34010"]
                )

    def test_exgf_records_atomic_exchange_and_bank_dependent_timing(self) -> None:
        field_zero = self.database.decode(0xD500)
        field_one = self.database.decode(0xD700)

        self.assertIs(field_zero, field_one)
        self.assertEqual(field_zero.mnemonic, "EXGF")
        self.assertEqual(
            field_zero.metadata["source_registers"],
            ["Rd old low 6 bits", "selected ST.FS/FE bank"],
        )
        self.assertEqual(
            field_zero.metadata["destination_registers"],
            ["Rd", "selected ST.FS/FE bank"],
        )
        self.assertEqual(
            field_zero.metadata["documented_cycles"],
            {
                "kind": "cases",
                "cases": [
                    {"when": "F=0", "machine_states": 1},
                    {"when": "F=1", "machine_states": 2},
                ],
            },
        )
        self.assertTrue(field_zero.metadata["compatible_with_tms34010"])
        self.assertIn(
            "ISA-DISC-0003-EXGF-F1-timing",
            self.raw["coverage"]["known_secondary_discrepancies"],
        )

    def test_putst_records_full_status_write_and_primary_timing(self) -> None:
        putst_a = self.database.decode(0x01A0)
        putst_b_sp = self.database.decode(0x01BF)

        self.assertIs(putst_a, putst_b_sp)
        self.assertEqual(putst_a.mnemonic, "PUTST")
        self.assertEqual(putst_a.metadata["source_registers"], ["Rs"])
        self.assertEqual(putst_a.metadata["destination_registers"], ["ST"])
        self.assertEqual(
            putst_a.metadata["status_bits_written"], ["entire ST"]
        )
        self.assertEqual(
            putst_a.metadata["documented_cycles"],
            {"kind": "fixed", "machine_states": 3},
        )
        self.assertTrue(putst_a.metadata["compatible_with_tms34010"])
        self.assertIsNone(self.database.decode(0x01C1))

    def test_jump_records_register_redirect_and_alignment_contract(self) -> None:
        jump_a = self.database.decode(0x0160)
        jump_b_sp = self.database.decode(0x017F)

        self.assertIs(jump_a, jump_b_sp)
        self.assertEqual(jump_a.mnemonic, "JUMP")
        self.assertEqual(jump_a.metadata["source_registers"], ["Rs"])
        self.assertEqual(jump_a.metadata["destination_registers"], ["PC"])
        self.assertEqual(jump_a.metadata["status_bits_written"], [])
        self.assertEqual(
            jump_a.metadata["documented_cycles"],
            {"kind": "fixed", "machine_states": 2},
        )
        self.assertIn(
            "bits 3:0 cleared",
            jump_a.metadata["pipeline_interactions"][0],
        )
        self.assertTrue(jump_a.metadata["compatible_with_tms34010"])
        self.assertEqual(self.database.decode(0x015F).mnemonic, "GETPC")
        self.assertEqual(self.database.decode(0x0180).mnemonic, "GETST")

    def test_dsj_family_records_conditional_decrement_redirect_contract(self) -> None:
        cases = (
            (0x0D80, "DSJ", []),
            (0x0DA0, "DSJEQ", ["Z"]),
            (0x0DC0, "DSJNE", ["Z"]),
        )
        expected_cycles = {
            "kind": "cases",
            "cases": [
                {"when": "no jump", "machine_states": 2},
                {"when": "jump", "machine_states": 3},
            ],
        }
        for opcode, mnemonic, status_reads in cases:
            with self.subTest(mnemonic=mnemonic):
                instruction = self.database.decode(opcode)
                self.assertIsNotNone(instruction)
                self.assertEqual(instruction.mnemonic, mnemonic)
                self.assertEqual(instruction.length_words, 2)
                self.assertEqual(
                    instruction.metadata["status_bits_read"],
                    status_reads,
                )
                self.assertEqual(
                    instruction.metadata["status_bits_written"],
                    [],
                )
                self.assertEqual(
                    instruction.metadata["documented_cycles"],
                    expected_cycles,
                )
                offset = instruction.metadata["immediate_fields"][0]
                self.assertEqual(offset["width"], 16)
                self.assertTrue(offset["signed"])
                self.assertEqual(offset["scale_bit_addresses"], 16)
                self.assertTrue(
                    instruction.metadata["compatible_with_tms34010"]
                )
        self.assertIsNone(self.database.decode(0x0D7F))
        self.assertEqual(self.database.decode(0x0DE0).mnemonic, "SETC")

    def test_dsjs_records_embedded_direction_magnitude_and_timing(self) -> None:
        forward_zero = self.database.decode(0x3800)
        forward_max = self.database.decode(0x3BFF)
        backward_zero = self.database.decode(0x3C00)
        backward_max = self.database.decode(0x3FFF)

        self.assertIs(forward_zero, forward_max)
        self.assertIs(forward_zero, backward_zero)
        self.assertIs(forward_zero, backward_max)
        self.assertEqual(forward_zero.mnemonic, "DSJS")
        self.assertEqual(forward_zero.length_words, 1)
        self.assertEqual(forward_zero.opcode_mask, 0xF800)
        self.assertEqual(forward_zero.metadata["status_bits_read"], [])
        self.assertEqual(forward_zero.metadata["status_bits_written"], [])
        self.assertEqual(
            forward_zero.metadata["documented_cycles"],
            {
                "kind": "cases",
                "cases": [
                    {"when": "no jump", "machine_states": 2},
                    {"when": "jump", "machine_states": 3},
                ],
            },
        )
        offset = forward_zero.metadata["immediate_fields"][0]
        self.assertEqual(offset["word"], 0)
        self.assertEqual(offset["lsb"], 5)
        self.assertEqual(offset["width"], 5)
        self.assertFalse(offset["signed"])
        self.assertEqual(offset["direction_bit"], 10)
        self.assertEqual(offset["scale_bit_addresses"], 16)
        self.assertEqual(
            offset["range_from_instruction_address_words"],
            "-30..+32",
        )
        self.assertTrue(
            forward_zero.metadata["compatible_with_tms34010"]
        )
        self.assertEqual(self.database.decode(0x37FF).mnemonic, "CMPK")
        self.assertEqual(self.database.decode(0x4000).mnemonic, "ADD")

    def test_jr_long_records_all_conditions_relative_target_and_timing(
        self,
    ) -> None:
        forms = [self.database.decode(0xC000 | (code << 8))
                 for code in range(16)]
        self.assertTrue(all(instruction is forms[0] for instruction in forms))
        instruction = forms[0]
        self.assertEqual(instruction.mnemonic, "JR.L")
        self.assertEqual(instruction.length_words, 2)
        self.assertEqual(instruction.opcode_mask, 0xF0FF)
        self.assertEqual(
            instruction.metadata["status_bits_read"],
            ["N", "C", "Z", "V"],
        )
        self.assertEqual(instruction.metadata["status_bits_written"], [])
        conditions = instruction.metadata["condition_fields"][0]["codes"]
        self.assertEqual(set(conditions), set("0123456789ABCDEF"))
        self.assertEqual(conditions["0"], "true")
        self.assertEqual(conditions["4"], "N != V")
        self.assertEqual(conditions["D"], "!V")
        offset = instruction.metadata["immediate_fields"][0]
        self.assertEqual(offset["width"], 16)
        self.assertTrue(offset["signed"])
        self.assertEqual(offset["scale_bit_addresses"], 16)
        self.assertEqual(
            instruction.metadata["documented_cycles"],
            {
                "kind": "cases",
                "cases": [
                    {"when": "no jump", "machine_states": 2},
                    {"when": "jump", "machine_states": 3},
                ],
            },
        )
        self.assertTrue(instruction.metadata["compatible_with_tms34010"])
        self.assertIsNone(self.database.decode(0xC001))
        self.assertEqual(self.database.decode(0xC080).mnemonic, "JACC")

    def test_jacc_records_all_conditions_absolute_target_and_timing(
        self,
    ) -> None:
        forms = [
            self.database.decode(0xC080 | (code << 8))
            for code in range(16)
        ]
        self.assertTrue(all(instruction is forms[0] for instruction in forms))
        instruction = forms[0]
        self.assertEqual(instruction.mnemonic, "JACC")
        self.assertEqual(instruction.length_words, 3)
        self.assertEqual(instruction.opcode_mask, 0xF0FF)
        self.assertEqual(
            instruction.metadata["status_bits_read"],
            ["N", "C", "Z", "V"],
        )
        self.assertEqual(instruction.metadata["status_bits_written"], [])
        conditions = instruction.metadata["condition_fields"][0]["codes"]
        self.assertEqual(set(conditions), set("0123456789ABCDEF"))
        self.assertEqual(conditions["0"], "true")
        self.assertEqual(conditions["7"], "(N == V) && !Z")
        self.assertEqual(conditions["F"], "!N")
        address = instruction.metadata["immediate_fields"][0]
        self.assertEqual(address["width"], 32)
        self.assertFalse(address["signed"])
        self.assertEqual(address["word_order"], ["low_16", "high_16"])
        self.assertEqual(
            address["alignment"],
            "PC bits 3:0 are hardwired to zero",
        )
        self.assertEqual(
            instruction.metadata["documented_cycles"],
            {
                "kind": "cases",
                "cases": [
                    {"when": "no jump", "machine_states": 3},
                    {"when": "jump", "machine_states": 4},
                ],
            },
        )
        self.assertTrue(instruction.metadata["compatible_with_tms34010"])
        self.assertEqual(self.database.decode(0xC000).mnemonic, "JR.L")
        self.assertIsNone(self.database.decode(0xC081))

    def test_stack_status_forms_record_ordering_and_alignment_timing(self) -> None:
        popst = self.database.decode(0x01C0)
        pushst = self.database.decode(0x01E0)

        self.assertEqual(popst.mnemonic, "POPST")
        self.assertEqual(
            popst.metadata["memory_transactions"],
            ["32-bit data read at old SP"],
        )
        self.assertEqual(
            popst.metadata["documented_cycles"],
            {
                "kind": "cases",
                "cases": [
                    {
                        "when": "SP 32-bit aligned",
                        "machine_states": 6,
                    },
                    {
                        "when": "SP not 32-bit aligned",
                        "machine_states": 7,
                    },
                ],
            },
        )
        self.assertEqual(pushst.mnemonic, "PUSHST")
        self.assertEqual(
            pushst.metadata["memory_transactions"],
            ["32-bit data write at SP minus 32"],
        )
        self.assertEqual(
            pushst.metadata["documented_cycles"]["cases"][0],
            {
                "when": "SP 32-bit aligned",
                "machine_states": 2,
                "hidden_write_states": 1,
            },
        )
        self.assertEqual(
            pushst.metadata["documented_cycles"]["cases"][1],
            {
                "when": "SP not 32-bit aligned",
                "machine_states": 2,
                "hidden_write_states": 2,
            },
        )
        self.assertTrue(popst.metadata["compatible_with_tms34010"])
        self.assertTrue(pushst.metadata["compatible_with_tms34010"])
        self.assertIsNone(self.database.decode(0x01C1))
        self.assertIsNone(self.database.decode(0x01DF))
        self.assertIsNone(self.database.decode(0x01E1))

    def test_shift_forms_record_direct_and_twos_complement_counts(self) -> None:
        direct_constant = self.database.decode(0x20E1)
        direct_register = self.database.decode(0x60E1)
        right_constant = self.database.decode(0x2FE1)
        right_register = self.database.decode(0x64E1)

        self.assertEqual(direct_constant.mnemonic, "SLA.K")
        self.assertEqual(direct_register.mnemonic, "SLA.R")
        self.assertEqual(
            direct_constant.metadata["immediate_fields"][0][
                "object_encoding"
            ],
            "direct_count_modulo_32",
        )
        self.assertIn(
            "direct left-shift count",
            direct_register.metadata["operand_fields"][0]["encoding"],
        )

        self.assertEqual(right_constant.mnemonic, "SRL.K")
        self.assertEqual(right_register.mnemonic, "SRA.R")
        self.assertEqual(
            right_constant.metadata["immediate_fields"][0][
                "object_encoding"
            ],
            "negative_count_modulo_32",
        )
        self.assertIn(
            "two's complement",
            right_register.metadata["operand_fields"][0]["encoding"],
        )

        expected_cycles = {
            "SLA.K": 3,
            "SLA.R": 3,
            "SLL.K": 1,
            "SLL.R": 1,
            "SRA.K": 1,
            "SRA.R": 1,
            "SRL.K": 1,
            "SRL.R": 1,
        }
        for mnemonic, machine_states in expected_cycles.items():
            instruction = next(
                entry
                for entry in self.database.instructions
                if entry.mnemonic == mnemonic
            )
            with self.subTest(mnemonic=mnemonic):
                self.assertEqual(
                    instruction.metadata["documented_cycles"],
                    {"kind": "fixed", "machine_states": machine_states},
                )

    def test_trapl_primary_length_disagrees_with_pinned_mame_disassembly(self) -> None:
        trapl = self.database.decode(0x080F)
        self.assertEqual(trapl.length_words, 2)
        self.assertIn(
            "ISA-DISC-0001-TRAPL-length",
            self.raw["coverage"]["known_secondary_discrepancies"],
        )

    def test_fixed_low_bits_follow_ti_not_secondary_aliases(self) -> None:
        for word in (0x0301, 0x0321, 0x0361, 0x0D61, 0x0DE1):
            with self.subTest(word=f"{word:04X}"):
                self.assertIsNone(self.database.decode(word))
        self.assertIn(
            "ISA-DISC-0002-fixed-low-bits",
            self.raw["coverage"]["known_secondary_discrepancies"],
        )

    def test_andi_alias_records_complemented_extension_encoding(self) -> None:
        andni = self.database.decode(0x0B80)
        self.assertIsNotNone(andni)
        self.assertIn("ANDI", andni.metadata["aliases"])
        immediate = andni.metadata["immediate_fields"][0]
        self.assertIn("ones-complement", immediate["alias_encoding"])

    def test_clr_is_the_constrained_xor_same_register_alias(self) -> None:
        xor = self.database.decode(0x5600)
        self.assertIsNotNone(xor)
        self.assertEqual(xor.mnemonic, "XOR")
        self.assertEqual(
            xor.metadata["aliases"],
            ["CLR when source and destination register numbers are equal"],
        )
        for register_file_bit in (0x0000, 0x0010):
            for register_index in range(16):
                with self.subTest(
                    register_file_bit=register_file_bit,
                    register_index=register_index,
                ):
                    clr_word = (
                        0x5600
                        | register_file_bit
                        | (register_index << 5)
                        | register_index
                    )
                    self.assertIs(self.database.decode(clr_word), xor)
        self.assertIs(self.database.decode(0x5620), xor)
        self.assertNotEqual((0x5620 >> 5) & 0xF, 0x5620 & 0xF)

    def test_addi_encoding_forms_retain_ti_mnemonic_and_widths(self) -> None:
        short = self.database.decode(0x0B00)
        long = self.database.decode(0x0B20)
        self.assertEqual(short.metadata["aliases"], ["ADDI"])
        self.assertEqual(long.metadata["aliases"], ["ADDI"])
        self.assertEqual(short.metadata["immediate_fields"][0]["width"], 16)
        self.assertTrue(short.metadata["immediate_fields"][0]["signed"])
        self.assertEqual(long.metadata["immediate_fields"][0]["width"], 32)
        self.assertTrue(long.metadata["immediate_fields"][0]["signed"])

    def test_subi_encoding_forms_record_complemented_object_words(self) -> None:
        short = self.database.decode(0x0BE0)
        long = self.database.decode(0x0D00)
        self.assertEqual(short.metadata["aliases"], ["SUBI"])
        self.assertEqual(long.metadata["aliases"], ["SUBI"])
        self.assertEqual(short.metadata["immediate_fields"][0]["width"], 16)
        self.assertTrue(short.metadata["immediate_fields"][0]["signed"])
        self.assertEqual(long.metadata["immediate_fields"][0]["width"], 32)
        self.assertTrue(long.metadata["immediate_fields"][0]["signed"])
        for instruction in (short, long):
            self.assertEqual(
                instruction.metadata["immediate_fields"][0][
                    "object_encoding"
                ],
                "ones_complement_of_source_immediate",
            )

    def test_cmpi_encoding_forms_are_nondestructive_and_complemented(self) -> None:
        short = self.database.decode(0x0B40)
        long = self.database.decode(0x0B60)
        self.assertEqual(short.metadata["aliases"], ["CMPI"])
        self.assertEqual(long.metadata["aliases"], ["CMPI"])
        self.assertEqual(short.metadata["immediate_fields"][0]["width"], 16)
        self.assertTrue(short.metadata["immediate_fields"][0]["signed"])
        self.assertEqual(long.metadata["immediate_fields"][0]["width"], 32)
        self.assertTrue(long.metadata["immediate_fields"][0]["signed"])
        for instruction in (short, long):
            self.assertEqual(instruction.metadata["destination_registers"], [])
            self.assertEqual(
                instruction.metadata["immediate_fields"][0][
                    "object_encoding"
                ],
                "ones_complement_of_source_immediate",
            )

    def test_addk_canonicalizes_inc_alias_and_encoded_zero(self) -> None:
        addk_32 = self.database.decode(0x1000)
        inc_alias = self.database.decode(0x1020)
        self.assertEqual(addk_32.mnemonic, "ADDK")
        self.assertIs(addk_32, inc_alias)
        self.assertEqual(addk_32.metadata["aliases"], ["INC when K=1"])
        immediate = addk_32.metadata["immediate_fields"][0]
        self.assertEqual(immediate["width"], 5)
        self.assertFalse(immediate["signed"])
        self.assertEqual(immediate["zero_encoding"], 32)

    def test_subk_canonicalizes_dec_alias_and_encoded_zero(self) -> None:
        subk_32 = self.database.decode(0x1400)
        dec_alias = self.database.decode(0x1420)
        self.assertEqual(subk_32.mnemonic, "SUBK")
        self.assertIs(subk_32, dec_alias)
        self.assertEqual(subk_32.metadata["aliases"], ["DEC when K=1"])
        immediate = subk_32.metadata["immediate_fields"][0]
        self.assertEqual(immediate["width"], 5)
        self.assertFalse(immediate["signed"])
        self.assertEqual(immediate["zero_encoding"], 32)

    def test_movk_metadata_and_encoded_zero(self) -> None:
        movk_32 = self.database.decode(0x1800)
        movk_1 = self.database.decode(0x1820)
        self.assertEqual(movk_32.mnemonic, "MOVK")
        self.assertIs(movk_32, movk_1)
        self.assertEqual(movk_32.metadata["status_bits_written"], [])
        immediate = movk_32.metadata["immediate_fields"][0]
        self.assertEqual(immediate["width"], 5)
        self.assertFalse(immediate["signed"])
        self.assertEqual(immediate["zero_encoding"], 32)

    def test_movi_forms_record_width_status_and_alignment(self) -> None:
        short = self.database.decode(0x09C0)
        long = self.database.decode(0x09E0)
        self.assertEqual(short.metadata["aliases"], ["MOVI"])
        self.assertEqual(long.metadata["aliases"], ["MOVI"])
        self.assertEqual(short.metadata["immediate_fields"][0]["width"], 16)
        self.assertTrue(short.metadata["immediate_fields"][0]["signed"])
        self.assertEqual(long.metadata["immediate_fields"][0]["width"], 32)
        self.assertTrue(long.metadata["immediate_fields"][0]["signed"])
        for instruction in (short, long):
            self.assertEqual(
                instruction.metadata["status_bits_written"],
                ["N", "Z", "V"],
            )
            self.assertNotIn(
                "C", instruction.metadata["status_bits_written"]
            )

    def test_movx_movy_are_same_file_status_neutral_half_moves(self) -> None:
        for opcode, mnemonic, half in (
            (0xEC00, "MOVX", "X half"),
            (0xEE00, "MOVY", "Y half"),
        ):
            instruction = self.database.decode(opcode)
            self.assertEqual(instruction.mnemonic, mnemonic)
            self.assertIn("same file", instruction.metadata["register_file"])
            self.assertEqual(instruction.metadata["status_bits_written"], [])
            self.assertEqual(
                instruction.metadata["destination_registers"],
                [f"Rd {half}"],
            )
            self.assertEqual(
                instruction.metadata["documented_cycles"]["machine_states"],
                1,
            )

    def test_move_records_cross_file_and_implicit_compare(self) -> None:
        same_file = self.database.decode(0x4C01)
        cross_file = self.database.decode(0x4E01)
        self.assertEqual(same_file.mnemonic, "MOVE")
        self.assertEqual(cross_file.mnemonic, "MOVE")
        self.assertIn("destination is R when M=0",
                      same_file.metadata["register_file"])
        self.assertEqual(
            same_file.metadata["status_bits_written"],
            ["N", "Z", "V"],
        )
        self.assertEqual(
            same_file.metadata["documented_cycles"]["machine_states"],
            1,
        )

    def test_move_register_to_memory_records_field_and_pipeline_contract(self) -> None:
        instruction = self.database.decode(0x8000)
        self.assertIsNotNone(instruction)
        self.assertEqual(instruction.mnemonic, "MOVE.RM")
        self.assertEqual(instruction.opcode_mask, 0xFC00)
        self.assertEqual(instruction.opcode_value, 0x8000)
        self.assertEqual(instruction.length_words, 1)
        self.assertEqual(
            instruction.metadata["documented_cycles"],
            {
                "kind": "field_alignment_cases",
                "visible_machine_states": 1,
                "little_endian_hidden_write_states": {
                    "case_1": 1,
                    "case_2": 2,
                    "case_3": 2,
                    "case_4": 3,
                    "case_5": 4,
                },
                "big_endian_visible_machine_states": 2,
                "big_endian_hidden_write_states": {
                    "case_1": 1,
                    "case_2": 2,
                    "case_3": 2,
                    "case_4": 3,
                    "case_5": 4,
                },
            },
        )
        self.assertEqual(instruction.metadata["status_bits_written"], [])
        self.assertTrue(instruction.metadata["compatible_with_tms34010"])

    def test_move_memory_to_register_records_extension_and_timing_contract(self) -> None:
        instruction = self.database.decode(0x8400)
        self.assertIsNotNone(instruction)
        self.assertEqual(instruction.mnemonic, "MOVE.MR")
        self.assertEqual(instruction.opcode_mask, 0xFC00)
        self.assertEqual(instruction.opcode_value, 0x8400)
        self.assertEqual(instruction.length_words, 1)
        self.assertEqual(
            instruction.metadata["documented_cycles"],
            {
                "kind": "field_alignment_cases",
                "zero_extended_visible_machine_states": {
                    "case_1": 3,
                    "case_2": 3,
                    "case_3": 4,
                    "case_4": 4,
                    "case_5": 4,
                },
                "sign_extended_visible_machine_states": {
                    "case_1": 4,
                    "case_2": 4,
                    "case_3": 5,
                    "case_4": 5,
                    "case_5": 5,
                },
            },
        )
        self.assertEqual(
            instruction.metadata["status_bits_written"], ["N", "Z", "V"]
        )
        self.assertTrue(instruction.metadata["compatible_with_tms34010"])

    def test_move_memory_to_memory_records_two_sided_timing_contract(self) -> None:
        instruction = self.database.decode(0x8800)
        self.assertIsNotNone(instruction)
        self.assertEqual(instruction.mnemonic, "MOVE.MM")
        self.assertEqual(instruction.opcode_mask, 0xFC00)
        self.assertEqual(instruction.opcode_value, 0x8800)
        self.assertEqual(instruction.length_words, 1)
        self.assertEqual(
            instruction.metadata["documented_cycles"],
            {
                "kind": "source_destination_field_alignment",
                "visible_machine_states_by_source_case": {
                    "case_1": 3,
                    "case_2": 3,
                    "case_3": 4,
                    "case_4": 4,
                    "case_5": 4,
                },
                "hidden_write_states_by_destination_case": {
                    "case_1": 1,
                    "case_2": 2,
                    "case_3": 2,
                    "case_4": 3,
                    "case_5": 4,
                },
            },
        )
        self.assertEqual(instruction.metadata["status_bits_written"], [])
        self.assertTrue(instruction.metadata["compatible_with_tms34010"])

    def test_rl_forms_record_count_source_and_partial_status_update(self) -> None:
        constant = self.database.decode(0x3001)
        register = self.database.decode(0x6801)
        self.assertEqual(constant.mnemonic, "RL.K")
        self.assertEqual(register.mnemonic, "RL.R")
        self.assertEqual(
            constant.metadata["immediate_fields"][0]["zero_encoding"], 0
        )
        self.assertIn("same file", register.metadata["register_file"])
        for instruction in (constant, register):
            self.assertEqual(
                instruction.metadata["status_bits_written"], ["C", "Z"]
            )
            self.assertEqual(
                instruction.metadata["documented_cycles"]["machine_states"],
                1,
            )


if __name__ == "__main__":
    unittest.main()
