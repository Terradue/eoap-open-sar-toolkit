from pathlib import Path

import pytest

from stac_catalog.process import build_stac_catalog


def test_build_stac_catalog_requires_catalog_file(tmp_path):
    input_dir = tmp_path / "sample-input"
    input_dir.mkdir()

    with pytest.raises(FileNotFoundError, match="Missing catalog.json"):
        build_stac_catalog(input_dir, "scene-001")


def test_build_stac_catalog_requires_tiff_asset_key(monkeypatch, tmp_path):
    input_dir = tmp_path / "sample-input"
    input_dir.mkdir()
    catalog_path = input_dir / "catalog.json"
    catalog_path.write_text("{}", encoding="utf-8")
    item_json_path = input_dir / "item.json"
    item_json_path.write_text("{}", encoding="utf-8")

    class FakeLink:
        rel = "item"
        href = "item.json"

    class FakeCatalog:
        links = [FakeLink()]

    class FakeItem:
        def get_assets(self):
            return {}

    class FakePystac:
        class Catalog:
            @staticmethod
            def from_file(path):
                assert Path(path) == catalog_path
                return FakeCatalog()

        class Item:
            @staticmethod
            def from_file(path):
                assert Path(path) == item_json_path
                return FakeItem()

    monkeypatch.setattr(
        "stac_catalog.process._import_runtime_dependencies",
        lambda: {"pystac": FakePystac()},
    )

    with pytest.raises(KeyError, match="Expected a TIFF asset with key 'TIFF'"):
        build_stac_catalog(input_dir, "scene-001")
