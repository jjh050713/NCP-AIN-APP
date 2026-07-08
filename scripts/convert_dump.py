#!/usr/bin/env python3
"""Convert simple text dump format to NCP-AIN app JSON.

Input format (per question block):
---
CATEGORY: Spectrum Networking
Q: Question text here?
A) Choice 1
B) Choice 2
C) Choice 3
D) Choice 4
ANSWER: B
---

Usage:
  python3 scripts/convert_dump.py input.txt -o output.json
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path

CATEGORY_MAP = {
    "ai data center": "AI Data Center Design",
    "ai data center design": "AI Data Center Design",
    "spectrum": "Spectrum Networking",
    "spectrum networking": "Spectrum Networking",
    "infiniband": "InfiniBand Networking",
    "infiniband networking": "InfiniBand Networking",
    "kubernetes": "Kubernetes Integration",
    "k8s": "Kubernetes Integration",
    "troubleshooting": "Troubleshooting Tools",
    "automation": "Automation & Configuration",
}

ANSWER_MAP = {"A": 0, "B": 1, "C": 2, "D": 3, "E": 4, "F": 5}


def parse_blocks(text: str) -> list[dict]:
    blocks = [b.strip() for b in re.split(r"\n---+\n", text) if b.strip()]
    questions: list[dict] = []

    for i, block in enumerate(blocks, start=1):
        category = "Spectrum Networking"
        question = ""
        choices: list[str] = []
        correct_index = 0

        for line in block.splitlines():
            line = line.strip()
            if not line:
                continue
            upper = line.upper()
            if upper.startswith("CATEGORY:"):
                raw = line.split(":", 1)[1].strip().lower()
                category = CATEGORY_MAP.get(raw, line.split(":", 1)[1].strip())
            elif upper.startswith("Q:"):
                question = line.split(":", 1)[1].strip()
            elif re.match(r"^[A-F]\)", line, re.I):
                choices.append(re.sub(r"^[A-F]\)\s*", "", line, flags=re.I))
            elif upper.startswith("ANSWER:"):
                ans = line.split(":", 1)[1].strip().upper()
                if ans.isdigit():
                    correct_index = int(ans)
                else:
                    correct_index = ANSWER_MAP.get(ans[:1], 0)

        if question and len(choices) >= 2:
            questions.append(
                {
                    "id": f"dump-{i:04d}",
                    "category": category,
                    "question": question,
                    "choices": choices,
                    "correctIndex": correct_index,
                    "source": "Dump",
                }
            )

    return questions


def main() -> int:
    parser = argparse.ArgumentParser(description="Convert text dump to NCP-AIN JSON")
    parser.add_argument("input", type=Path, help="Input text file")
    parser.add_argument("-o", "--output", type=Path, default=Path("dump_import.json"))
    args = parser.parse_args()

    text = args.input.read_text(encoding="utf-8")
    questions = parse_blocks(text)

    payload = {"version": "1.0", "questions": questions}
    args.output.write_text(json.dumps(payload, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"Converted {len(questions)} questions -> {args.output}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
