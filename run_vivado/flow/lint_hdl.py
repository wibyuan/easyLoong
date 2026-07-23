#!/usr/bin/env python3
import xml.etree.ElementTree as etree
import sys
import os
from pathlib import Path
from typing import Tuple, List, Set
import shutil
import subprocess
import tempfile
import traceback
import re

def usage():
    print("Usage: python3 flow/lint_hdl.py <path-to-vivado-xpr>", file=sys.stderr)

def is_header(f: Path):
    with f.open('rb') as fd:
        return -1 == fd.read().find(b'endmodule')

def transcoding(src: Path, target: Path):
    rawdata = src.read_bytes()
    for encoding in ("utf-8-sig", "utf-8", "gb18030"):
        try:
            text = rawdata.decode(encoding)
            break
        except UnicodeDecodeError:
            continue
    else:
        print("Transcoding", src, "with replacement characters")
        text = rawdata.decode("utf-8", "replace")
    target.write_text(text, encoding="utf-8")

def parse_project(xpr: Path) -> Tuple[str, Set[str], Set[str], Set[str]]:
    prjname = os.path.splitext(xpr.name)[0]
    prjdir = xpr.parent.resolve()
    repo_root = prjdir.parent.parent
    srcdir = prjdir / (prjname + ".srcs")
    topname = ''
    target = prjdir / '.lint'

    tree = etree.parse(str(xpr))
    root = tree.getroot()
    srclist = set()
    headerlist = set()
    inclist = set()
    skipped_ip_modules = set()
    for fileset in root.findall("./FileSets/FileSet"):
        fileset_type = fileset.attrib.get('Type')
        if fileset_type not in ('DesignSrcs', 'BlockSrcs'):
            continue
        for child in fileset:
            if child.tag == 'File':
                tmp = child.attrib['Path']
                if tmp.endswith((".xci", ".xcix")):
                    skipped_ip_modules.add(Path(tmp).stem)
                    continue
                tmp = tmp.replace('$PSRCDIR', str(srcdir))
                tmp = tmp.replace('$PPRDIR', str(prjdir))
                vlog = Path(tmp).resolve()
                if not vlog.is_file():
                    print("Source file", vlog, "does not exist")
                    continue
                vlog_target = target / vlog.relative_to(repo_root)
                vlog_target.parent.mkdir(exist_ok=True, parents=True)
                transcoding(vlog, vlog_target)
                inclist.add(str(vlog_target.parent))
                if is_header(vlog_target):
                    headerlist.add(str(vlog_target))
                else:
                    srclist.add(str(vlog_target))
            elif child.tag == 'Config' and fileset_type == 'DesignSrcs':
                option = child.find("./Option[@Name='TopModule']")
                if option is not None:
                    topname = option.attrib.get('Val', '')

    generate_ip_stubs(target, skipped_ip_modules, srclist, inclist)
    return (topname, headerlist, srclist, inclist)

def verilator_supports_warning(verilator: str, env, warning: str) -> bool:
    with tempfile.TemporaryDirectory() as tmpdir:
        probe = Path(tmpdir) / "verilator_warning_probe.v"
        probe.write_text("module verilator_warning_probe; endmodule\n", encoding="utf-8")
        res = subprocess.run(
            [verilator, "--lint-only", "-Wno-" + warning, str(probe)],
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            universal_newlines=True,
            env=env,
        )
        return "Unknown warning specified" not in res.stdout

def strip_verilog_comments(text: str) -> str:
    text = re.sub(r"/\*.*?\*/", "", text, flags=re.S)
    return re.sub(r"//.*", "", text)


def infer_instance_ports(module_name: str, sources: Set[str]) -> List[str]:
    ports = set()
    instance_re = re.compile(
        r"(?<!\bmodule\s)\b"
        + re.escape(module_name)
        + r"\s*(?:#\s*\(.*?\)\s*)?[A-Za-z_][A-Za-z0-9_$]*\s*\((.*?)\)\s*;",
        re.S,
    )
    port_re = re.compile(r"\.\s*([A-Za-z_][A-Za-z0-9_$]*)\s*\(", re.S)
    for src in sorted(sources):
        text = Path(src).read_text(encoding="utf-8", errors="replace")
        code = strip_verilog_comments(text)
        for instance in instance_re.finditer(code):
            ports.update(port_re.findall(instance.group(1)))
    return sorted(ports)


