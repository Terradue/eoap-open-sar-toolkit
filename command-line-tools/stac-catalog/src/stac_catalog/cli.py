# cli.py

import click


@click.command(
    short_help="stac-catalog: Produce a STAC catalog.",
)
@click.option(
    "--input-tif",
    required=True,
    type=click.Path(exists=True, dir_okay=False, file_okay=True, readable=True),
)
@click.option(
    "--reference-id",
    type=click.STRING,
)
@click.option("--bbox", nargs=4, type=float, help="Bounding box as minx miny maxx maxy")
def main(input_tif, reference_id, bbox):

    click.echo(f"Input TIFF file: {input_tif}")
    click.echo(f"Reference ID: {reference_id}")
    click.echo(f"Bounding box: {bbox}")


if __name__ == "__main__":
    main()