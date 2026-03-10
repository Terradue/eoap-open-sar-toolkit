# cli.py

import click


@click.command(
    short_help="convert-search: Convert a search result into a different format.",
)
@click.option(
    "--target-datetime",
    required=True,
    type=click.STRING,
)
@click.option(
    "--search-results",
    type=click.Path(exists=True, dir_okay=False, file_okay=True, readable=True),
)
def main(target_datetime, search_results):

    click.echo(f"Target datetime: {target_datetime}")
    click.echo(f"Search results file: {search_results}")


if __name__ == "__main__":
    main()