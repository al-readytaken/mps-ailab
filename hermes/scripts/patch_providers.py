"""Patch _PROVIDER_MODELS in hermes_cli/models.py to add openrouter models.

Called during Docker build. Adds the openrouter entry after the
_PROVIDER_MODELS dict opening brace. Idempotent — only patches once.
"""
from __future__ import annotations

import re
import sys
from pathlib import Path

TARGET = Path("/opt/hermes/hermes_cli/models.py")
MARKER = "openrouter"

MODELS = """\
    "openrouter": [
        "deepseek/deepseek-v4-pro",
        "x-ai/grok-4.3",
        "minimax/minimax-m2.7",
        "google/gemini-3-pro-preview",
    ],
"""


def main() -> int:
    if not TARGET.exists():
        print(f"ERROR: {TARGET} not found", file=sys.stderr)
        return 1

    content = TARGET.read_text()

    if MARKER in content:
        print(f"patch_providers: {MARKER} entry already present, skipping")
        return 0

    patched = re.sub(
        r'(_PROVIDER_MODELS\s*(?::\s*dict\[str,\s*list\[str\]\])?\s*=\s*\{)',
        r'\1\n' + MODELS,
        content,
        count=1,
    )
    TARGET.write_text(patched)
    print(f"patch_providers: Added {MARKER} to {TARGET}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
