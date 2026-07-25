#!/usr/bin/env python3
import re
import sys
from pathlib import Path
from typing import List


def usage() -> None:
    print("Usage: python3 flow/check_timing.py <timing-summary-report>", file=sys.stderr)


def _parse_table_row(line: str) -> List[str]:
    return [col.strip() for col in line.strip().strip("|").split("|")]


def _extract_design_summary_wns(lines: List[str]) -> float:
    for index, line in enumerate(lines):
        if "Design Timing Summary" in line:
            for header_index, header_line in enumerate(lines[index + 1 : index + 30], index + 1):
                if "WNS" not in header_line:
                    continue

                for data_line in lines[header_index + 1 : header_index + 8]:
                    stripped = data_line.strip()
                    if not stripped or set(stripped) <= set("- "):
                        continue

                    match = re.match(r"([-+]?\d+(?:\.\d+)?)\s+", stripped)
                    if match:
                        return float(match.group(1))

    raise ValueError("No Design Timing Summary WNS value found")


def extract_wns(report: Path) -> float:
    if not report.is_file():
        raise FileNotFoundError(f"Timing summary report not found: {report}")

    lines = report.read_text(errors="replace").splitlines()

    try:
        return _extract_design_summary_wns(lines)
    except ValueError:
        pass

    for index, line in enumerate(lines):
        if "WNS" not in line:
            continue

        columns = _parse_table_row(line)
        wns_columns = [i for i, col in enumerate(columns) if re.search(r"\bWNS\b", col)]
        if not wns_columns:
            continue

        wns_column = wns_columns[0]
        for data_line in lines[index + 1 : index + 8]:
            data_columns = _parse_table_row(data_line)
            if len(data_columns) <= wns_column:
                continue

            value = data_columns[wns_column]
            if re.fullmatch(r"[-+]?\d+(?:\.\d+)?", value):
                return float(value)

    text = "\n".join(lines)
    for pattern in (
        r"\bWNS\s*\(ns\)\s*[:=]\s*([-+]?\d+(?:\.\d+)?)",
        r"\bWNS\b\s*[:=]\s*([-+]?\d+(?:\.\d+)?)",
    ):
        match = re.search(pattern, text, re.IGNORECASE)
        if match:
            return float(match.group(1))

    raise ValueError(f"No WNS value found in {report}")


def main(argv: List[str]) -> int:
    if len(argv) != 2:
        usage()
        return 2

    report = Path(argv[1])
    wns = extract_wns(report)
    print(f"WNS: {wns:.3f} ns")
    if wns <= 0:
        print(f"WARNING: WNS is not positive, got {wns:.3f} ns", file=sys.stderr)
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main(sys.argv))
    except Exception as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        sys.exit(1)
