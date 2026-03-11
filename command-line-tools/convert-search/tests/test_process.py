
from convert_search.process import (
    convert_search_results,
    extract_candidate_ids,
    select_best_candidate,
)


def test_extract_candidate_ids_reads_derived_from_links():
    search_results = {
        "features": [
            {
                "links": [
                    {
                        "rel": "derived_from",
                        "href": "https://example.test/?$filter=Name%20eq%20%27S1A_IW_GRDH_1SDV_20260310T101010_20260310T101035_000001_000001_0001.SAFE%27",
                    },
                    {"rel": "self", "href": "https://example.test/items/1"},
                ]
            }
        ]
    }

    assert extract_candidate_ids(search_results) == [
        "S1A_IW_GRDH_1SDV_20260310T101010_20260310T101035_000001_000001_0001"
    ]


def test_select_best_candidate_prefers_same_day():
    candidates = [
        "S1A_IW_GRDH_1SDV_20260308T101010_20260308T101035_000001_000001_0001",
        "S1A_IW_GRDH_1SDV_20260310T101010_20260310T101035_000002_000002_0002",
    ]

    assert select_best_candidate(candidates, "2026-03-10T12:00:00Z") == [
        "S1A_IW_GRDH_1SDV_20260310T101010_20260310T101035_000002_000002_0002"
    ]


def test_convert_search_results_falls_back_to_first_candidate(tmp_path):
    search_results_path = tmp_path / "search-results.json"
    search_results_path.write_text(
        """
        {
          "features": [
            {
              "links": [
                {
                  "rel": "derived_from",
                  "href": "https://example.test/?$filter=Name%20eq%20%27S1A_IW_GRDH_1SDV_20260308T101010_20260308T101035_000001_000001_0001.SAFE%27"
                },
                {
                  "rel": "derived_from",
                  "href": "https://example.test/?$filter=Name%20eq%20%27S1A_IW_GRDH_1SDV_20260309T101010_20260309T101035_000002_000002_0002.SAFE%27"
                }
              ]
            }
          ]
        }
        """,
        encoding="utf-8",
    )

    assert convert_search_results(search_results_path, "2026-03-10T12:00:00Z") == [
        "S1A_IW_GRDH_1SDV_20260308T101010_20260308T101035_000001_000001_0001"
    ]