def infer_ip_port_direction(port: str) -> str:
    lower = port.lower()
    output_names = {
        "p",
        "q",
        "spo",
        "dout",
        "douta",
        "doutb",
        "data_out",
        "locked",
    }
    if lower in output_names:
        return "output"
    if lower.startswith(("dout", "clk_out")):
        return "output"
    return "input"


def generate_ip_stubs(target: Path, ip_modules: Set[str], srclist: Set[str], inclist: Set[str]):
    if not ip_modules:
        return
    stub_dir = target / "ip_stubs"
    stub_dir.mkdir(exist_ok=True, parents=True)
    inclist.add(str(stub_dir))
    for module_name in sorted(ip_modules):
        if not re.fullmatch(r"[A-Za-z_][A-Za-z0-9_$]*", module_name):
            continue
        ports = infer_instance_ports(module_name, srclist)
        stub = stub_dir / (module_name + "_stub.v")
        if ports:
            port_list = ", ".join(ports)
            declarations = "\n".join("    " + infer_ip_port_direction(port) + " " + port + ";" for port in ports)
            text = (
                "(* black_box *) module {name}({ports});\n"
                "{decls}\n"
                "endmodule\n"
            ).format(name=module_name, ports=port_list, decls=declarations)
        else:
            text = "(* black_box *) module {name};\nendmodule\n".format(name=module_name)
        stub.write_text(text, encoding="utf-8")
        srclist.add(str(stub))

def find_module_body(text: str, module_name: str) -> str:
    pattern = re.compile(r"\bmodule\s+" + re.escape(module_name) + r"\b.*?\bendmodule\b", re.S)
    m = pattern.search(text)
    return m.group(0) if m else ""

def find_top_source(topname: str, srclist: Set[str]) -> Tuple[Path, str]:
    module_re = re.compile(r"\bmodule\s+" + re.escape(topname) + r"\b")
    for src in sorted(srclist):
        path = Path(src)
        text = path.read_text(encoding="utf-8", errors="replace")
        if module_re.search(strip_verilog_comments(text)):
            return path, text
    return Path(), ""

def module_is_instantiated(module_name: str, text: str) -> bool:
    code = strip_verilog_comments(text)
    pattern = re.compile(
        r"(?<!\bmodule\s)\b"
        + re.escape(module_name)
        + r"\s*(?:#\s*\(.*?\)\s*)?[A-Za-z_][A-Za-z0-9_$]*\s*\(",
        re.S,
    )
    return bool(pattern.search(code))

def extract_module_definitions(sources: Set[str]) -> Tuple[dict, dict]:
    module_sources = {}
    module_bodies = {}
    for src in sorted(sources):
        path = Path(src)
        text = path.read_text(encoding="utf-8", errors="replace")
        code = strip_verilog_comments(text)
        for m in re.finditer(r"\bmodule\s+([A-Za-z_][A-Za-z0-9_$]*)\b.*?\bendmodule\b", code, re.S):
            name = m.group(1)
            module_sources.setdefault(name, path)
            module_bodies.setdefault(name, m.group(0))
    return module_sources, module_bodies

def find_instantiated_modules(text: str, module_names: Set[str]) -> Set[str]:
    return {
        module
        for module in module_names
        if module_is_instantiated(module, text)
    }

def find_reachable_modules(topname: str, module_bodies: dict) -> Set[str]:
    reachable = set()
    pending = [topname]
    module_names = set(module_bodies)
    while pending:
        module = pending.pop()
        if module in reachable:
            continue
        reachable.add(module)
        body = module_bodies.get(module, "")
        for child in find_instantiated_modules(body, module_names - reachable):
            pending.append(child)
    return reachable

