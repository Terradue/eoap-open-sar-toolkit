import json
import re
from pathlib import Path
from urllib.parse import unquote
from shapely.geometry import box, shape
from datetime import datetime, timezone

PRODUCT_NAME_PATTERN = re.compile(r"Name eq '([^']+)\.SAFE'")


def parse_target_datetime(target_datetime: str) -> datetime:
    dt = datetime.fromisoformat(target_datetime.replace("Z", "+00:00"))
    if dt.tzinfo is None:
        dt = dt.replace(tzinfo=timezone.utc)
    return dt


def parse_input_bbox(input_bbox: str) -> tuple[float, float, float, float]:
    parts = [float(x.strip()) for x in input_bbox.split(",")]
    if len(parts) != 4:
        raise ValueError(
            "input_bbox must be a comma-separated string: minx,miny,maxx,maxy"
        )

    minx, miny, maxx, maxy = parts
    if minx >= maxx or miny >= maxy:
        raise ValueError(f"Invalid bbox: {input_bbox}")

    return minx, miny, maxx, maxy

def extract_candidate_id(feature: dict) -> str | None:
    for link in feature.get("links", []):
        if link.get("rel") != "derived_from":
            continue

        href = link.get("href", "")
        match = PRODUCT_NAME_PATTERN.search(unquote(href))
        if match:
            return match.group(1)

    return None


def extract_processing_datetime(feature: dict) -> datetime | None:
    props = feature.get("properties", {})
    dt_str = props.get("processing:datetime")
    if not dt_str:
        return None

    dt = datetime.fromisoformat(dt_str.replace("Z", "+00:00"))
    if dt.tzinfo is None:
        dt = dt.replace(tzinfo=timezone.utc)
    return dt


def compute_bbox_coverage_pct(feature: dict, input_bbox: str) -> float:
    minx, miny, maxx, maxy = parse_input_bbox(input_bbox)

    user_geom = box(minx, miny, maxx, maxy)
    user_area = user_geom.area
    if user_area <= 0:
        raise ValueError("Input bbox has zero area")

    geom = feature.get("geometry")
    if not geom:
        return 0.0

    scene_geom = shape(geom)
    overlap_area = scene_geom.intersection(user_geom).area

    return 100.0 * overlap_area / user_area


def select_best_candidate(
    search_results: dict, target_datetime: str, input_bbox: str
) -> list[str]:
    target_dt = parse_target_datetime(target_datetime)

    best_candidate = None
    best_key = None

    for feature in search_results.get("features", []):
        candidate_id = extract_candidate_id(feature)
        if not candidate_id:
            continue

        processing_dt = extract_processing_datetime(feature)
        if processing_dt is None:
            continue

        coverage_pct = compute_bbox_coverage_pct(feature, input_bbox)
        delta_seconds = abs((processing_dt - target_dt).total_seconds())

        print(
            f"Candidate {candidate_id}: "
            f"bbox coverage = {coverage_pct:.2f}% | "
            f"datetime = {processing_dt.strftime('%Y-%m-%d')} | "
            f"delta to target datetime = {delta_seconds/3600/24:.2f} days"
        )

        # Ranking:
        # 1) highest bbox coverage first
        # 2) closest processing datetime second
        key = (-coverage_pct, delta_seconds, candidate_id)

        if best_key is None or key < best_key:
            best_key = key
            best_candidate = candidate_id

    return [best_candidate] if best_candidate else []


def convert_search_results(
    search_results_path: Path, target_datetime: str, input_bbox: str
) -> list[str]:
    search_results = json.loads(search_results_path.read_text(encoding="utf-8"))
    return select_best_candidate(search_results, target_datetime, input_bbox)
