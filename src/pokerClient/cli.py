"""Terminal entrypoint for the local Pokerlost client foundation."""

from __future__ import annotations

import typer

app = typer.Typer(help="Pokerlost terminal client foundation")


@app.callback()
def main() -> None:
    """Expose the current client status command."""


@app.command()
def status() -> None:
    """Describe the currently available client lifecycle."""
    typer.echo("Client foundation is installed; game transport and login are not configured.")
