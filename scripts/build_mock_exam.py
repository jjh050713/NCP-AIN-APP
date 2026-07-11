#!/usr/bin/env python3
"""Build the mock exam bank from the merged question bank's Dump questions.

The mock exam pool is exactly the "기출" (Dump-source) questions already
shown by 암기 mode's dump filter — reusing them directly (rather than
re-deriving from a raw dump file) guarantees the two modes always show
byte-identical question/choice/answer content, with no risk of the
extraction-artifact corruption we previously had to repair by hand.
"""

from __future__ import annotations

import json
from pathlib import Path

SOURCE = Path("web/data/questions.json")
OUTPUTS = [
    Path("web/data/exam180.json"),
    Path("NCPAINApp/NCPAINApp/Resources/exam180.json"),
]


def main() -> int:
    payload = json.loads(SOURCE.read_text(encoding="utf-8"))
    dump_questions = [q for q in payload["questions"] if q.get("source") == "Dump"]

    if not dump_questions:
        raise SystemExit("No Dump-source questions found in the merged bank")

    result = {
        "version": "2.0.0",
        "title": f"NCP-AIN 모의고사 (기출 {len(dump_questions)}제)",
        "questions": dump_questions,
    }

    for output in OUTPUTS:
        output.parent.mkdir(parents=True, exist_ok=True)
        output.write_text(
            json.dumps(result, ensure_ascii=False, indent=2), encoding="utf-8"
        )
        print(f"Written {len(dump_questions)} questions to {output}")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
