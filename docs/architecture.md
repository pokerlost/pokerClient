# pokerClient architecture

`src/pokerclient/cli.py` owns the current terminal entrypoint. A later client should keep presentation and input separate from its chosen transport. The reference curses and TCP examples in `pokerengine` remain examples; production realtime transport/security is undecided. No SDK WebSocket or NDJSON support is assumed. The server owns authoritative table state and filters private views before transmission.
