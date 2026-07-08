#!/usr/bin/env python3
"""Convert NCP-AIN EXAM dump JSON (HWP extraction format) to app question bank."""

from __future__ import annotations

import argparse
import json
import re
from collections import Counter
from pathlib import Path

from convert_user_dump import categorize, normalize_text, parse_answer

ANSWER_MAP = {"A": 0, "B": 1, "C": 2, "D": 3, "E": 4, "F": 5}


def parse_answer_list(answer: list[str] | str, choice_count: int) -> tuple[list[int], str, bool]:
    if isinstance(answer, str):
        return parse_answer(answer, choice_count)

    labels = [a.strip().upper() for a in answer if a.strip()]
    indices: list[int] = []
    for label in labels:
        if label in ANSWER_MAP:
            index = ANSWER_MAP[label]
            if index < choice_count and index not in indices:
                indices.append(index)

    if not indices:
        return [0], "A", False

    answer_key = "".join(labels)
    return indices, answer_key, len(indices) > 1


def extract_questions(payload: dict) -> list[dict]:
    source_file = payload.get("source_file", "unknown")
    extracted: list[dict] = []

    for item in payload.get("questions", []):
        question_text = item.get("question", "").strip()
        if not question_text:
            continue

        options = item.get("options", [])
        if not options:
            continue

        if isinstance(options, dict):
            ordered_keys = sorted(options.keys())
            choices = [options[key] for key in ordered_keys]
        else:
            ordered = sorted(options, key=lambda o: o.get("key", ""))
            choices = [o.get("text", "") for o in ordered]

        choices = [c for c in choices if c]
        if len(choices) < 2:
            continue

        answer = item.get("answer", ["A"])
        indices, answer_key, is_multi = parse_answer_list(answer, len(choices))

        extracted.append(
            {
                "number": item.get("source_number", item.get("id", len(extracted) + 1)),
                "source_file": source_file,
                "question_text": question_text,
                "choices": choices,
                "correctIndices": indices,
                "answerKey": answer_key,
                "isMultiSelect": is_multi,
            }
        )

    return extracted


def to_app_question(item: dict, index: int) -> dict:
    slug = re.sub(r"[^a-z0-9]+", "-", normalize_text(item["question_text"]))[:48].strip("-")
    question_id = f"dump-hwp-{index:03d}-{slug or index}"

    return {
        "id": question_id,
        "category": categorize(item["question_text"]),
        "question": item["question_text"],
        "choices": item["choices"],
        "correctIndices": item["correctIndices"],
        "answerKey": item["answerKey"],
        "isMultiSelect": item["isMultiSelect"],
        "source": "Dump",
    }


def convert(payload: dict) -> dict:
    raw = extract_questions(payload)
    app_questions = [to_app_question(item, i + 1) for i, item in enumerate(raw)]

    return {
        "version": "2.0.0",
        "generatedFrom": [payload.get("source_file", "unknown")],
        "questions": app_questions,
    }


def main() -> int:
    parser = argparse.ArgumentParser(description="Convert HWP EXAM dump JSON to app format")
    parser.add_argument("input", type=Path, help="Source EXAM dump JSON file")
    parser.add_argument(
        "-o",
        "--output",
        type=Path,
        default=Path("/tmp/dump_hwp120.json"),
    )
    args = parser.parse_args()

    payload = json.loads(args.input.read_text(encoding="utf-8"))
    result = convert(payload)
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(result, ensure_ascii=False, indent=2), encoding="utf-8")

    multi = sum(1 for q in result["questions"] if q["isMultiSelect"])
    print(f"Converted {len(result['questions'])} questions ({multi} multi-select)")
    counts = Counter(q["category"] for q in result["questions"])
    for category, count in sorted(counts.items()):
        print(f"  - {category}: {count}")
    print(f"Written to {args.output}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
