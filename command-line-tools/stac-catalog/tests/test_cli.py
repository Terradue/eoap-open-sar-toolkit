
from click.testing import CliRunner

from stac_catalog import cli


def test_main_delegates_to_process(monkeypatch, tmp_path):
    input_dir = tmp_path / "sample-input"
    input_dir.mkdir()
    output_dir = tmp_path / "scene-001-COG"

    calls = {}

    def fake_build_stac_catalog(received_input_dir, reference_id, bbox=None):
        calls["input_dir"] = received_input_dir
        calls["reference_id"] = reference_id
        calls["bbox"] = bbox
        return output_dir

    monkeypatch.setattr(cli, "build_stac_catalog", fake_build_stac_catalog)

    result = CliRunner().invoke(
        cli.main,
        [
            "--input-tif",
            str(input_dir),
            "--reference-id",
            "scene-001",
            "--bbox",
            "1",
            "2",
            "3",
            "4",
        ],
    )

    assert result.exit_code == 0
    assert calls == {
        "input_dir": input_dir.resolve(),
        "reference_id": "scene-001",
        "bbox": (1.0, 2.0, 3.0, 4.0),
    }
    assert f"Input directory: {input_dir}" in result.output
    assert "Reference ID: scene-001" in result.output
    assert "Bounding box: (1.0, 2.0, 3.0, 4.0)" in result.output
    assert f"Output directory: {output_dir}" in result.output
