#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

mapfile -t VERILOG_FILES < <(
    {
        find rtl -type f \( -name '*.v' -o -name '*.sv' \) \
            ! -path 'rtl/ip/PLL_2019_2/*' \
            ! -path '*/.Xil/*'
        find sim -maxdepth 1 -type f \( -name '*.v' -o -name '*.sv' \) \
            ! -name 'mycpu_tb.v'
    } | sort
)

mapfile -t HEADER_FILES < <(
    find rtl sim -type f \( -name '*.h' -o -name '*.vh' \) \
        ! -path '*/.Xil/*' \
        ! -path 'sim/verilator/obj_dir/*' \
        | sort
)

mapfile -t MYCPU_INCLUDE_DIRS < <(
    find rtl/ip/myCPU -type d ! -path '*/.Xil*' | sort | sed 's#^#-I#'
)

VERILATOR_DEFINES=()
if [[ "${MYCPU_OPENLA500_PROBES:-0}" == "1" ]]; then
    VERILATOR_DEFINES+=("-DMYCPU_OPENLA500_PROBES")
fi

MODE_SELECTED=0
BASE_IMAGE_SELECTED=0
EXT_IMAGE_SELECTED=0
for arg in "$@"; do
    case "$arg" in
        +term_port=*|+supervisor_entry=*|+supervisor_uart_check|+supervisor_a_words=*|+supervisor_a_file=*)
            MODE_SELECTED=1
            ;;
        +base_ram_mif=*)
            BASE_IMAGE_SELECTED=1
            ;;
        +ext_ram_mif=*)
            EXT_IMAGE_SELECTED=1
            ;;
    esac
done
if [[ "$MODE_SELECTED" == "0" ]]; then
    set -- "$@" +term_port=6666
fi
if [[ "$BASE_IMAGE_SELECTED" == "0" && -f sdk/axi_ram.mif ]]; then
    set -- "$@" +base_ram_mif=sdk/axi_ram.mif
fi
if [[ "$EXT_IMAGE_SELECTED" == "0" ]]; then
    if [[ -f sdk/ext_ram.mif ]]; then
        set -- "$@" +ext_ram_mif=sdk/ext_ram.mif
    else
        set -- "$@" +ext_ram_mif=none
    fi
fi

VERILATOR_BINARY=sim/verilator/obj_dir/Vverilator_tb
VERILATOR_STAMP=sim/verilator/obj_dir/.build_config
BUILD_CONFIG=$(
    {
        printf '%s\n' "$(verilator --version)"
        printf '%s\n' "MYCPU_OPENLA500_PROBES=${MYCPU_OPENLA500_PROBES:-0}"
        printf '%s\n' "${MYCPU_INCLUDE_DIRS[@]}"
        sha256sum \
            "$0" \
            sim/verilator/verilator_tb.v \
            sim/verilator/verilator_main.cpp \
            "${VERILOG_FILES[@]}" \
            "${HEADER_FILES[@]}"
    } | sha256sum | awk '{print $1}'
)
BUILD_REQUIRED=${FORCE_VERILATOR_REBUILD:-0}

if [[ ! -x "$VERILATOR_BINARY" || ! -f "$VERILATOR_STAMP" ]]; then
    BUILD_REQUIRED=1
elif [[ "$(<"$VERILATOR_STAMP")" != "$BUILD_CONFIG" ]]; then
    BUILD_REQUIRED=1
fi

if [[ "$BUILD_REQUIRED" == "1" ]]; then
    verilator \
        --cc --exe --build \
        --trace-fst \
        --trace-structs \
        --top-module verilator_tb \
        --Mdir sim/verilator/obj_dir \
        -Wno-fatal \
        -Wno-DECLFILENAME \
        -Wno-PINCONNECTEMPTY \
        -Wno-UNUSEDSIGNAL \
        -Wno-UNDRIVEN \
        -Wno-EOFNEWLINE \
        -Wno-MISINDENT \
        -Wno-DEFPARAM \
        -Wno-PINMISSING \
        -Wno-IMPLICIT \
        -Wno-WIDTHEXPAND \
        -Wno-WIDTHTRUNC \
        -Wno-CASEINCOMPLETE \
        -Wno-CASEX \
        -Wno-BLKSEQ \
        -Wno-SYNCASYNCNET \
        -Wno-MULTIDRIVEN \
        -Wno-MODDUP \
        -Wno-TIMESCALEMOD \
        "${VERILATOR_DEFINES[@]}" \
        -Irtl \
        -Irtl/ip/APB_UART/URT \
        -Isim/verilator \
        "${MYCPU_INCLUDE_DIRS[@]}" \
        sim/verilator/verilator_tb.v \
        "$ROOT_DIR/sim/verilator/verilator_main.cpp" \
        sim/verilator/difftest_interface.cpp \
        sim/verilator/difftest_dut.cpp \
        -LDFLAGS "-ldl" \
        "${VERILOG_FILES[@]}"
    printf '%s\n' "$BUILD_CONFIG" > "$VERILATOR_STAMP"
else
    echo "[VERILATOR] Reusing sim/verilator/obj_dir/Vverilator_tb"
fi

"$VERILATOR_BINARY" "$@"
