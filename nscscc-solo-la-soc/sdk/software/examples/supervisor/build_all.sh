#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
BUILD_DIR="$ROOT_DIR/build"
KERNEL_DIR="$ROOT_DIR/kernel"
SDK_DIR=$(cd "$ROOT_DIR/../../.." && pwd)
INSTALL_MODE=""
EXT_IMAGE=""

if [[ -v GCCPREFIX ]]; then
    CROSS_PREFIX=$GCCPREFIX
else
    CROSS_PREFIX=loongarch32r-linux-gnusf-
fi

CROSS_CC=${CROSS_PREFIX}gcc
CROSS_LD=${CROSS_PREFIX}ld
CROSS_OBJCOPY=${CROSS_PREFIX}objcopy
CROSS_OBJDUMP=${CROSS_PREFIX}objdump
CROSS_NM=${CROSS_PREFIX}nm
HOSTCC=${HOSTCC:-gcc}
PYTHON=${PYTHON:-python3}

usage() {
    cat <<'EOF'
Usage: ./build_all.sh [options]

Generate all supervisor artifacts under build/.

Options:
  --install auto|uncache  Install the selected BaseRAM MIF to sdk/axi_ram.mif.
  --ext matrix            Also install MATRIX data to sdk/ext_ram.mif.
  --clean                 Remove generated artifacts and exit.
  -h, --help              Show this help.
EOF
}

while (($#)); do
    case "$1" in
        --install)
            [[ $# -ge 2 ]] || { echo "--install requires auto or uncache" >&2; exit 2; }
            INSTALL_MODE=$2
            shift 2
            ;;
        --ext)
            [[ $# -ge 2 ]] || { echo "--ext requires matrix" >&2; exit 2; }
            EXT_IMAGE=$2
            shift 2
            ;;
        --clean)
            rm -rf "$BUILD_DIR"
            make -C "$KERNEL_DIR" clean >/dev/null
            exit 0
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "unknown option: $1" >&2
            usage >&2
            exit 2
            ;;
    esac
done

case "$INSTALL_MODE" in
    ""|auto|uncache) ;;
    *) echo "invalid install mode: $INSTALL_MODE" >&2; exit 2 ;;
esac
case "$EXT_IMAGE" in
    ""|matrix) ;;
    *) echo "invalid ExtRAM image: $EXT_IMAGE" >&2; exit 2 ;;
esac

for command in make "$PYTHON" "$HOSTCC" "$CROSS_CC" "$CROSS_LD" \
    "$CROSS_OBJCOPY" "$CROSS_OBJDUMP" "$CROSS_NM"; do
    command -v "$command" >/dev/null || {
        echo "required command not found: $command" >&2
        exit 1
    }
done
"$PYTHON" -c 'import numpy' 2>/dev/null || {
    echo "Python package numpy is required" >&2
    exit 1
}

TMP_DIR=$(mktemp -d)
cleanup() {
    make -C "$KERNEL_DIR" clean >/dev/null 2>&1 || true
    rm -rf "$TMP_DIR"
}
trap cleanup EXIT

rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR/kernel" "$BUILD_DIR/utility"

build_kernel() {
    local mode=$1
    local destination="$BUILD_DIR/kernel/$mode"

    echo "[BUILD] kernel ($mode)"
    make -C "$KERNEL_DIR" clean >/dev/null
    make -C "$KERNEL_DIR" GCCPREFIX="$CROSS_PREFIX" CACHE_MODE="$mode" all
    mkdir -p "$destination"
    cp "$KERNEL_DIR/kernel.elf" "$destination/"
    cp "$KERNEL_DIR/kernel.bin" "$destination/"
    cp "$KERNEL_DIR/kernel.s" "$destination/"
    cp "$KERNEL_DIR/axi_ram.mif" "$destination/"
    "$CROSS_NM" -n "$KERNEL_DIR/kernel.elf" \
        | awk '$3 ~ /^UTEST_/ {print $1, $3}' \
        > "$destination/utest_symbols.txt"
}

