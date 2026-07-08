#!/usr/bin/env python3
"""Convert shared NCP-AIN dump JSON to app question bank format."""

from __future__ import annotations

import argparse
import json
import re
from collections import Counter
from pathlib import Path

ANSWER_MAP = {"A": 0, "B": 1, "C": 2, "D": 3, "E": 4, "F": 5}

CATEGORY_RULES: list[tuple[str, list[str]]] = [
    (
        "Kubernetes Integration",
        [
            "kubernetes",
            "network operator",
            "nicclusterpolicy",
            "multus",
            "gpu operator",
            "k8s",
        ],
    ),
    (
        "Automation & Configuration",
        [
            "ansible",
            "nvue",
            "playbook",
            "nv set",
            "nv config",
            "upgrade cumulus",
            "bond in cumulus",
            "collection roles",
        ],
    ),
    (
        "Troubleshooting Tools",
        [
            "troubleshoot",
            "ibdiagnet",
            "ibstat",
            "ibping",
            "mlxlink",
            "wjh",
            "what just happened",
            "ib_write",
            "ibnetdiscover",
            "sminfo",
            "smpquery",
            "perfquery",
            "cl-resource",
            "microburst",
            "connectivity issue",
            "link flapping",
        ],
    ),
    (
        "InfiniBand Networking",
        [
            "infiniband",
            "ufm",
            "pkey",
            "partition key",
            "subnet manager",
            "mlnx",
            "ib router",
            "sharp",
            "nccl",
            "lrh",
            "ibpath",
            "mellanox infiniband",
            "mlnx_ofed",
            "mlnx-os",
            "ibnodes",
            "ibswitches",
            "minhop",
            "updown",
            "fat tree",
        ],
    ),
    (
        "Spectrum Networking",
        [
            "spectrum",
            "roce",
            "netq",
            "cumulus",
            "bgp-evpn",
            "evpn multi-homing",
            "vrf",
            "l3vni",
            "supernic",
            "doca",
            "pfc",
            "ecn",
            "nvidia air",
            "soniс",
            "sonic",
            "sn5600",
            "sn4700",
            "adaptive routing",
            "flow analysis",
            "mlnx-os led",
            "onyx software",
        ],
    ),
    (
        "AI Data Center Design",
        [
            "rail-optimized",
            "dgx",
            "ai factory",
            "nvlink",
            "bluefield",
            "topology",
            "ai data center",
            "scalable unit",
            "gpu-to-gpu",
            "cloudai benchmark",
            "superpod",
            "storage fabric",
            "magnum io",
        ],
    ),
]


def normalize_text(text: str) -> str:
    return re.sub(r"\s+", " ", text.strip().lower())


def categorize(question_text: str) -> str:
    text = question_text.lower()
    for category, keywords in CATEGORY_RULES:
        if any(keyword in text for keyword in keywords):
            return category
    return "Spectrum Networking"


def parse_answer(answer: str, choice_count: int) -> tuple[list[int], str, bool]:
    cleaned = answer.strip().upper().replace(",", "").replace(" ", "")
    if not cleaned:
        return [0], "A", False

    if cleaned.isdigit():
        index = int(cleaned)
        if 0 <= index < choice_count:
            labels = "".join(chr(ord("A") + index) for index in [index])
            return [index], labels, False
        return [0], "A", False

    indices: list[int] = []
    labels: list[str] = []
    for char in cleaned:
        if char in ANSWER_MAP:
            index = ANSWER_MAP[char]
            if index < choice_count and index not in indices:
                indices.append(index)
                labels.append(char)

    if not indices:
        return [0], "A", False

    return indices, "".join(labels), len(indices) > 1


def extract_questions(payload: list[dict]) -> list[dict]:
    extracted: list[dict] = []

    for entry in payload:
        content = entry.get("content", {})
        questions = content.get("questions")
        if not questions:
            continue

        source_file = entry.get("file_name", "unknown")
        for item in questions:
            options = item.get("options", {})
            if not options:
                continue

            ordered_keys = sorted(options.keys())
            choices = [options[key] for key in ordered_keys]
            answer = str(item.get("answer", "A"))
            indices, answer_key, is_multi = parse_answer(answer, len(choices))

            question_text = item.get("question_text", "").strip()
            if not question_text:
                continue

            number = item.get("number", len(extracted) + 1)
            extracted.append(
                {
                    "number": number,
                    "source_file": source_file,
                    "question_text": question_text,
                    "choices": choices,
                    "correctIndices": indices,
                    "answerKey": answer_key,
                    "isMultiSelect": is_multi,
                }
            )

    return extracted


def deduplicate(questions: list[dict]) -> list[dict]:
    seen: set[str] = set()
    unique: list[dict] = []

    for item in questions:
        key = normalize_text(item["question_text"])
        if key in seen:
            continue
        seen.add(key)
        unique.append(item)

    return unique


def to_app_question(item: dict, index: int) -> dict:
    slug = re.sub(r"[^a-z0-9]+", "-", normalize_text(item["question_text"]))[:48].strip("-")
    question_id = f"dump-{index:03d}-{slug or index}"

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


def convert(payload: list[dict]) -> dict:
    raw = extract_questions(payload)
    unique = deduplicate(raw)
    app_questions = [to_app_question(item, i + 1) for i, item in enumerate(unique)]

    return {
        "version": "2.0.0",
        "generatedFrom": [
            entry.get("file_name", "unknown")
            for entry in payload
            if entry.get("content", {}).get("questions")
        ],
        "questions": app_questions,
    }


def main() -> int:
    parser = argparse.ArgumentParser(description="Convert shared dump JSON to app format")
    parser.add_argument("input", type=Path, help="Source dump JSON file")
    parser.add_argument(
        "-o",
        "--output",
        type=Path,
        default=Path("NCPAINApp/NCPAINApp/Resources/questions.json"),
    )
    args = parser.parse_args()

    payload = json.loads(args.input.read_text(encoding="utf-8"))
    result = convert(payload)
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(result, ensure_ascii=False, indent=2), encoding="utf-8")

    multi = sum(1 for q in result["questions"] if q["isMultiSelect"])
    print(f"Converted {len(result['questions'])} unique questions ({multi} multi-select)")
    counts = Counter(q["category"] for q in result["questions"])
    for category, count in sorted(counts.items()):
        print(f"  - {category}: {count}")
    print(f"Written to {args.output}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
