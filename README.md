# eoap-open-sar-toolkit

`eoap-open-sar-toolkit` is a CWL workflow for discovering Sentinel-1 products, processing them with OpenSarToolkit, and packaging the resulting raster output as a STAC catalog with a Cloud Optimized GeoTIFF.

## Repository Layout

- `cwl-workflow/open-sar-toolkit.cwl`: main CWL workflow definition
- `command-line-tools/convert-search`: Python CLI that selects the best Sentinel-1 product from a STAC ItemCollection
- `command-line-tools/stac-catalog`: Python CLI that rewrites an input STAC bundle into a cropped COG-based STAC catalog
- `Taskfile.yaml`: convenience tasks for validation, image builds, tests, and checks

## Workflow Overview

The CWL workflow performs these stages:

1. Build a search request from the target datetime and AOI bbox.
2. Query the Copernicus Data Space OData endpoint.
3. Convert the returned STAC ItemCollection into one or more Sentinel-1 reference IDs.
4. Stage the selected SAFE product.
5. Run OpenSarToolkit preprocessing.
6. Convert the produced TIFF asset into a COG and write a new STAC catalog.

The main workflow entrypoint is `#opensartoolkit` inside [open-sar-toolkit.cwl](/data/work/github-terradue/eoap-open-sar-toolkit/cwl-workflow/open-sar-toolkit.cwl).

## Prerequisites

- Python 3.8+
- Docker
- `cwltool`
- `hatch`
- optionally `go-task` for `task` commands

The workflow also expects credentials and runtime access for the external services used during discovery and stage-in.

## Development

Build the command-line tool images:

```bash
task build
```

Validate the CWL workflow:

```bash
task validate
```

Run the package checks configured in each Python project:

```bash
task check
task lint
```

Run the test environments:

```bash
task test
```

## Python Tools

### `convert-search`

Reads a STAC ItemCollection GeoJSON, extracts Sentinel-1 product identifiers from `derived_from` links, prefers an item matching the requested day, and writes `items.json`.

See [command-line-tools/convert-search/README.md](/data/work/github-terradue/eoap-open-sar-toolkit/command-line-tools/convert-search/README.md).

### `stac-catalog`

Reads an input STAC catalog produced by the OST processing step, optionally crops the TIFF with a bbox, writes a COG, and emits a self-contained output STAC catalog.

See [command-line-tools/stac-catalog/README.md](/data/work/github-terradue/eoap-open-sar-toolkit/command-line-tools/stac-catalog/README.md).

## License

This repository is distributed under the terms of the MIT license unless noted otherwise in individual assets or metadata.
