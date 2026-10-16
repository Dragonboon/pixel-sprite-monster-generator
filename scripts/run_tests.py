#!/usr/bin/env python3
"""Strict Godot checks: assertions can log errors while Godot still exits zero."""
import argparse
import os
from pathlib import Path
import re
import subprocess

parser = argparse.ArgumentParser()
parser.add_argument("--godot", default=os.environ.get("GODOT_BIN", "godot"))
parser.add_argument("--render", action="store_true", help="Also test real rendering/PNG export; requires a display")
args = parser.parse_args()
root = Path(__file__).resolve().parents[1]
godot = str(Path(args.godot).resolve()) if Path(args.godot).is_file() else args.godot

def run(arguments, marker=None):
    result = subprocess.run([godot, "--path", str(root), "--audio-driver", "Dummy", *arguments],
                            text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, timeout=120)
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
run(["--headless", "--script", "res://tests/regression.gd"], "PASS: generator regression")
if args.render:
    run(["--rendering-method", "gl_compatibility", "--script", "res://tests/regression.gd"], "PASS: generator regression")
print("PASS: all checks")
