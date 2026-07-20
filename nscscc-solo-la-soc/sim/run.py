#!/usr/bin/env python3
"""Run a simulator backend from a software-owned JSON scenario."""

import argparse
import json
import os
from pathlib import Path
import shlex
import shutil
import subprocess
import sys


ROOT_DIR = Path(__file__).resolve().parent.parent
SUPPORTED_BACKENDS = ("verilator", "xsim")


def parse_args():
    parser = argparse.ArgumentParser(
        description="Run an SoC simulation scenario without embedding software paths in RTL."
    )
    parser.add_argument("scenario", type=Path, help="JSON scenario file")
    parser.add_argument("--backend", choices=SUPPORTED_BACKENDS,
                        help="override the backend selected by the scenario")
    parser.add_argument("--prepare", action="store_true",
                        help="run the scenario's optional prepare command first")
    parser.add_argument("--recreate-project", action="store_true",
                        help="recreate the Vivado project before an xsim run")
    parser.add_argument("--vivado", help="Vivado executable or .bat path")
    parser.add_argument("--dry-run", action="store_true",
                        help="print commands without executing them")
    args, extra = parser.parse_known_args()
    if extra and extra[0] == "--":
        extra = extra[1:]
    invalid = [value for value in extra if not value.startswith("+")]
    if invalid:
        parser.error("extra simulator arguments must be plusargs: " + " ".join(invalid))
    return args, extra


def load_scenario(path):
    path = path.resolve()
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        raise SystemExit(f"cannot load scenario {path}: {exc}") from exc
    if data.get("version") != 1:
        raise SystemExit(f"{path}: unsupported or missing scenario version")
    if not isinstance(data.get("plusargs", {}), dict):
        raise SystemExit(f"{path}: plusargs must be an object")
    if not isinstance(data.get("flags", []), list):
        raise SystemExit(f"{path}: flags must be an array")
    return path, data


def resolve_path(base_dir, value):
    path = Path(os.path.expandvars(os.path.expanduser(value)))
    if not path.is_absolute():
        path = base_dir / path
    return path.resolve()


def is_wsl():
    return "microsoft" in os.uname().release.lower()


def windows_path(path):
    result = subprocess.run(
        ["wslpath", "-m", str(path)], check=True, text=True,
        stdout=subprocess.PIPE
    )
    return result.stdout.strip()


def backend_path(path, backend):
    if backend == "xsim" and is_wsl():
        return windows_path(path)
    return str(path)


def path_value(base_dir, value, backend, required_paths):
    if not isinstance(value, dict) or set(value) != {"path"}:
        raise SystemExit("path plusargs must use {\"path\": \"...\"}")
    path = resolve_path(base_dir, value["path"])
    required_paths.append(path)
    return backend_path(path, backend)


def symbol_value(base_dir, value, required_paths, allow_missing):
    if set(value) != {"symbol", "file"}:
        raise SystemExit(
            "symbol plusargs must use "
            "{\"symbol\": \"NAME\", \"file\": \"...\"}"
        )
    symbol = value["symbol"]
    if not isinstance(symbol, str) or not symbol:
        raise SystemExit("symbol name must be a non-empty string")
    symbol_file = resolve_path(base_dir, value["file"])
    required_paths.append(symbol_file)
    if not symbol_file.is_file():
        if allow_missing:
            return f"<{symbol}>"
        raise SystemExit(
            f"symbol file is missing: {symbol_file}\nRun again with --prepare."
        )

    matches = []
    for line in symbol_file.read_text(encoding="ascii").splitlines():
        fields = line.split()
        if len(fields) == 2 and fields[1] == symbol:
            matches.append(fields[0])
    if len(matches) != 1:
        raise SystemExit(
            f"{symbol_file}: expected exactly one definition of {symbol}, "
            f"found {len(matches)}"
        )
    try:
        address = int(matches[0], 16)
    except ValueError as exc:
        raise SystemExit(
            f"{symbol_file}: invalid address for {symbol}: {matches[0]}"
        ) from exc
    return f"0x{address:08x}"


def build_plusargs(scenario_path, scenario, backend, allow_missing=False):
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
            rendered = backend_path(path, backend)
        result.append(f"+{plusarg_name}={rendered}")

    for name, value in scenario.get("plusargs", {}).items():
        if isinstance(value, dict):
            if set(value) == {"path"}:
                value = path_value(base_dir, value, backend, required_paths)
            elif "symbol" in value:
                value = symbol_value(base_dir, value, required_paths, allow_missing)
            else:
                raise SystemExit(f"{scenario_path}: invalid structured plusarg {name}")
        elif isinstance(value, bool):
            if value:
                result.append(f"+{name}")
            continue
        result.append(f"+{name}={value}")

    for flag in scenario.get("flags", []):
        if not isinstance(flag, str) or not flag or "=" in flag:
            raise SystemExit(f"{scenario_path}: invalid flag {flag!r}")
        result.append("+" + flag)
    return result, required_paths


def merge_extra_plusargs(plusargs, extra):
    override_names = {value[1:].split("=", 1)[0] for value in extra}
    kept = [value for value in plusargs
            if value[1:].split("=", 1)[0] not in override_names]
    return kept + extra


def validate_backend(scenario_path, scenario, backend):
    supported = scenario.get("supported_backends", list(SUPPORTED_BACKENDS))
    if not isinstance(supported, list) or not supported:
        raise SystemExit(f"{scenario_path}: supported_backends must be an array")
    if backend not in supported:
        raise SystemExit(
            f"{scenario_path}: backend {backend} is not supported; "
            f"choose one of {', '.join(supported)}"
        )


