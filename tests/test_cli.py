"""Check the published terminal command after the import-package migration."""

from __future__ import annotations

from typer.testing import CliRunner

from pokerclient.cli import app


def test_status_reports_foundation_without_business_claims() -> None:
    """The CLI stays available while game transport remains unconfigured."""
    result = CliRunner().invoke(app, ["status"])

    assert result.exit_code == 0, result.output
    assert result.output.strip() == (
        "Client foundation is installed; game transport and login are not configured."
    )
