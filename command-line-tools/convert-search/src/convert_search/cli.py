import click
import json
from pathlib import Path

from convert_search.process import convert_search_results


@click.command(
    short_help="convert-search: Convert a search result into a different format.",
)
@click.option(
    "--target-datetime",
    required=True,
    type=click.STRING,
)
@click.option(
    "--input-bbox",
    required=True,
    type=click.STRING,
    help="Comma-separated bbox: minx,miny,maxx,maxy",
)
@click.option(
    "--search-results",
    required=True,
    type=click.Path(
        exists=True, dir_okay=False, file_okay=True, readable=True, path_type=Path
    ),
)
def main(target_datetime, input_bbox, search_results):
    click.echo(f"Target datetime: {target_datetime}")
    click.echo(f"Input bbox: {input_bbox}")
    click.echo(f"Search results file: {search_results}")
    items = convert_search_results(search_results, target_datetime, input_bbox)
    Path("items.json").write_text(json.dumps(items), encoding="utf-8")
    click.echo(f"Selected items: {items}")


if __name__ == "__main__":
    main()
