"""Load and query the primary-source TMS34020 ISA database."""

from __future__ import annotations

import json
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Iterable

ROOT = Path(__file__).resolve().parents[2]
DEFAULT_DATABASE = ROOT / "docs/generated/tms34020_isa.yaml"


class IsaDatabaseError(ValueError):
    """The ISA database is malformed or ambiguous."""


@dataclass(frozen=True)
class Instruction:
    """Validated decode fields plus the original metadata mapping."""

    mnemonic: str
    opcode_mask: int
    opcode_value: int
    length_words: int
    metadata: dict[str, Any]

    def matches(self, first_word: int) -> bool:
        """Return whether a 16-bit first word selects this entry."""

        if not 0 <= first_word <= 0xFFFF:
            raise ValueError("first_word must fit in 16 bits")
        return (first_word & self.opcode_mask) == self.opcode_value


class IsaDatabase:
    """A deterministic ordered set of non-overlapping instruction patterns."""

    def __init__(self, document: dict[str, Any]) -> None:
        self.document = document
        self.instructions = tuple(self._parse_entries(document))
        self._validate_first_word_space()

    @classmethod
    def load(cls, path: Path = DEFAULT_DATABASE) -> "IsaDatabase":
        return cls(json.loads(path.read_text(encoding="utf-8")))

    @staticmethod
    def _parse_entries(document: dict[str, Any]) -> Iterable[Instruction]:
        if document.get("schema_version") != 1:
            raise IsaDatabaseError("unsupported ISA schema_version")
        entries = document.get("instructions")
        if not isinstance(entries, list) or not entries:
            raise IsaDatabaseError("instructions must be a nonempty list")
        seen_mnemonics: set[str] = set()
        for raw in entries:
            mnemonic = raw.get("mnemonic")
            if not isinstance(mnemonic, str) or not mnemonic:
                raise IsaDatabaseError("each instruction needs a mnemonic")
            if mnemonic in seen_mnemonics:
                raise IsaDatabaseError(f"duplicate mnemonic: {mnemonic}")
            seen_mnemonics.add(mnemonic)
            try:
                mask = int(raw["opcode_mask"], 0)
                value = int(raw["opcode_value"], 0)
                length = int(raw["instruction_length_words"])
            except (KeyError, TypeError, ValueError) as error:
                raise IsaDatabaseError(f"bad decode fields for {mnemonic}") from error
            if not 0 <= mask <= 0xFFFF or not 0 <= value <= 0xFFFF:
                raise IsaDatabaseError(f"decode field out of range for {mnemonic}")
            if value & ~mask:
                raise IsaDatabaseError(
                    f"{mnemonic} value sets a bit outside its mask"
                )
            if not 1 <= length <= 5:
                raise IsaDatabaseError(f"bad length for {mnemonic}: {length}")
            yield Instruction(mnemonic, mask, value, length, raw)

    def _validate_first_word_space(self) -> None:
        for first_word in range(0x10000):
            matches = [
                instruction.mnemonic
                for instruction in self.instructions
                if instruction.matches(first_word)
            ]
            if len(matches) > 1:
                raise IsaDatabaseError(
                    f"decode collision at {first_word:04X}: {', '.join(matches)}"
                )

    def decode(self, first_word: int) -> Instruction | None:
        matches = [
            instruction
            for instruction in self.instructions
            if instruction.matches(first_word)
        ]
        if len(matches) > 1:
            raise IsaDatabaseError(f"ambiguous decode at {first_word:04X}")
        return matches[0] if matches else None

    def coverage(self) -> tuple[int, int]:
        """Return matched and currently-unclassified first-word counts."""

        matched = sum(self.decode(word) is not None for word in range(0x10000))
        return matched, 0x10000 - matched
