import json
import re
from pathlib import Path
from urllib.parse import unquote
from shapely.geometry import box, shape, Polygon
from shapely.geometry.base import BaseGeometry
from pyproj import Geod
from datetime import datetime, timezone

PRODUCT_NAME_PATTERN = re.compile(r"Name eq '([^']+)\.SAFE'")
geod = Geod(ellps="WGS84")

def _parse_target_datetime(target_datetime: str) -> datetime:
    dt = datetime.fromisoformat(target_datetime.replace("Z", "+00:00"))
    if dt.tzinfo is None:
        dt = dt.replace(tzinfo=timezone.utc)
    return dt


def _parse_input_bbox(input_bbox: str) -> tuple[float, float, float, float]:
    parts = [float(x.strip()) for x in input_bbox.split(",")]
    if len(parts) != 4:
        raise ValueError(
            "input_bbox must be a comma-separated string: minx,miny,maxx,maxy"
        )

    minx, miny, maxx, maxy = parts
    if minx >= maxx or miny >= maxy:
        raise ValueError(f"Invalid bbox: {input_bbox}")

    return minx, miny, maxx, maxy


def _extract_processing_datetime(feature: dict) -> datetime | None:
    props = feature.get("properties", {})
    dt_str = props.get("processing:datetime")
    if not dt_str:
        return None

    dt = datetime.fromisoformat(dt_str.replace("Z", "+00:00"))
    if dt.tzinfo is None:
        dt = dt.replace(tzinfo=timezone.utc)
    return dt


def _compute_bbox_coverage_pct(scene_geom: BaseGeometry, user_geom: Polygon) -> float:
    overlap_area = scene_geom.intersection(user_geom).area

    return 100.0 * overlap_area / user_geom.area


def _compute_centroid_distance(scene_geom: BaseGeometry, user_geom: Polygon) -> float:
    scene_geom_centroid = scene_geom.centroid
    user_geom_centroid = user_geom.centroid
    _, _, distance_m = geod.inv(
        scene_geom_centroid.x,
        scene_geom_centroid.y, 
        user_geom_centroid.x,
        user_geom_centroid.y, 
    )
    return distance_m / 1000    


def extract_candidate_id(feature: dict) -> str | None:
    for link in feature.get("links", []):
        if link.get("rel") != "derived_from":
            continue

        href = link.get("href", "")
        match = PRODUCT_NAME_PATTERN.search(unquote(href))
        if match:
            return match.group(1)

    return None

def _find_reference_feature(reference: str, search_results: dict) -> dict|None:
    for feature in search_results.get("features", []):
        if feature.get("id") == reference:
            return feature
    return None
    

def select_best_candidate(
    search_results: dict, target_datetime: str, input_bbox: str
) -> list[str]:
    target_dt = _parse_target_datetime(target_datetime)

    # Get user geometry
    user_geom = box(*_parse_input_bbox(input_bbox))
    if user_geom.area <= 0:
        raise ValueError("Input bbox has zero area")

    best_candidate = None
    best_key = None

    for feature in search_results.get("features", []):
        candidate_id = extract_candidate_id(feature)
        if not candidate_id:
            continue

        processing_dt = _extract_processing_datetime(feature)
        if processing_dt is None:
            continue

        # Get scene geometry
        geom = feature.get("geometry")
        scene_geom = shape(geom) if geom else None
        if not scene_geom:
            continue

        coverage_pct = _compute_bbox_coverage_pct(scene_geom=scene_geom, user_geom=user_geom)
        distance = _compute_centroid_distance(scene_geom=scene_geom, user_geom=user_geom)
        delta_seconds = abs((processing_dt - target_dt).total_seconds())

        print(
            f"Candidate {candidate_id}: "
            f"bbox coverage = {coverage_pct:.2f}% | "
            f"datetime = {processing_dt.strftime('%Y-%m-%d')} | "
            f"delta to target datetime = {delta_seconds/3600/24:.2f} days"
        )

        # Ranking:
        # 1) highest bbox coverage first
        # 2) closest to geometry centroid
        # 3) closest processing datetime second
        key = (-coverage_pct, distance, delta_seconds, candidate_id)

        if best_key is None or key < best_key:
            best_key = key
            best_candidate = candidate_id

    return [best_candidate] if best_candidate else []


def select_matching_features(
    search_results: dict, reference: str, target_datetime: str
) -> list[str]:
    # Select feat
    target_dt = _parse_target_datetime(target_datetime)

    features = []
    reference_feature = None
    for feature in search_results.get("features", []):
        feature_id = extract_candidate_id(feature)
        if not feature_id:
            continue

        processing_dt = _extract_processing_datetime(feature)
        if processing_dt is None:
            continue

        properties = feature.get("properties", {})
        relative_orbit = properties.get("sat:relative_orbit")
        orbit_direction = properties.get("sat:orbit_state")

        if relative_orbit is None or orbit_direction is None:
            continue
        
        # Create feature list with condensed information
        simple_feature = {
            "id": feature_id,
            "datetime": processing_dt,
            "orbit_direction": orbit_direction,
            "relative_orbit": relative_orbit,
            "geometry": feature.get("geometry"),
            "orig": feature
        }
        features.append(simple_feature)
        if feature_id == reference:
            reference_feature = simple_feature

    if not reference_feature:
        raise ValueError("Reference feature '{reference}' not in result")
    
    print(reference_feature)

    features.sort(key=lambda feature: abs(feature["datetime"] - target_dt))

    matching_features = []
    for feature in features:
        if feature["orbit_direction"] == reference_feature["orbit_direction"]:
            matching_features.append(feature["id"])
            print("{0} {1} {2}".format(feature["id"], feature["relative_orbit"], feature["orbit_direction"]))
        
    return matching_features


def convert_search_results(
    search_results_path: Path,
    target_datetime: str,
    input_bbox: str,
    reference: str|None = None,
) -> list[str]:
    search_results = json.loads(search_results_path.read_text(encoding="utf-8"))

    if reference:
        # If reference is given, select matching features
        return select_matching_features(search_results, reference, target_datetime)
    
    else:
        # If no reference is given, only search the best candidate
        return select_best_candidate(search_results, target_datetime, input_bbox)
