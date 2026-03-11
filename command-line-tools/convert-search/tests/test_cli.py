import json
from pathlib import Path

from click.testing import CliRunner

from convert_search import cli


def test_main_delegates_and_writes_items_json(monkeypatch, tmp_path):
    search_results = tmp_path / "search-results.json"
    search_results.write_text("{}", encoding="utf-8")

    calls = {}

    def fake_convert_search_results(search_results_path, target_datetime, input_bbox):
        calls["search_results_path"] = search_results_path
        calls["target_datetime"] = target_datetime
        calls["input_bbox"] = input_bbox
        return ["S1A_TEST_SCENE"]

    monkeypatch.setattr(cli, "convert_search_results", fake_convert_search_results)

    runner = CliRunner()
    with runner.isolated_filesystem():
        result = runner.invoke(
            cli.main,
            [
                "--target-datetime",
                "2026-03-10T12:00:00Z",
                "--input-bbox",
                "12.146,41.701,12.629,41.967",
                "--search-results",
                str(search_results),
            ],
            catch_exceptions=False,
        )

        assert result.exit_code == 0
        assert calls == {
            "search_results_path": search_results,
            "target_datetime": "2026-03-10T12:00:00Z",
            "input_bbox": "12.146,41.701,12.629,41.967",
        }
        assert "Target datetime: 2026-03-10T12:00:00Z" in result.output
        assert "Input bbox: 12.146,41.701,12.629,41.967" in result.output
        assert f"Search results file: {search_results}" in result.output
        assert "Selected items: ['S1A_TEST_SCENE']" in result.output
        assert json.loads(Path("items.json").read_text(encoding="utf-8")) == [
            "S1A_TEST_SCENE"
        ]
