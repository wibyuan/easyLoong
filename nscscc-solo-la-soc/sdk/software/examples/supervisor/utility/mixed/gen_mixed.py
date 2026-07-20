#!/usr/bin/env python3
# -*- encoding=utf-8 -*-

import argparse
from pathlib import Path
import struct

SRC_PHYS = 0x1C500000
DST_PHYS = 0x1C510000
SIG_PHYS = 0x1C520000

WORD_COUNT = 0x4000
STRIDE_ITERS = 0x2000
INDEX_MASK = 0x3FFF
INIT_XOR = 0x9E37


def u32(value):
    return value & 0xFFFFFFFF


def pack_words(words):
    return b"".join(struct.pack("<I", u32(word)) for word in words)


def write_hex(path, words):
    with open(path, "w") as f:
        for word in words:
            f.write(f"{u32(word):08x}\n")


def write_mif(path, data):
    with open(path, "w") as f:
        for offset in range(0, len(data), 4):
            word = int.from_bytes(data[offset:offset + 4], byteorder="little")
            f.write(f"{word:032b}\n")


def run_mixed():
    src = [0] * WORD_COUNT
    dst = [0] * WORD_COUNT

    # mixed_fill
    for t0 in range(WORD_COUNT):
        t2 = u32(t0 ^ INIT_XOR)
        t3 = u32(t0 << 3)
        src[t0] = u32(t2 ^ t3)

    # mixed_stream
    s0 = s1 = s2 = s3 = 0
    for i in range(0, WORD_COUNT, 4):
        t4, t5, t6, t7 = src[i:i + 4]
        s0 = u32(s0 + t4)
        s1 = u32(s1 ^ t5)
        s2 = u32(s2 + t6)
        s3 = u32(s3 ^ t7)
        dst[i + 0] = s0
        dst[i + 1] = s1
        dst[i + 2] = s2
        dst[i + 3] = s3

    # mixed_stride
    t1 = u32(s0 ^ s1)
    for _ in range(STRIDE_ITERS):
        idx = t1 & INDEX_MASK
        t4 = src[idx]
        t1 = u32(t1 ^ t4)
        t1 = u32(t1 ^ u32(t1 << 5))
        t1 = u32(t1 ^ (t1 >> 7))
        if t1 & 0x1:
            s0 = u32(s0 + t4)
        else:
            s1 = u32(s1 ^ t4)
        src[idx] = t1

    signature = [s0, s1, s2, s3, t1]
    return src, dst, signature


def main():
    parser = argparse.ArgumentParser(description="Generate MIXED reference images.")
    parser.add_argument(
        "--output-dir",
        type=Path,
        default=Path(__file__).resolve().parent,
        help="directory for generated files",
    )
    args = parser.parse_args()

    out_dir = args.output_dir.resolve()
    out_dir.mkdir(parents=True, exist_ok=True)
    src, dst, signature = run_mixed()

    image = pack_words(src) + pack_words(dst) + pack_words(signature)
    signature_data = pack_words(signature)

    (out_dir / "mixed.bin").write_bytes(image)
    (out_dir / "mixed_signature.bin").write_bytes(signature_data)
    write_mif(out_dir / "mixed.mif", image)
    write_mif(out_dir / "mixed_signature.mif", signature_data)
    write_hex(out_dir / "mixed.out", signature)

    print(f"mixed.bin base phys: 0x{SRC_PHYS:08x}")
    print(f"mixed.bin size:      0x{len(image):x} bytes")
    print(f"signature phys:      0x{SIG_PHYS:08x}")
    print("signature words:")
    for word in signature:
        print(f"{word:08x}")


if __name__ == "__main__":
    main()
