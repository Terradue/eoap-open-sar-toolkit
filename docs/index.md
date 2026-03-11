# OpenSAR Toolkit

`eoap-open-sar-toolkit` is a CWL-based workflow for discovering Sentinel-1 products, processing them with OpenSarToolkit, and packaging the output as a STAC catalog containing a Cloud Optimized GeoTIFF.

## What This Documentation Covers

This site documents:

- the main CWL workflow definition
- the workflow inputs, steps, and outputs
- the generated diagrams for the `opensartoolkit` workflow
- the supporting Python command-line tools used by the workflow

## Main Components

The repository is organized around three main parts:

- `cwl-workflow/open-sar-toolkit.cwl`: the workflow entrypoint
- `command-line-tools/convert-search`: selects the most relevant Sentinel-1 product from discovery results
- `command-line-tools/stac-catalog`: converts OST output into a self-contained STAC catalog with a COG asset

## Workflow Summary

At a high level, the workflow does the following:

1. Builds a search request from a target datetime and AOI.
2. Queries a remote catalog for Sentinel-1 products.
3. Selects the best candidate product for the requested date.
4. Stages the source SAFE product.
5. Runs OpenSarToolkit preprocessing.
6. Writes the final result as a STAC catalog.

## Start Here

The generated workflow documentation is available here:

- [OpenSAR Toolkit](opensartoolkit.md)

For source code and repository-level development details, see the project repository:

- [Terradue/eoap-open-sar-toolkit](https://github.com/Terradue/eoap-open-sar-toolkit)