def run_design_sanity_checks(prjdir: Path, topname: str, srclist: Set[str]):
    issues = []
    top_source, top_text = find_top_source(topname, srclist)
    if not top_text:
        issues.append("Top module '{}' was not found in lint source set.".format(topname))
    else:
        for lineno, line in enumerate(top_text.splitlines(), start=1):
            if "add your code" in line.lower():
                issues.append(
                    "{}:{}: template placeholder remains in top module; the SoC integration is likely incomplete.".format(
                        top_source, lineno
                    )
                )

        module_sources, module_bodies = extract_module_definitions(srclist)
        reachable_modules = find_reachable_modules(topname, module_bodies)
        unreachable_modules = sorted(set(module_bodies) - reachable_modules)
        if len(module_bodies) >= 20 and len(unreachable_modules) > len(module_bodies) // 2:
            shown_modules = ", ".join(unreachable_modules[:12])
            if len(unreachable_modules) > 12:
                shown_modules += ", ..."
            issues.append(
                "{}: only {} of {} project modules are reachable from top '{}'; unreachable modules include: {}.".format(
                    top_source,
                    len(reachable_modules & set(module_bodies)),
                    len(module_bodies),
                    topname,
                    shown_modules,
                )
            )

    if issues:
        sanity_log = prjdir / "linter-sanity.log"
        sanity_log.write_text("\n".join(issues) + "\n", encoding="utf-8")
        print("HDL sanity check failed.")
        for issue in issues:
            print(issue)
        print("Full log:", sanity_log)
        sys.exit(1)

def run_linter(prjdir: Path, topname: str, headerlist: Set[str], srclist: Set[str], inclist: Set[str]):
    linter_log = prjdir / "linter.log"
    linter_args = prjdir / "linter.args"
    verilator = os.environ.get("VERILATOR") or shutil.which("verilator") or shutil.which("verilator_bin.exe")
    if not verilator:
        print("ERROR: verilator was not found in PATH.", file=sys.stderr)
        print("Install verilator in the CI image, set VERILATOR, or remove the HDL lint step from .gitlab-ci.yml.", file=sys.stderr)
        sys.exit(127)

    env = os.environ.copy()
    if os.name == "nt" and "VERILATOR_ROOT" not in env:
        verilator_root = Path(verilator).resolve().parent.parent / "share" / "verilator"
        if verilator_root.is_dir():
            env["VERILATOR_ROOT"] = str(verilator_root)

    timescale_warning = None
    for warning in ("TIMESCALEMOD", "TIMESCALE"):
        if verilator_supports_warning(verilator, env, warning):
            timescale_warning = warning
            break

    args = [
        verilator,
        "--lint-only",
        "-Wall",
        "-Wno-fatal",
        "-Wno-DECLFILENAME",
        "-Wno-PINCONNECTEMPTY",
        "-Wno-UNUSED",
        "-DSIMULATION=1",
    ]
    if timescale_warning:
        args.append("-Wno-" + timescale_warning)
    args += ['--top-module', topname]
    incargs = [ '-I' + i for i in inclist]
    args += incargs
    args += sorted(headerlist)
    args += srclist

    if os.name == "nt":
        response_args = [str(arg).replace("\\", "/") for arg in args[1:]]
        linter_args.write_text("\n".join(response_args) + "\n", encoding="utf-8")
        run_args = [verilator, "-f", str(linter_args)]
    else:
        run_args = args

    with linter_log.open("w", encoding="utf-8") as log:
        res = subprocess.run(run_args, stdout=log, stderr=subprocess.STDOUT, env=env)
    if res.returncode != 0:
        log_text = linter_log.read_text(encoding="utf-8", errors="replace")
        error_lines = [
            line for line in log_text.splitlines()
            if "%Error" in line or "Error:" in line or "ERROR:" in line
        ]
        print("HDL lint failed.")
        if error_lines:
            print("Key errors:")
            for line in error_lines[:20]:
                print(line)
            if len(error_lines) > 20:
                print("... {} more error lines omitted".format(len(error_lines) - 20))
        else:
            print("No explicit error line found in Verilator output.")
        print("Return code:", res.returncode)
        print("Full log:", linter_log)
        sys.exit(res.returncode)
    print("HDL lint passed.")

if __name__ == "__main__":
    try:
        if len(sys.argv) != 2:
            usage()
            sys.exit(2)
        xpr = Path(sys.argv[1])
        if not xpr.is_file():
            print("Vivado project file does not exist:", xpr, file=sys.stderr)
            sys.exit(2)
        topname, headerlist, srclist, inclist = parse_project(xpr)
        if not topname:
            print("Top module was not found in project:", xpr, file=sys.stderr)
            sys.exit(1)
        if not srclist:
            print("No Verilog source files were found in project:", xpr, file=sys.stderr)
            sys.exit(1)
        run_design_sanity_checks(xpr.parent, topname, srclist)
        run_linter(xpr.parent, topname, headerlist, srclist, inclist)
    except Exception:
        traceback.print_exc()
        sys.exit(1)
