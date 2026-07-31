#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
RTL_DIR="${ROOT_DIR}/nscscc-solo-la-soc/rtl"
MYCPU_DIR="${RTL_DIR}/ip/myCPU"
TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OBJ_DIR="${TEST_DIR}/obj_dir"
DIFFTEST_DIR="${ROOT_DIR}/difftest"

VERILOG_FILES=(
    "${TEST_DIR}/test_tb.sv"
    "${TEST_DIR}/inst_rom.sv"
    "${MYCPU_DIR}/core.sv"
    "${MYCPU_DIR}/common.sv"
    "${MYCPU_DIR}/fetch_unit.sv"
    "${MYCPU_DIR}/decode.sv"
    "${MYCPU_DIR}/alu.sv"
    "${MYCPU_DIR}/bcu.sv"
    "${MYCPU_DIR}/npc.sv"
    "${MYCPU_DIR}/csr_regfile.sv"
    "${MYCPU_DIR}/lsu.sv"
    "${MYCPU_DIR}/regfile.sv"
    "${MYCPU_DIR}/hazard_unit.sv"
    "${MYCPU_DIR}/branch_predictor.sv"
    "${MYCPU_DIR}/pipeline_reg.sv"
    "${MYCPU_DIR}/icache.sv"
    "${MYCPU_DIR}/difftest.v"
)

BUILD_STAMP="${OBJ_DIR}/.build_stamp"

# --- incremental build decision ---
CURRENT_HASH=$(
    sha256sum \
        "${VERILOG_FILES[@]}" \
        "${TEST_DIR}/test_main.cpp" \
        "${DIFFTEST_DIR}/difftest_interface.cpp" \
        "${DIFFTEST_DIR}/difftest_dut.cpp" \
        | sha256sum | awk '{print $1}'
)

REBUILD=0
if [[ ! -f "${BUILD_STAMP}" ]]; then
    REBUILD=1
elif [[ "$(cat "${BUILD_STAMP}")" != "${CURRENT_HASH}" ]]; then
    REBUILD=1
fi

if [[ "${REBUILD}" == "1" ]]; then
    mkdir -p "${OBJ_DIR}"
    verilator \
        --cc --exe --build \
        --top-module test_icache_redirect_stale \
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
        -Wno-UNOPTFLAT \
        -I"${MYCPU_DIR}" \
        -I"${RTL_DIR}" \
        -I"${DIFFTEST_DIR}" \
        -I"${ROOT_DIR}" \
        "${VERILOG_FILES[@]}" \
        "${TEST_DIR}/test_main.cpp" \
        "${DIFFTEST_DIR}/difftest_interface.cpp" \
        "${DIFFTEST_DIR}/difftest_dut.cpp" \
        -LDFLAGS "-ldl" \
        -CFLAGS "-I${DIFFTEST_DIR} -I${ROOT_DIR}"
    printf '%s\n' "${CURRENT_HASH}" > "${BUILD_STAMP}"
fi

cd "${ROOT_DIR}"
"${OBJ_DIR}/Vtest_icache_redirect_stale" "${TEST_DIR}/test_prog.bin"
