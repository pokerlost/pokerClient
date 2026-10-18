"""Export checks prove artifact identity, privacy boundaries and repeatability."""

from __future__ import annotations

import hashlib
import json
import shutil
import subprocess
import sys
from pathlib import Path

import pytest

from tools import export_web
from tools.export_web import export_bundle

REVISION = "a" * 40
TOOLCHAIN = {"flutterVersion": "3.47.0", "dartSdkVersion": "3.13.0"}


def bundle(root: Path) -> Path:
    source = root / "bundle"
    (source / "assets").mkdir(parents=True)
    (source / "flutter_bootstrap.js").write_text("synthetic loader")
    (source / "assets/data").write_bytes(b"synthetic public data")
    return source


def test_manifest_covers_every_file_and_is_reproducible(tmp_path: Path) -> None:
    source = bundle(tmp_path)
    output = tmp_path / "export"
    result = export_bundle(source, output, REVISION, TOOLCHAIN)
    assert result["clientCommit"] == REVISION and result["bridgeVersion"] == 1
    assert result["files"] == {
        "assets/data": hashlib.sha256(b"synthetic public data").hexdigest(),
        "flutter_bootstrap.js": hashlib.sha256(b"synthetic loader").hexdigest(),
    }
    second = tmp_path / "second"
    export_bundle(source, second, REVISION, TOOLCHAIN)
    assert (output / "artifact-manifest.json").read_bytes() == (
        second / "artifact-manifest.json"
    ).read_bytes()
    assert (output / "assets/data").read_bytes() == b"synthetic public data"
    (source / "assets/data").write_bytes(b"changed input")
    changed = export_bundle(source, tmp_path / "changed", REVISION, TOOLCHAIN)
    assert changed["files"] != result["files"]


@pytest.mark.parametrize("revision", ["main", "a" * 39, "z" * 40])
def test_floating_or_invalid_revision_is_rejected(
    tmp_path: Path, revision: str
) -> None:
    with pytest.raises(ValueError, match="full client commit"):
        export_bundle(bundle(tmp_path), tmp_path / "export", revision, TOOLCHAIN)


def test_invalid_source_destination_and_symlinks_are_rejected(tmp_path: Path) -> None:
    source = bundle(tmp_path)
    for destination in (source, source / "nested"):
        with pytest.raises(ValueError, match="outside"):
            export_bundle(source, destination, REVISION, TOOLCHAIN)
    with pytest.raises(ValueError, match="fresh"):
        export_bundle(source, tmp_path, REVISION, TOOLCHAIN)
    for invalid in (tmp_path / "missing", source / "assets"):
        with pytest.raises(ValueError, match="built Flutter"):
            export_bundle(invalid, tmp_path / "export", REVISION, TOOLCHAIN)
    (source / "link").symlink_to(source / "assets/data")
    with pytest.raises(ValueError, match="symlinks"):
        export_bundle(source, tmp_path / "export", REVISION, TOOLCHAIN)
    assert not (tmp_path / "export").exists()


def test_cli_exports_only_a_clean_local_git_commit(
    tmp_path: Path, monkeypatch: pytest.MonkeyPatch
) -> None:
    repository = tmp_path / "repo"
    (repository / "tools").mkdir(parents=True)
    script = repository / "tools/export_web.py"
    shutil.copyfile(Path(__file__).resolve().parents[1] / "tools/export_web.py", script)
    (repository / "toolchain.lock.json").write_text(json.dumps(TOOLCHAIN))

    def git(*args: str) -> str:
        return subprocess.check_output(
            ["git", *args], cwd=repository, text=True
        ).strip()

    git("init", "--quiet")
    git("add", "tools/export_web.py", "toolchain.lock.json")
    git(
        "-c",
        "user.name=Artifact Test",
        "-c",
        "user.email=artifact@example.invalid",
        "commit",
        "--quiet",
        "-m",
        "fixture",
    )
    source = bundle(tmp_path)
    output = tmp_path / "artifact"
    flutter = tmp_path / "flutter"
    flutter.write_text(
        f"#!{sys.executable}\nimport json\nprint({json.dumps(TOOLCHAIN)!r})\n"
    )
    flutter.chmod(0o755)
    monkeypatch.setattr(export_web, "__file__", str(script))
    monkeypatch.setattr(
        sys, "argv", [str(script), str(source), str(output), "--flutter", str(flutter)]
    )
    export_web.main()
    assert json.loads((output / "artifact-manifest.json").read_text())[
        "clientCommit"
    ] == git("rev-parse", "HEAD")
    flutter.write_text(f"#!{sys.executable}\nprint('{{}}')\n")
    monkeypatch.setattr(
        sys,
        "argv",
        [str(script), str(source), str(tmp_path / "wrong"), "--flutter", str(flutter)],
    )
    with pytest.raises(RuntimeError, match="toolchain mismatch"):
        export_web.main()
    assert not (tmp_path / "wrong").exists()
    script.write_text(script.read_text() + "\n# dirty source\n")
    monkeypatch.setattr(
        sys, "argv", [str(script), str(source), str(tmp_path / "dirty")]
    )
    with pytest.raises(RuntimeError, match="Commit and verify"):
        export_web.main()
    assert not (tmp_path / "dirty").exists()


def test_real_export_cli_help() -> None:
    script = Path(__file__).resolve().parents[1] / "tools/export_web.py"
    result = subprocess.run(
        [sys.executable, str(script), "--help"],
        capture_output=True,
        text=True,
        check=False,
    )
    assert result.returncode == 0 and "bundle" in result.stdout


def test_clean_python_archives_exclude_process_memory_and_local_metadata(
    tmp_path: Path,
) -> None:
    import tarfile
    import zipfile

    root = Path(__file__).resolve().parents[1]
    fixture = tmp_path / "packaging"
    fixture.mkdir()
    for name in ("pyproject.toml", "README.md", ".gitignore"):
        shutil.copyfile(root / name, fixture / name)
    shutil.copytree(root / "src", fixture / "src")
    private_names = {"core.1234", ".coverage", ".aws"}
    for name in private_names:
        (fixture / name).write_bytes(b"synthetic private marker")
    subprocess.run(
        [sys.executable, "-m", "hatchling", "build"],
        cwd=fixture,
        capture_output=True,
        check=True,
        timeout=30,
    )
    for archive in (fixture / "dist").iterdir():
        if archive.suffix == ".whl":
            with zipfile.ZipFile(archive) as wheel:
                names = wheel.namelist()
        else:
            with tarfile.open(archive) as sdist:
                names = sdist.getnames()
        assert not any(Path(name).name in private_names for name in names)
