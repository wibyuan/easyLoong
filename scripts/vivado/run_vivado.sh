#!/bin/bash
# Vivado 2019.2 docker pipeline for the 100MHz push (default strategy only —
# the CI runs the default strategy; PerfExplore etc. are forbidden).
#
# Usage:
#   scripts/vivado/run_vivado.sh create   # recreate the project (RTL + xci + XDC)
#   scripts/vivado/run_vivado.sh synth    # create + synthesize + reports
#   scripts/vivado/run_vivado.sh impl     # create + synthesize + implement + reports
#
# Notes:
#   - The Vivado image is `vivado:2019.2`; the repo root is mounted at /workspace.
#   - Vivado regenerates the PLL output products (clk_pll_sim_netlist.v, .dcp,
#     .veo, .xml, ...) into src/soc/xilinx_ip/clk_pll/ on every run.  The
#     create_project.tcl globs them as sources and synthesis fails with
#     "Synth 8-5832: source file was generated for simulation".  They are
#     removed before each run (they are regenerated artifacts; the .xci is
#     the source of truth).
#   - After any run, check `git status src/soc/xilinx_ip/` — a silent
#     upgrade_ip rewrite of the .xci must be restored with `git checkout`.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DOCKER_RUN="docker run --rm -v ${ROOT}:/workspace vivado:2019.2 bash -c"

run_create() {
    $DOCKER_RUN "source /opt/Xilinx/Vivado/2019.2/settings64.sh && cd /workspace/run_vivado && vivado -mode batch -source flow/create_vivado_project.tcl"
}

clean_pll_products() {
    local dir="${ROOT}/src/soc/xilinx_ip/clk_pll"
    rm -f "${dir}"/clk_pll.dcp "${dir}"/clk_pll.veo "${dir}"/clk_pll.xml \
          "${dir}"/clk_pll_sim_netlist.v "${dir}"/clk_pll_sim_netlist.vhdl \
          "${dir}"/clk_pll_stub.v "${dir}"/clk_pll_stub.vhdl
}

run_synth() {
    $DOCKER_RUN "source /opt/Xilinx/Vivado/2019.2/settings64.sh && vivado -mode batch -source /workspace/scripts/vivado/synth.tcl"
}

run_impl() {
    $DOCKER_RUN "source /opt/Xilinx/Vivado/2019.2/settings64.sh && vivado -mode batch -source /workspace/scripts/vivado/impl.tcl"
}

# Archive the run's timing/utilization reports under
# run_vivado/reports/<timestamp>-<commit>/ so every run's WNS evidence is
# preserved in the repo (the reports under run_vivado/project/ are
# overwritten by the next run).  Call this after every synth/impl run.
archive_reports() {
    local out="${ROOT}/run_vivado/reports/$(date +%Y%m%d-%H%M%S)-$(git -C "${ROOT}" rev-parse --short HEAD 2>/dev/null || echo nogit)$(git -C "${ROOT}" status --porcelain 2>/dev/null | grep -qv '^??' && echo -dirty || true)"
    mkdir -p "${out}"
    local f
    for f in synth_timing_summary.rpt synth_critical_paths.rpt synth_util_hier.rpt \
             impl_timing_summary.rpt impl_critical_paths.rpt impl_utilization.rpt; do
        if [ -f "${ROOT}/run_vivado/project/${f}" ]; then
            cp "${ROOT}/run_vivado/project/${f}" "${out}/"
        fi
    done
    echo "reports archived: ${out}"
}

case "${1:-}" in
    create)
        clean_pll_products
        run_create
        ;;
    synth)
        clean_pll_products
        run_create
        run_synth
        echo "SYNTH WNS: $(grep -E '^\s+-?[0-9.]+' "${ROOT}/run_vivado/project/synth_timing_summary.rpt" | head -1 | awk '{print $1}')"
        archive_reports
        ;;
    impl)
        clean_pll_products
        run_create
        run_synth
        run_impl
        echo "SYNTH WNS: $(grep -E '^\s+-?[0-9.]+' "${ROOT}/run_vivado/project/synth_timing_summary.rpt" | head -1 | awk '{print $1}')"
        echo "IMPL  WNS: $(grep -E '^\s+-?[0-9.]+' "${ROOT}/run_vivado/project/impl_timing_summary.rpt" | head -1 | awk '{print $1}')"
        archive_reports
        ;;
    *)
        echo "usage: $0 {create|synth|impl}"
        exit 1
        ;;
esac
