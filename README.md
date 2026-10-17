# pokerClient

A Python terminal client foundation generated from the generic Python Copier source. It has an honest runnable entrypoint and no connected game or login flow.

## 🚀 Run

Requires Python 3.12+ and `uv`:

```bash
uv lock
uv sync --locked
uv run --locked pokerClient status
```

The command reports that transport and login are not configured. It does not open a network connection, load credentials, or display a game table.

## 🧭 Client boundary

The reference curses client in `pokerengine/examples/client/poker_client.py` demonstrates command input and display, while `examples/server/poker_server.py` demonstrates server authority and public/player views. Their newline-delimited JSON/TCP transport lacks production TLS/auth and is not adopted here. A future client separates transport from terminal rendering, presents only server-authorized views, and never computes authoritative state or owns money. `pypokerlost` is an HTTP SDK; it does not supply the unchosen realtime transport.

The current package has no game transport or server API contract. See [PROJECT.md](PROJECT.md), [architecture](docs/architecture.md), and [CONTRIBUTING.md](CONTRIBUTING.md). No subject tests were generated. The opt-in CI checks the lock, style, types and build; an empty suite is reported as NOT_CONFIGURED.
