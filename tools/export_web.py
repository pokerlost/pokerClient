"""Export a clean-commit Flutter bundle with a reproducible checksum manifest."""

from __future__ import annotations

import argparse
import hashlib
import json
import re
import shutil
import subprocess
from pathlib import Path


def export_bundle(
    bundle: Path, destination: Path, revision: str, toolchain: dict[str, str]
) -> dict[str, object]:
    """Verify all inputs before copying a public gameplay artifact."""
    if re.fullmatch(r"[0-9a-f]{40}", revision) is None:
        raise ValueError("Expected a full client commit")
    if not bundle.is_dir() or not (bundle / "flutter_bootstrap.js").is_file():
        raise ValueError("A built Flutter bundle is required")
    if (
        bundle.resolve() == destination.resolve()
        or bundle.resolve() in destination.resolve().parents
    ):
        raise ValueError("Artifact destination must be outside the bundle")
    if destination.exists():
        raise ValueError("Use a fresh artifact destination")
    checksums: dict[str, str] = {}
    for path in sorted(bundle.rglob("*")):
        if path.is_symlink():
            raise ValueError("Bundle symlinks are forbidden")
        if path.is_file():
            checksums[path.relative_to(bundle).as_posix()] = hashlib.sha256(
                path.read_bytes()
            ).hexdigest()
    manifest: dict[str, object] = {
        "clientCommit": revision,
        "bridgeVersion": 1,
        "toolchain": toolchain,
        "files": checksums,
    }
    shutil.copytree(bundle, destination)
    data = (json.dumps(manifest, indent=2, sort_keys=True) + "\n").encode()
    (destination / "artifact-manifest.json").write_bytes(data)
    return manifest


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("bundle", type=Path)
    parser.add_argument("destination", type=Path)
    parser.add_argument("--flutter", default="flutter")
    args = parser.parse_args()
    repository = Path(__file__).resolve().parents[1]
    status = subprocess.check_output(
        ["git", "status", "--porcelain"], cwd=repository, text=True
    )
    if status.strip():
        raise RuntimeError("Commit and verify the client source before exporting")
    revision = subprocess.check_output(
        ["git", "rev-parse", "HEAD"], cwd=repository, text=True
    ).strip()
    expected = json.loads((repository / "toolchain.lock.json").read_text())
    actual = json.loads(
        subprocess.check_output([args.flutter, "--version", "--machine"], text=True)
    )
    for key, value in expected.items():
        if actual.get(key) != value:
            raise RuntimeError(f"Flutter toolchain mismatch: {key}")
    toolchain = {key: actual[key] for key in expected}
    export_bundle(args.bundle, args.destination, revision, toolchain)


if __name__ == "__main__":
    main()
