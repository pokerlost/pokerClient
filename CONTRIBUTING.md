# Contributing to pokerClient

Open a short `type/shortCamelCaseIntent` branch from the actual default branch. Keep each PR focused, review the full diff and outgoing commits, and use a `type(scope): intent` title. Explain purpose, ownership, compatibility, actual checks, privacy, version decision, and rollback. Do not attach secrets or live data.

## 🧪 Local checks

On the first render, run `uv lock` and commit `uv.lock`. After that, use the locked commands below; CI requires the committed lockfile.

```bash
uv lock --check
uv sync --locked
uv run --locked ruff check .
uv run --locked ruff format --check .
uv run --locked mypy
uv build
```

Run `uv run --locked pytest -q` for the current CLI contract. Treat empty collection as failure. CI, package release, and deployment are separate from a local build. Record this project's decisions in `PROJECT.md`.
