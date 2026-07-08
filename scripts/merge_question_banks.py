#!/usr/bin/env python3
"""Merge dump, practice, and official topic questions into one bank."""

from __future__ import annotations

import argparse
import json
import re
from collections import Counter
from pathlib import Path


def normalize_text(text: str) -> str:
    return re.sub(r"\s+", " ", text.strip().lower())


def migrate_question(raw: dict) -> dict:
    """Normalize legacy correctIndex format to correctIndices."""
    if "correctIndices" in raw:
        indices = raw["correctIndices"]
    else:
        indices = [raw["correctIndex"]]

    labels = ["A", "B", "C", "D", "E", "F"]
    answer_key = raw.get("answerKey")
    if not answer_key and indices:
        answer_key = "".join(
            labels[i] for i in indices if i < len(labels)
        )

    is_multi = raw.get("isMultiSelect", len(indices) > 1)

    return {
        "id": raw["id"],
        "category": raw["category"],
        "question": raw["question"],
        "choices": raw["choices"],
        "correctIndices": indices,
        "answerKey": answer_key,
        "isMultiSelect": is_multi,
        "source": raw["source"],
    }


def deduplicate(questions: list[dict]) -> list[dict]:
    seen: set[str] = set()
    unique: list[dict] = []

    # Dump questions first (higher priority)
    ordered = sorted(
        questions,
        key=lambda q: (0 if q["source"] == "Dump" else 1, q["id"]),
    )

    for item in ordered:
        key = normalize_text(item["question"])
        if key in seen:
            continue
        seen.add(key)
        unique.append(item)

    return unique


def load_bank(path: Path) -> list[dict]:
    payload = json.loads(path.read_text(encoding="utf-8"))
    return [migrate_question(q) for q in payload.get("questions", [])]


def main() -> int:
    parser = argparse.ArgumentParser(description="Merge multiple question banks")
    parser.add_argument("inputs", nargs="+", type=Path, help="Question bank JSON files")
    parser.add_argument(
        "-o",
        "--output",
        type=Path,
        default=Path("NCPAINApp/NCPAINApp/Resources/questions.json"),
    )
    args = parser.parse_args()

    merged: list[dict] = []
    for path in args.inputs:
        merged.extend(load_bank(path))

    unique = deduplicate(merged)
    result = {
        "version": "2.1.0",
        "questions": unique,
    }

    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(result, ensure_ascii=False, indent=2), encoding="utf-8")

    sources = Counter(q["source"] for q in unique)
    categories = Counter(q["category"] for q in unique)
    multi = sum(1 for q in unique if q["isMultiSelect"])

    print(f"Merged {len(unique)} unique questions ({multi} multi-select)")
    for source, count in sorted(sources.items()):
        print(f"  [{source}] {count}")
    for category, count in sorted(categories.items()):
        print(f"  - {category}: {count}")
    print(f"Written to {args.output}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
