#!/usr/bin/env python3

import argparse
from pathlib import Path


def padded_words(data):
    if len(data) % 4:
        data += bytes(4 - len(data) % 4)
    for offset in range(0, len(data), 4):
        yield int.from_bytes(data[offset:offset + 4], "little")


def main():
    parser = argparse.ArgumentParser(
        description="Convert a little-endian binary to a 32-bit MIF or hex word file."
    )
    parser.add_argument("input", type=Path)
    parser.add_argument("output", type=Path)
    parser.add_argument(
        "--format",
        choices=("mif", "hex"),
        help="output format; inferred from .mif or .mem when omitted",
    )
    args = parser.parse_args()

    output_format = args.format
    if output_format is None:
        output_format = "mif" if args.output.suffix.lower() == ".mif" else "hex"

    formatter = "{word:032b}\n" if output_format == "mif" else "{word:08x}\n"
    content = "".join(
        formatter.format(word=word) for word in padded_words(args.input.read_bytes())
    )
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(content, encoding="ascii")


if __name__ == "__main__":
    main()
