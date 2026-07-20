#!/usr/bin/env python3

import argparse
from pathlib import Path

import numpy as np


MATRIX_DIM = 128
ACTIVE_DIM = 96
DEFAULT_SEED = 2026


def matrix_bytes(*matrices):
    return b"".join(
        matrix.astype("<i4", copy=False).tobytes(order="C")
        for matrix in matrices
    )


def write_hex(path, matrices):
    with path.open("w", encoding="ascii") as output:
        for matrix in matrices:
            for value in matrix.flat:
                output.write(f"{int(value) & 0xffffffff:08x}\n")


def write_mif(path, data):
    with path.open("w", encoding="ascii") as output:
        for offset in range(0, len(data), 4):
            word = int.from_bytes(data[offset:offset + 4], "little")
            output.write(f"{word:032b}\n")


def main():
    parser = argparse.ArgumentParser(description="Generate MATRIX input and reference images.")
    parser.add_argument(
        "--output-dir",
        type=Path,
        default=Path(__file__).resolve().parent,
        help="directory for generated files",
    )
    parser.add_argument(
        "--seed",
        type=int,
        default=DEFAULT_SEED,
        help=f"random seed (default: {DEFAULT_SEED})",
    )
    args = parser.parse_args()

    out_dir = args.output_dir.resolve()
    out_dir.mkdir(parents=True, exist_ok=True)

    rng = np.random.default_rng(args.seed)
    zero = np.zeros((MATRIX_DIM, MATRIX_DIM), dtype=np.int32)
    matrix_a = zero.copy()
    matrix_b = zero.copy()
    matrix_a[:ACTIVE_DIM, :ACTIVE_DIM] = rng.integers(
        -1000, 1000, size=(ACTIVE_DIM, ACTIVE_DIM), dtype=np.int32
    )
    matrix_b[:ACTIVE_DIM, :ACTIVE_DIM] = rng.integers(
        -1000, 1000, size=(ACTIVE_DIM, ACTIVE_DIM), dtype=np.int32
    )
    matrix_c = matrix_a @ matrix_b

    input_data = matrix_bytes(matrix_a, matrix_b, zero)
    expected_data = matrix_bytes(matrix_c)
    combined_data = input_data + expected_data

    (out_dir / "matrix_input.bin").write_bytes(input_data)
    (out_dir / "matrix_expected.bin").write_bytes(expected_data)
    (out_dir / "matrix.bin").write_bytes(combined_data)
    write_mif(out_dir / "matrix_input.mif", input_data)
    write_mif(out_dir / "matrix_expected.mif", expected_data)
    write_mif(out_dir / "matrix.mif", combined_data)
    write_hex(out_dir / "matrix.in", (matrix_a, matrix_b, zero))
    write_hex(out_dir / "matrix.out", (matrix_c,))

    print(f"matrix seed:          {args.seed}")
    print(f"matrix active size:   {ACTIVE_DIM} x {ACTIVE_DIM}")
    print(f"matrix.bin size:      0x{len(combined_data):x} bytes")
    print("matrix expected phys: 0x1c430000")


if __name__ == "__main__":
    main()
