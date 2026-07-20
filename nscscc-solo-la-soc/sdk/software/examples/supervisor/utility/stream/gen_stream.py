#!/usr/bin/env python3

import argparse
from pathlib import Path
import struct


SOURCE_OFFSET = 0x00100000
STREAM_BYTES = 0x00300000
WORD_COUNT = STREAM_BYTES // 4
MASK32 = 0xFFFFFFFF


def words_from_bytes(data):
    if len(data) % 4:
        data += bytes(4 - len(data) % 4)
    for offset in range(0, len(data), 4):
        yield int.from_bytes(data[offset:offset + 4], "little")


def stream_word(index):
    rotated = ((index << 13) | (index >> 19)) & MASK32
    return ((index * 0x9E3779B9 + 0x20260717) ^ rotated) & MASK32


def main():
    parser = argparse.ArgumentParser(
        description="Generate deterministic STREAM input and a combined BaseRAM MIF."
    )
    parser.add_argument("--kernel-bin", type=Path, required=True)
    parser.add_argument("--output-dir", type=Path, required=True)
    args = parser.parse_args()

    kernel = args.kernel_bin.read_bytes()
    if len(kernel) > SOURCE_OFFSET:
        raise SystemExit(
            f"kernel is {len(kernel)} bytes and overlaps STREAM data at "
            f"BaseRAM offset 0x{SOURCE_OFFSET:x}"
        )

    args.output_dir.mkdir(parents=True, exist_ok=True)
    input_path = args.output_dir / "stream_input.bin"
    mif_path = args.output_dir / "axi_ram.mif"

    with input_path.open("wb") as input_file, mif_path.open(
        "w", encoding="ascii", newline="\n"
    ) as mif_file:
        for word in words_from_bytes(kernel):
            mif_file.write(f"{word:032b}\n")
        mif_file.write(f"@{SOURCE_OFFSET // 4:x}\n")

        binary_chunk = bytearray()
        mif_chunk = []
        for index in range(WORD_COUNT):
            word = stream_word(index)
            binary_chunk.extend(struct.pack("<I", word))
            mif_chunk.append(f"{word:032b}\n")
            if len(mif_chunk) == 4096:
                input_file.write(binary_chunk)
                mif_file.writelines(mif_chunk)
                binary_chunk.clear()
                mif_chunk.clear()
        if mif_chunk:
            input_file.write(binary_chunk)
            mif_file.writelines(mif_chunk)

    print(f"STREAM input: {input_path} ({STREAM_BYTES} bytes)")
    print(f"STREAM BaseRAM image: {mif_path}")


if __name__ == "__main__":
    main()
