# convert-search

`convert-search` selects the best Sentinel-1 product identifier from a STAC ItemCollection returned by the discovery step in the CWL workflow.

## What It Does

The tool reads a GeoJSON/STAC ItemCollection file, inspects `features[].links[]`, extracts product names from links with `rel == "derived_from"`, and returns:

- the first candidate whose identifier contains the same day as `--target-datetime`
- otherwise the first available candidate
- otherwise an empty list

The selected items are written to `items.json` in the current working directory.

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
convert-search \
  --target-datetime 2026-03-10T12:00:00Z \
  --search-results /path/to/search-results.json
```

Example output:

```text
Target datetime: 2026-03-10T12:00:00Z
Search results file: /path/to/search-results.json
Selected items: ['S1A_IW_GRDH_1SDV_20260310T101010_20260310T101035_000001_000001_0001']
```

The command writes:

```json
["S1A_IW_GRDH_1SDV_20260310T101010_20260310T101035_000001_000001_0001"]
```

to `items.json`.

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

- `src/convert_search/cli.py`: Click entrypoint
- `src/convert_search/process.py`: selection logic
- `tests/`: CLI and process tests

## License

`convert-search` is distributed under the terms of the [MIT](https://spdx.org/licenses/MIT.html) license.
