#!/usr/bin/env python3
"""Ensure Hermes model config is present in config.yaml.

Called from entrypoint.sh before gateway startup.
Exits 0 if model config is already correct or was written successfully.
Exits 1 if writing failed.
"""
import os
import sys
import pathlib

CONFIG_DIR = os.environ.get("HERMES_HOME", os.path.expanduser("~/.hermes"))
CONFIG_PATH = pathlib.Path(CONFIG_DIR) / "config.yaml"
PROVIDER = os.environ.get("MODEL_PROVIDER", "openrouter")
NAME = os.environ.get("MODEL_NAME", "deepseek/deepseek-v4-pro")
BASE_URL = os.environ.get("MODEL_BASE_URL", "https://openrouter.ai/api/v1")

if not CONFIG_PATH.exists():
    print(f"ERROR: {CONFIG_PATH} not found", file=sys.stderr)
    sys.exit(1)

raw = CONFIG_PATH.read_text()

# quick check: is model config already correct?
if f"provider: {PROVIDER}" in raw and f"name: {NAME}" in raw:
    print(f"entrypoint: Model config OK ({PROVIDER}/{NAME})")
    sys.exit(0)

# need to write — use yaml if available, otherwise locate model block
try:
    import yaml
except ImportError:
    print("entrypoint: yaml module not available, installing...", file=sys.stderr)
    # Try to install via the hermes venv pip
    venv_pip = pathlib.Path("/opt/hermes/.venv/bin/pip")
    if venv_pip.exists():
        os.system(f"{venv_pip} install pyyaml -q")
        import yaml
    else:
        print("ERROR: cannot install yaml", file=sys.stderr)
        sys.exit(1)

cfg = yaml.safe_load(raw) or {}
cfg.setdefault("model", {})
cfg["model"]["provider"] = PROVIDER
cfg["model"]["name"] = NAME
cfg["model"]["base_url"] = BASE_URL
CONFIG_PATH.write_text(yaml.dump(cfg, default_flow_style=False))
print(f"entrypoint: Model config written ({PROVIDER}/{NAME} -> {BASE_URL})")