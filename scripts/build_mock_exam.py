#!/usr/bin/env python3
"""Build the 120-question mock exam bank from the HWP exam dump.

The source file (`3.NCP-AIN-EXAM-정리(120문제 덤프).hwp`) was extracted with
150 numbered items plus one duplicate (source_number 99 appears twice),
for 151 raw entries. Numbers 121-150 are extraction artifacts beyond the
document's own "120문제" scope, so the real mock-exam set is exactly the
120 unique items numbered 1-120 (keeping the first occurrence of any
duplicate number).
"""

from __future__ import annotations

import json
import re
from collections import Counter
from pathlib import Path

from convert_exam_dump import parse_answer_list
from convert_user_dump import categorize, extract_questions, normalize_text

SOURCE = Path("dumps/ncp_ain_exam_120.json")
KOREA_SOURCE = Path("dumps/source_dump.json")
OUTPUTS = [
    Path("web/data/exam120.json"),
    Path("NCPAINApp/NCPAINApp/Resources/exam120.json"),
]
EXAM_SIZE = 120

# The HWP extraction glued a couple of options together (e.g. one choice's
# text literally contains "... D. BGP", swallowing the next option), which
# looks like a real, embedded option label ("B. ", "C. ", etc.) in the
# middle of another choice's text.
CORRUPTION_PATTERN = re.compile(r"\s[B-F]\.\s")


def load_korea_lookup() -> dict[str, dict]:
    """Normalized question text -> cleaned Korea-dump question, used to
    repair HWP items whose options were corrupted during extraction."""
    if not KOREA_SOURCE.exists():
        return {}
    payload = json.loads(KOREA_SOURCE.read_text(encoding="utf-8"))
    return {normalize_text(item["question_text"]): item for item in extract_questions(payload)}


def is_corrupted(choices: list[str]) -> bool:
    return any(CORRUPTION_PATTERN.search(choice) for choice in choices)


def extract_first_120(payload: dict) -> list[dict]:
    seen_numbers: set[int] = set()
    items: list[dict] = []
    for item in payload.get("questions", []):
        number = item.get("source_number")
        if number is None or number > EXAM_SIZE or number in seen_numbers:
            continue
        seen_numbers.add(number)
        items.append(item)
    items.sort(key=lambda item: item["source_number"])
    return items


def to_app_question(item: dict, index: int, korea_lookup: dict[str, dict]) -> dict:
    question_text = item["question"].strip()
    options = item.get("options", [])
    ordered = sorted(options, key=lambda o: o.get("key", ""))
    choices = [o.get("text", "") for o in ordered if o.get("text")]

    answer = item.get("answer", ["A"])
    indices, answer_key, is_multi = parse_answer_list(answer, len(choices))

    korea_match = korea_lookup.get(normalize_text(question_text))
    if korea_match:
        # Prefer the manually-transcribed Korea dump's choices whenever the
        # same question exists there too — it's what 암기 mode already shows
        # for this text (dedup keeps the Korea copy), and it fixes HWP OCR
        # artifacts (stray line breaks, en-dashes, missing periods) even
        # when they're too subtle to flag as outright corruption.
        if choices != korea_match["choices"]:
            tag = "repaired" if is_corrupted(choices) else "aligned"
            print(f"  [{tag}] #{item['source_number']}: {question_text[:60]!r}")
        choices = korea_match["choices"]
        indices = korea_match["correctIndices"]
        answer_key = korea_match["answerKey"]
        is_multi = korea_match["isMultiSelect"]
    elif is_corrupted(choices):
        print(f"  [WARNING] corrupted options with no fix available: #{item['source_number']}: {question_text[:60]!r}")

    slug = normalize_text(question_text)
    slug = "".join(c if c.isalnum() else "-" for c in slug)
    while "--" in slug:
        slug = slug.replace("--", "-")
    slug = slug.strip("-")[:40]

    return {
        "id": f"exam120-{index:03d}-{slug or index}",
        "category": categorize(question_text),
        "question": question_text,
        "choices": choices,
        "correctIndices": indices,
        "answerKey": answer_key,
        "isMultiSelect": is_multi,
        "source": "Dump",
    }


def main() -> int:
    payload = json.loads(SOURCE.read_text(encoding="utf-8"))
    raw_items = extract_first_120(payload)

    if len(raw_items) != EXAM_SIZE:
        raise SystemExit(
            f"Expected {EXAM_SIZE} unique numbered questions, got {len(raw_items)}"
        )

    korea_lookup = load_korea_lookup()
    questions = [to_app_question(item, i + 1, korea_lookup) for i, item in enumerate(raw_items)]

    result = {
        "version": "1.0.0",
        "title": "NCP-AIN 모의고사 (기출 120제)",
        "questions": questions,
    }

    for output in OUTPUTS:
        output.parent.mkdir(parents=True, exist_ok=True)
        output.write_text(
            json.dumps(result, ensure_ascii=False, indent=2), encoding="utf-8"
        )
        print(f"Written {len(questions)} questions to {output}")

    multi = sum(1 for q in questions if q["isMultiSelect"])
    print(f"Multi-select questions: {multi}")
    counts = Counter(q["category"] for q in questions)
    for category, count in sorted(counts.items()):
        print(f"  - {category}: {count}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