build_kernel auto
build_kernel uncache

echo "[BUILD] STREAM data"
"$PYTHON" "$ROOT_DIR/utility/stream/gen_stream.py" \
    --kernel-bin "$BUILD_DIR/kernel/auto/kernel.bin" \
    --output-dir "$BUILD_DIR/utility/stream"

echo "[BUILD] MATRIX data"
"$PYTHON" "$ROOT_DIR/utility/matrix/gen_matrix.py" \
    --output-dir "$BUILD_DIR/utility/matrix"

echo "[BUILD] MIXED data"
"$PYTHON" "$ROOT_DIR/utility/mixed/gen_mixed.py" \
    --output-dir "$BUILD_DIR/utility/mixed"

echo "[BUILD] CryptoNight reference"
mkdir -p "$BUILD_DIR/utility/crypto"
"$HOSTCC" -std=c11 -O2 -Wall -Wextra -Werror \
    "$ROOT_DIR/utility/crypto/gen_cryptonight.c" \
    -o "$TMP_DIR/gen_cryptonight"
"$TMP_DIR/gen_cryptonight" "$BUILD_DIR/utility/crypto/crypto.bin"
"$PYTHON" "$ROOT_DIR/utility/bin_to_mem.py" \
    "$BUILD_DIR/utility/crypto/crypto.bin" \
    "$BUILD_DIR/utility/crypto/crypto.mif"

echo "[BUILD] Fibonacci example"
mkdir -p "$BUILD_DIR/utility/fibonacci"
"$CROSS_CC" -c -mabi=ilp32s -g "-fdebug-prefix-map=$ROOT_DIR=." \
    "$ROOT_DIR/utility/fibonacci/fibonacci.S" \
    -o "$TMP_DIR/fibonacci.o"
"$CROSS_LD" -Ttext 0x1c300000 -e fibonacci \
    "$TMP_DIR/fibonacci.o" \
    -o "$BUILD_DIR/utility/fibonacci/fibonacci.elf"
"$CROSS_OBJCOPY" -j .text -O binary \
    "$BUILD_DIR/utility/fibonacci/fibonacci.elf" \
    "$BUILD_DIR/utility/fibonacci/fibonacci.bin"
(
    cd "$BUILD_DIR/utility/fibonacci"
    "$CROSS_OBJDUMP" -d -S -l fibonacci.elf > fibonacci.disasm
)
"$PYTHON" "$ROOT_DIR/utility/bin_to_mem.py" \
    "$BUILD_DIR/utility/fibonacci/fibonacci.bin" \
    "$BUILD_DIR/utility/fibonacci/fibonacci.mif"
"$PYTHON" "$ROOT_DIR/utility/bin_to_mem.py" \
    "$BUILD_DIR/utility/fibonacci/fibonacci.bin" \
    "$BUILD_DIR/utility/fibonacci/fibonacci.mem"

"$PYTHON" - "$BUILD_DIR" <<'PY'
import hashlib
import sys
from pathlib import Path

root = Path(sys.argv[1])
lines = []
for path in sorted(root.rglob("*")):
    if path.is_file() and path.name != "SHA256SUMS":
        digest = hashlib.sha256(path.read_bytes()).hexdigest()
        lines.append(f"{digest}  {path.relative_to(root).as_posix()}\n")
(root / "SHA256SUMS").write_text("".join(lines), encoding="ascii")
PY

if [[ -n "$INSTALL_MODE" ]]; then
    cp "$BUILD_DIR/kernel/$INSTALL_MODE/axi_ram.mif" "$SDK_DIR/axi_ram.mif"
    echo "[INSTALL] sdk/axi_ram.mif <- kernel/$INSTALL_MODE"
fi
if [[ "$EXT_IMAGE" == matrix ]]; then
    cp "$BUILD_DIR/utility/matrix/matrix.mif" "$SDK_DIR/ext_ram.mif"
    echo "[INSTALL] sdk/ext_ram.mif <- MATRIX"
fi

echo "[DONE] artifacts: $BUILD_DIR"
