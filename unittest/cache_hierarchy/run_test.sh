#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
RTL_DIR="${ROOT_DIR}/nscscc-solo-la-soc/rtl"
MYCPU_DIR="${RTL_DIR}/ip/myCPU"
TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OBJ_DIR="${TEST_DIR}/obj_dir"

VERILOG_FILES=(
    "${TEST_DIR}/test_tb.sv"
    "${MYCPU_DIR}/l1dcache.sv"
    "${MYCPU_DIR}/l2dcache.sv"
    "${MYCPU_DIR}/ram_sdpram.sv"
    "${MYCPU_DIR}/common.sv"
)

BUILD_STAMP="${OBJ_DIR}/.build_stamp"

# --- incremental build decision ---
CURRENT_HASH=$(
    sha256sum "${VERILOG_FILES[@]}" "${TEST_DIR}/test_main.cpp" \
        | sha256sum | awk '{print $1}'
)

REBUILD=0
if [[ ! -f "${BUILD_STAMP}" ]]; then
    REBUILD=1
elif [[ "$(cat "${BUILD_STAMP}")" != "${CURRENT_HASH}" ]]; then
    REBUILD=1
fi

if [[ "${REBUILD}" == "1" ]]; then
    rm -rf "${OBJ_DIR}"
    mkdir -p "${OBJ_DIR}"
    verilator \
        --cc --exe --build \
        --top-module test_tb \
        --Mdir "${OBJ_DIR}" \
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
        --timing \
        -I"${MYCPU_DIR}" \
        -I"${RTL_DIR}" \
        "${VERILOG_FILES[@]}" \
        "${TEST_DIR}/test_main.cpp"
    printf '%s\n' "${CURRENT_HASH}" > "${BUILD_STAMP}"
fi

"${OBJ_DIR}/Vtest_tb"
