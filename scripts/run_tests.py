#!/usr/bin/env python3
"""Strict Godot checks: assertions can log errors while Godot still exits zero."""
import argparse
import os
from pathlib import Path
import re
import shutil
import subprocess

parser = argparse.ArgumentParser()
parser.add_argument("--godot", default=os.environ.get("GODOT_BIN", "godot"))
parser.add_argument("--render", action="store_true", help="Also test real rendering/PNG export; requires a display")
args = parser.parse_args()
root = Path(__file__).resolve().parents[1]
def discover_godot():
    """Use GODOT_BIN, PATH, common local/Windows installs, without a required CLI flag."""
    explicit = args.godot
    candidates = [explicit, "godot", "godot4", "godot-mono", "Godot"]
    if os.name == "nt":
        roots = [root, root / "tools", Path.home() / "Downloads", Path.home() / "Desktop"]
        for candidate_root in roots:
            if candidate_root.exists():
                candidates.extend(str(p) for p in candidate_root.glob("Godot_v4.7*_win64*.exe"))
        candidates.extend([
            r"C:\Program Files\Godot\Godot.exe",
            r"C:\Program Files (x86)\Godot\Godot.exe",
        ])
    for candidate in candidates:
        resolved = shutil.which(candidate)
        if resolved:
            return resolved
        if Path(candidate).is_file():
            return str(Path(candidate).resolve())
    raise SystemExit(
        "Godot 4.7 not found. Run tests directly in Godot via "
        "tests/run_from_editor.gd or add Godot to PATH; "
        "GODOT_BIN / --godot remain optional overrides."
    )

godot = discover_godot()

def run(arguments, marker=None):
    result = subprocess.run([godot, "--path", str(root), "--audio-driver", "Dummy", *arguments],
                            text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, timeout=360)
    print(result.stdout, end="")
    if result.returncode or re.search(r"SCRIPT ERROR|(?:^|\n)ERROR:|Parse Error|Assertion failed|leaked at exit", result.stdout):
        raise SystemExit("Godot validation failed")
    if marker and marker not in result.stdout:
        raise SystemExit("Missing success marker: " + marker)

version = subprocess.check_output([godot, "--version"], text=True).strip()
if not version.startswith("4.7."):
    raise SystemExit("Use Godot 4.7.x (CI pins 4.7.2): " + version)
run(["--headless", "--editor", "--import"])
run(["--headless", "--script", "res://tests/load_scripts.gd"], "PASS: script loading")
run(["--headless", "--script", "res://tests/species_regression.gd"], "PASS: procedural species")
run(["--headless", "--script", "res://tests/species_lab_smoke.gd"], "PASS: species lab smoke")
run(["--headless", "--script", "res://tests/regression.gd"], "PASS: generator regression")
if args.render:
    run(["--rendering-method", "gl_compatibility", "--script", "res://tests/regression.gd"], "PASS: generator regression")
print("PASS: all checks")
