# stac-catalog

`stac-catalog` rewrites an input STAC bundle into a self-contained output catalog that contains a Cloud Optimized GeoTIFF generated from the processed OST raster.

## What It Does

The tool expects an input directory containing:

- `catalog.json`
- exactly one linked STAC item
- a TIFF asset stored under the asset key `TIFF`

It then:

1. reads the input STAC catalog and item
2. locates the TIFF asset
3. optionally crops the raster using `--bbox`
4. writes a Cloud Optimized GeoTIFF
5. creates a new STAC item and self-contained catalog under `<reference-id>-COG/`

## Installation

```bash
pip install .
```

For development:

```bash
hatch env create
```

## CLI Usage

```bash
stac-catalog \
  --input-tif /path/to/ost-output \
  --reference-id S1A_IW_GRDH_1SDV_20260310T101010_20260310T101035_000001_000001_0001 \
  --bbox 12.0 45.0 12.5 45.5
```

The output directory structure is:

```text
<reference-id>-COG/
  catalog.json
  <reference-id>-COG/
    <reference-id>-COG.json
    ost-ard-cog.tif
```

If `--bbox` is omitted, the full raster extent is used.

## Development

Run tests:

```bash
hatch run test:test
```

Run linting and checks:

```bash
hatch run dev:lint
hatch run dev:check
```

## Source Layout

- `src/stac_catalog/cli.py`: Click entrypoint
- `src/stac_catalog/process.py`: STAC rewrite and COG creation logic
- `tests/`: CLI and process tests

## License

`stac-catalog` is distributed under the terms of the [MIT](https://spdx.org/licenses/MIT.html) license.
