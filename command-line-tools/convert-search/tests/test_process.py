import json

from convert_search.process import (
    convert_search_results,
    extract_candidate_id,
    select_best_candidate,
)


def _feature(candidate_id, processing_datetime, geometry_coords):
    return {
        "type": "Feature",
        "geometry": {
            "type": "Polygon",
            "coordinates": [geometry_coords],
        },
        "properties": {
            "processing:datetime": processing_datetime,
        },
        "links": [
            {
                "rel": "derived_from",
                "href": (
                    "https://example.test/?$filter="
                    f"Name%20eq%20%27{candidate_id}.SAFE%27"
                ),
            }
        ],
    }


def test_extract_candidate_id_reads_derived_from_link():
    feature = {
        "links": [
            {
                "rel": "derived_from",
                "href": (
                    "https://example.test/?$filter="
                    "Name%20eq%20%27"
                    "S1A_IW_GRDH_1SDV_20260310T101010_20260310T101035_000001_000001_0001"
                    ".SAFE%27"
                ),
            },
            {"rel": "self", "href": "https://example.test/items/1"},
        ]
    }

    assert extract_candidate_id(feature) == (
        "S1A_IW_GRDH_1SDV_20260310T101010_20260310T101035_000001_000001_0001"
    )


def test_select_best_candidate_prefers_highest_bbox_coverage():
    # input bbox: 0,0 to 10,10
    # first feature covers all of it -> 100%
    # second feature covers only half -> 50%
    feature_full = _feature(
        "S1A_FULL",
        "2026-03-12T10:00:00Z",
        [(0, 0), (10, 0), (10, 10), (0, 10), (0, 0)],
    )
    feature_partial = _feature(
        "S1A_PARTIAL",
        "2026-03-10T10:00:00Z",
        [(0, 0), (5, 0), (5, 10), (0, 10), (0, 0)],
    )

    search_results = {"features": [feature_partial, feature_full]}

    assert (
        select_best_candidate(
            search_results,
            "2026-03-10T12:00:00Z",
            "0,0,10,10",
        )
        == ["S1A_FULL"]
    )


def test_select_best_candidate_breaks_tie_with_closest_processing_datetime():
    # both features fully cover the bbox -> same coverage
    # second one is closer to target datetime, so it should win
    feature_farther = _feature(
        "S1A_FARTHER",
        "2026-03-08T12:00:00Z",
        [(0, 0), (10, 0), (10, 10), (0, 10), (0, 0)],
    )
    feature_closer = _feature(
        "S1A_CLOSER",
        "2026-03-10T10:00:00Z",
        [(0, 0), (10, 0), (10, 10), (0, 10), (0, 0)],
    )

    search_results = {"features": [feature_farther, feature_closer]}

    assert (
        select_best_candidate(
            search_results,
            "2026-03-10T12:00:00Z",
            "0,0,10,10",
        )
        == ["S1A_CLOSER"]
    )


def test_convert_search_results_selects_best_candidate(tmp_path):
    search_results_path = tmp_path / "search-results.json"
    search_results = {
        "features": [
            _feature(
                "S1A_PARTIAL",
                "2026-03-10T10:00:00Z",
                [(0, 0), (5, 0), (5, 10), (0, 10), (0, 0)],
            ),
            _feature(
                "S1A_FULL",
                "2026-03-12T10:00:00Z",
                [(0, 0), (10, 0), (10, 10), (0, 10), (0, 0)],
            ),
        ]
    }
    search_results_path.write_text(
        json.dumps(search_results),
        encoding="utf-8",
    )

    assert (
        convert_search_results(
            search_results_path,
            "2026-03-10T12:00:00Z",
            "0,0,10,10",
        )
        == ["S1A_FULL"]
    )