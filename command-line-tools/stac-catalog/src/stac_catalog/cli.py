import click
from pathlib import Path

from stac_catalog.process import build_stac_catalog


@click.command(
    short_help="stac-catalog: Produce a STAC catalog.",
)
@click.option(
    "--input-tif",
    "--input_tif",
    required=True,
    type=click.Path(
        exists=True, dir_okay=True, file_okay=False, readable=True, path_type=Path
    ),
    help="Input directory containing the STAC catalog, item, and TIFF asset.",
)
@click.option(
    "--reference-id",
    type=click.STRING,
    required=True,
)
@click.option(
    "--bbox",
    type=(float, float, float, float),
    help="Bounding box to use for cropping the COG output",
)
def main(input_tif, reference_id, bbox):
    click.echo(f"Input directory: {input_tif}")
    click.echo(f"Reference ID: {reference_id}")
    click.echo(f"Bounding box: {bbox}")
    
    print("TESTING, WIP")
    
    output_dir = build_stac_catalog(input_tif.resolve(), reference_id, bbox=bbox)
    click.echo(f"Output directory: {output_dir}")


if __name__ == "__main__":
    main()
