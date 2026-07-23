#!/usr/bin/env python3
"""Run a Vivado post-implementation timing simulation from a JSON scenario."""

import argparse
import json
import os
import shutil
import subprocess
import sys
from pathlib import Path

ROOT_DIR = Path(__file__).resolve().parent.parent


def parse_args():
    parser = argparse.ArgumentParser(
        description="Run a post-implementation timing simulation scenario."
    )
    parser.add_argument("scenario", type=Path, help="JSON scenario file")
    parser.add_argument("--vivado", help="Vivado executable path")
    parser.add_argument("--dry-run", action="store_true",
                        help="print commands without executing them")
    args, extra = parser.parse_known_args()
    if extra and extra[0] == "--":
        extra = extra[1:]
    invalid = [value for value in extra if not value.startswith("+")]
    if invalid:
        parser.error("extra simulator arguments must be plusargs: " + " ".join(invalid))
    return args, extra


def resolve_path(base_dir, value):
    path = Path(os.path.expandvars(os.path.expanduser(value)))
    if not path.is_absolute():
        path = base_dir / path
    return path.resolve()


def build_plusargs(scenario_path, scenario):
    base_dir = scenario_path.parent
    required_paths = []
    result = []

    images = scenario.get("images", {})
    for image_name, plusarg_name in (("base", "base_ram_mif"),
                                     ("ext", "ext_ram_mif")):
        value = images.get(image_name, "none")
        if value == "none":
            rendered = "none"
        else:
            path = resolve_path(base_dir, value)
            required_paths.append(path)
            rendered = str(path)
        result.append(f"+{plusarg_name}={rendered}")

    for name, value in scenario.get("plusargs", {}).items():
        if isinstance(value, dict):
            if set(value) == {"path"}:
                path = resolve_path(base_dir, value["path"])
                required_paths.append(path)
                value = str(path)
            elif "symbol" in value:
                symbol = value["symbol"]
                symbol_file = resolve_path(base_dir, value["file"])
                required_paths.append(symbol_file)
                if not symbol_file.is_file():
                    raise SystemExit(
                        f"symbol file is missing: {symbol_file}\nRun --prepare first."
                    )
                matches = []
                for line in symbol_file.read_text(encoding="ascii").splitlines():
                    fields = line.split()
                    if len(fields) == 2 and fields[1] == symbol:
                        matches.append(fields[0])
                if len(matches) != 1:
                    raise SystemExit(
                        f"{symbol_file}: expected 1 definition of {symbol}, found {len(matches)}"
                    )
                try:
                    value = f"0x{int(matches[0], 16):08x}"
                except ValueError as exc:
                    raise SystemExit(
                        f"{symbol_file}: invalid address for {symbol}: {matches[0]}"
                    ) from exc
            else:
                raise SystemExit(f"{scenario_path}: invalid structured plusarg {name}")
        elif isinstance(value, bool):
            if value:
                result.append(f"+{name}")
            continue
        result.append(f"+{name}={value}")

    for flag in scenario.get("flags", []):
        result.append("+" + flag)
    return result, required_paths


def merge_extra_plusargs(plusargs, extra):
    override_names = {value[1:].split("=", 1)[0] for value in extra}
    kept = [value for value in plusargs
            if value[1:].split("=", 1)[0] not in override_names]
    return kept + extra


def find_vivado(requested):
    candidates = [requested, os.environ.get("VIVADO"), shutil.which("vivado")]
    for candidate in candidates:
        if not candidate:
            continue
        path = Path(candidate)
        if path.exists() or shutil.which(candidate):
            return path.resolve() if path.exists() else Path(candidate)
    raise SystemExit("Vivado not found; pass --vivado or set VIVADO")


def run_command(command, cwd, dry_run):
    import shlex
    print(f"[POST_IMPL] cwd: {cwd}", flush=True)
    print(f"[POST_IMPL] command: {' '.join(shlex.quote(str(v)) for v in command)}", flush=True)
    if dry_run:
        return
    subprocess.run(command, cwd=cwd, check=True)


def main():
    args, extra = parse_args()
    scenario_path = args.scenario.resolve()
    data = json.loads(scenario_path.read_text(encoding="utf-8"))
    if data.get("version") != 1:
        raise SystemExit(f"{scenario_path}: unsupported scenario version")
    if not isinstance(data.get("plusargs", {}), dict):
        raise SystemExit(f"{scenario_path}: plusargs must be an object")
    if not isinstance(data.get("flags", []), list):
        raise SystemExit(f"{scenario_path}: flags must be an array")

    print(f"[POST_IMPL] scenario: {data.get('name', scenario_path.stem)}", flush=True)

    plusargs, required_paths = build_plusargs(scenario_path, data)
    if not args.dry_run:
        missing = [p for p in required_paths if not p.is_file()]
        if missing:
            lines = "\n".join(f"  {p}" for p in missing)
            raise SystemExit(
                f"scenario artifacts are missing:\n{lines}\n"
                "Run the supervisor build first."
            )
    plusargs = merge_extra_plusargs(plusargs, extra)

    project = ROOT_DIR / "fpga/project/Loongson_Soc.xpr"
    if not args.dry_run and not project.exists():
        raise SystemExit(
            "Vivado project is missing; run create_project.tcl first."
        )

    run_script = ROOT_DIR / "sim/xsim/run_post_impl.tcl"
    encoded_plusargs = []
    for plusarg in plusargs:
        value = plusarg[1:]
        if "=" in value:
            name, val = value.split("=", 1)
            encoded_plusargs.extend(["--plusarg-value", name, val])
        else:
            encoded_plusargs.extend(["--plusarg-flag", value])

    vivado = find_vivado(args.vivado)
    arguments = [
        "-mode", "batch", "-source", str(run_script),
        "-tclargs", str(project),
    ] + encoded_plusargs

    run_command([str(vivado)] + arguments, ROOT_DIR / "fpga", args.dry_run)
    print(f"[POST_IMPL] PASS: {data.get('name', scenario_path.stem)}", flush=True)


if __name__ == "__main__":
    try:
        main()
    except subprocess.CalledProcessError as exc:
        raise SystemExit(exc.returncode) from exc
