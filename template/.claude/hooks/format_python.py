#!/usr/bin/env python3
"""
Claude Code PostToolUse hook: format Python files after the agent writes them.

Runs `ruff format` on every `.py` file that the Write or Edit tool just
touched, so the agent's code arrives formatted without waiting for
pre-commit or `just fix`. Unlike the other two hooks this is not a guardrail:
it never blocks anything, it only tidies what was written.

The Python project is found by walking up from the edited file to the nearest
pyproject.toml (the repo root in simple projects, backend/ in product
projects), and Ruff runs through `uv run --project` there, so it uses the
project's own pinned Ruff and its own config. Files that config excludes
(for example .claude/ in simple projects) are left alone. Files outside the
project directory, and files with no pyproject.toml above them, are skipped.

Reads the PostToolUse hook JSON payload from stdin. Exit codes: 0 means done
or nothing to do; 2 means Ruff rejected the file (usually a syntax error) and
its message is shown to the agent so it can fix the edit; 1 means the hook
itself could not run (uv missing, timeout) and the reason is shown to you.
"""
import json
import os
import shutil
import subprocess
import sys
from pathlib import Path

TIMEOUT_SECONDS = 60


def edited_file(payload: dict) -> Path | None:
    tool_input = payload.get("tool_input")
    tool_response = payload.get("tool_response")
    candidates = [
        tool_input.get("file_path") if isinstance(tool_input, dict) else None,
        tool_response.get("filePath") if isinstance(tool_response, dict) else None,
    ]
    path = next((c for c in candidates if isinstance(c, str) and c), None)
    return Path(path) if path else None


def python_project_dir(file: Path, root: Path) -> Path | None:
    for directory in file.parents:
        if (directory / "pyproject.toml").is_file():
            return directory
        if directory == root:
            break
    return None


def main() -> int:
    try:
        payload = json.load(sys.stdin)
    except (json.JSONDecodeError, ValueError):
        print("format_python: unreadable hook input, nothing formatted.", file=sys.stderr)
        return 1

    file = edited_file(payload)
    if file is None or file.suffix != ".py" or not file.is_file():
        return 0

    root = Path(os.environ.get("CLAUDE_PROJECT_DIR", os.getcwd())).resolve()
    file = file.resolve()
    if not file.is_relative_to(root):
        return 0

    project = python_project_dir(file, root)
    if project is None:
        return 0

    if shutil.which("uv") is None:
        print("format_python: uv not found on PATH, nothing formatted.", file=sys.stderr)
        return 1

    try:
        result = subprocess.run(
            ["uv", "run", "--project", str(project), "ruff", "format", "--force-exclude", str(file)],
            cwd=project,
            capture_output=True,
            text=True,
            timeout=TIMEOUT_SECONDS,
        )
    except subprocess.TimeoutExpired:
        print(f"format_python: ruff format timed out after {TIMEOUT_SECONDS}s.", file=sys.stderr)
        return 1

    if result.returncode != 0:
        print(f"format_python: ruff could not format {file}:\n{result.stderr or result.stdout}", file=sys.stderr)
        return 2
    return 0


if __name__ == "__main__":
    sys.exit(main())
