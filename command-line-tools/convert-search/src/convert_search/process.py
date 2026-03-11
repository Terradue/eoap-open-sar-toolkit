import json
import re
from pathlib import Path
from urllib.parse import unquote


PRODUCT_NAME_PATTERN = re.compile(r"Name eq '([^']+)\.SAFE'")


def extract_candidate_ids(search_results: dict) -> list[str]:
    candidates = []

    for feature in search_results.get("features", []):
        for link in feature.get("links", []):
            if link.get("rel") != "derived_from":
                continue

            href = link.get("href", "")
            match = PRODUCT_NAME_PATTERN.search(unquote(href))
            if match:
                candidates.append(match.group(1))

    return candidates


def select_best_candidate(candidates: list[str], target_datetime: str) -> list[str]:
    target_day = target_datetime[:10].replace("-", "")

    for candidate in candidates:
        if f"_{target_day}T" in candidate:
            return [candidate]

    return [candidates[0]] if candidates else []


def convert_search_results(
    search_results_path: Path, target_datetime: str
) -> list[str]:
    search_results = json.loads(search_results_path.read_text(encoding="utf-8"))
    candidates = extract_candidate_ids(search_results)
    return select_best_candidate(candidates, target_datetime)