def run_command(command, cwd, dry_run):
    print(f"[SIM] cwd: {cwd}", flush=True)
    print(f"[SIM] command: {shlex.join(str(value) for value in command)}", flush=True)
    if dry_run:
        return
    subprocess.run(command, cwd=cwd, check=True)


def run_prepare(scenario_path, scenario, dry_run):
    prepare = scenario.get("prepare")
    if not prepare:
        raise SystemExit(f"{scenario_path}: no prepare command is defined")
    if not isinstance(prepare.get("command"), list) or not prepare["command"]:
        raise SystemExit(f"{scenario_path}: prepare.command must be a non-empty array")
    cwd = resolve_path(scenario_path.parent, prepare.get("cwd", "."))
    run_command(prepare["command"], cwd, dry_run)


def find_vivado(requested):
    candidates = [requested, os.environ.get("VIVADO"), shutil.which("vivado")]
    if is_wsl():
        candidates.extend([
            "/mnt/d/Xilinx/Vivado/2019.2/bin/vivado.bat",
            "/mnt/c/Xilinx/Vivado/2019.2/bin/vivado.bat",
        ])
    for candidate in candidates:
        if not candidate:
            continue
        path = Path(candidate)
        if path.exists() or shutil.which(candidate):
            return path.resolve() if path.exists() else Path(candidate)
    raise SystemExit("Vivado not found; pass --vivado or set VIVADO")


def vivado_command(vivado, arguments):
    if is_wsl() and vivado.suffix.lower() == ".bat":
        return ["cmd.exe", "/d", "/c", windows_path(vivado)] + arguments
    return [str(vivado)] + arguments


def run_xsim(vivado, plusargs, recreate, dry_run):
    project = ROOT_DIR / "fpga/project/Loongson_Soc.xpr"
    if recreate:
        create_script = ROOT_DIR / "fpga/create_project.tcl"
        command = vivado_command(vivado, [
            "-mode", "batch", "-source", backend_path(create_script, "xsim")
        ])
        run_command(command, ROOT_DIR / "fpga", dry_run)
    if not dry_run and not project.exists():
        raise SystemExit("Vivado project is missing; use --recreate-project")

    run_script = ROOT_DIR / "sim/xsim/run.tcl"
    encoded_plusargs = []
    for plusarg in plusargs:
        value = plusarg[1:]
        if "=" in value:
            name, value = value.split("=", 1)
            encoded_plusargs.extend(["--plusarg-value", name, value])
        else:
            encoded_plusargs.extend(["--plusarg-flag", value])

    arguments = [
        "-mode", "batch", "-source", backend_path(run_script, "xsim"),
        "-tclargs", backend_path(project, "xsim"),
    ] + encoded_plusargs
    run_command(vivado_command(vivado, arguments), ROOT_DIR / "fpga", dry_run)


def run_suite(args, suite_path, suite, extra):
    cases = suite.get("cases")
    if not isinstance(cases, list) or not cases or not all(
        isinstance(case, str) and case for case in cases
    ):
        raise SystemExit(f"{suite_path}: cases must be a non-empty string array")

    print(f"[SIM] suite: {suite.get('name', suite_path.stem)}", flush=True)
    if args.prepare:
        run_prepare(suite_path, suite, args.dry_run)

    recreated = False
    suite_backend = args.backend or suite.get("backend")
    case_runs = []
    for case_name in cases:
        case_path = resolve_path(suite_path.parent, case_name)
        _, case = load_scenario(case_path)
        backend = suite_backend or case.get("backend", "verilator")
        validate_backend(case_path, case, backend)
        case_runs.append((case_path, backend))

    for case_path, backend in case_runs:
        command = [sys.executable, str(Path(__file__).resolve()), str(case_path),
                   "--backend", backend]
        if args.vivado:
            command.extend(["--vivado", args.vivado])
        if args.recreate_project and backend == "xsim" and not recreated:
            command.append("--recreate-project")
            recreated = True
        command.extend(extra)
        run_command(command, ROOT_DIR, args.dry_run)

    result = "dry run complete" if args.dry_run else "PASS"
    print(f"[SIM] suite {result}: {suite.get('name', suite_path.stem)}", flush=True)


def main():
    args, extra = parse_args()
    scenario_path, scenario = load_scenario(args.scenario)
    if "cases" in scenario:
        run_suite(args, scenario_path, scenario, extra)
        return
    backend = args.backend or scenario.get("backend", "verilator")
    if backend not in SUPPORTED_BACKENDS:
        raise SystemExit(f"unsupported backend: {backend}")
    validate_backend(scenario_path, scenario, backend)

    print(f"[SIM] scenario: {scenario.get('name', scenario_path.stem)}", flush=True)
    if args.prepare:
        run_prepare(scenario_path, scenario, args.dry_run)

    plusargs, required_paths = build_plusargs(
        scenario_path, scenario, backend, allow_missing=args.dry_run
    )
    if not args.dry_run:
        missing = [path for path in required_paths if not path.is_file()]
        if missing:
            lines = "\n".join(f"  {path}" for path in missing)
            raise SystemExit(f"scenario artifacts are missing:\n{lines}\nRun again with --prepare.")
    plusargs = merge_extra_plusargs(plusargs, extra)

    if backend == "verilator":
        command = [str(ROOT_DIR / "sim/verilator/run_verilator.sh")] + plusargs
        run_command(command, ROOT_DIR, args.dry_run)
    else:
        run_xsim(find_vivado(args.vivado), plusargs,
                 args.recreate_project, args.dry_run)


if __name__ == "__main__":
    try:
        main()
    except subprocess.CalledProcessError as exc:
        raise SystemExit(exc.returncode) from exc
