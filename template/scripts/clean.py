"""Remove build artifacts and caches (run through `just clean`).

Plain pathlib, so it behaves the same on Linux, macOS and Windows.
"""

import shutil
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SKIP = {".git", ".venv", "node_modules"}
DIR_NAMES = {"__pycache__", ".pytest_cache", ".ruff_cache", "dist", "build"}
FILE_NAMES = {".coverage"}


def walk(directory: Path):
    for path in directory.iterdir():
        if path.name in SKIP:
            continue
        if path.is_dir():
            if path.name in DIR_NAMES or path.name.endswith(".egg-info"):
                shutil.rmtree(path)
            else:
                yield from walk(path)
        elif path.suffix == ".pyc" or path.name in FILE_NAMES:
            path.unlink()


if __name__ == "__main__":
    for _ in walk(ROOT):
        pass
    print("Cleaned.")
