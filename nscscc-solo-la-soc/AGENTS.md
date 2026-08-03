# Repository Guidelines

## Project Structure & Module Organization

The hardware top is `rtl/soc_top.v`; shared buses, UART, RAM wrappers, PLL, and peripherals live under `rtl/ip/`. Student CPU RTL belongs in `rtl/ip/myCPU/` and must provide module `core_top`, but its internal hierarchy and filenames are unrestricted. FPGA constraints and reproducible Vivado scripts are in `fpga/`. Generic simulation infrastructure is under `sim/`, while software-owned scenarios are kept beside the software, currently in `sdk/software/examples/supervisor/sim/`. Do not put program addresses or generated MIF paths in RTL.

## Build, Test, and Development Commands

- `cd sdk/software/examples/supervisor && ./build_all.sh`: generate both kernel modes, workload data, reference results, and checksums under ignored `build/`.
- `python3 sim/run.py sdk/software/examples/supervisor/sim/suite.json`: run the complete Verilator supervisor regression using existing artifacts.
- Add `--prepare` to the previous command after software changes; preparation runs once for the suite.
- `python3 sim/run.py sdk/software/examples/supervisor/sim/cases/simple.json --backend xsim --recreate-project --vivado <vivado.bat>`: run a Windows Vivado XSIM smoke test from WSL.
- `cd fpga && vivado -mode batch -source create_project.tcl`: recreate the project.
- `cd fpga && vivado -mode batch -source build_bitstream.tcl`: synthesize, implement, and generate the bitstream.

## Long-Running Tool Tasks (Vivado/Docker)

- Run Vivado builds **foreground-blocking**: `docker run --rm -v ...:/workspace vivado:2019.2 bash -c "source /opt/Xilinx/Vivado/2019.2/settings64.sh && vivado -mode batch -source flow/xxx.tcl" 2>&1 | tee /tmp/opencode/run.log`. The command returns when Vivado exits; set a generous timeout instead of backgrounding or polling.
- NEVER poll with `pgrep -f vivado` (or any `-f` pattern the calling shell also contains): the pattern matches the polling shell itself, the loop never exits, and a finished run looks hung. Check container status with `docker ps` instead.
- Read results from the log/report files immediately after the run; do not re-run the same command.

## GitLab CI Submission

- **Before any push to the competition GitLab, read `../docs/CI-WORKFLOW.md` and use `../scripts/submit-ci.sh`.** Never `git push gitlab <dev-branch>` directly: the pre-receive hook rejects anything inconsistent with protected `main`.
- When adding a NEW `.sv/.v` file under `rtl/`, add a matching symlink in `../src/soc/<same-dir>/` and commit it, or the CI branch will miss the file (Verilator simulation reads `rtl/` directly and will NOT catch this).

## Coding Style & Naming Conventions

Follow existing lowercase underscore-separated Verilog names and preserve local indentation. Makefile recipes require tabs. Use `apply_patch` for manual edits. Keep CPU-specific implementation inside `rtl/ip/myCPU/`; only the `core_top` interface is an SoC contract. Never commit Vivado projects, `.Xil`, generated IP output products, simulator object directories, waveforms, binaries, or MIF files.

## Timing Optimization Forbidden Practices (HARD RULE)

These were all actually tried during the 100MHz push and each one is forbidden because of its root cause, not just by rule:

1. **Non-default synthesis/implementation strategies (Performance_Explore, Flow_PerfOptimized_high, ...)** — REASON: CI always runs the default strategy (`run_vivado/flow/` is pre-receive protected); PerfExplore is a randomized exploration whose results are not reproducible. A "pass" under a strategy is a mirage that CI can never reproduce.
2. **Changing timing-constraint semantics to move the WNS (e.g. re-homing I/O delays to a different clock domain, fake generated clocks, relaxing critical-path constraints)** — REASON: `run_vivado/constraints/soc.xdc` is the exact constraint CI copies and checks; editing it moves the goalposts instead of meeting them, and the board-level SRAM timing still must really hold.
3. **Backgrounding Vivado and polling for completion (nohup, `pgrep -f vivado`, while loops)** — REASON: `pgrep -f` self-matches the polling shell and never exits; decisions get made on a hallucinated "still running". Run foreground-blocking only.
4. **Sourcing a tcl script that ends with `exit`** — REASON: `source` is inlined, so the `exit` kills the whole session after the first step — a fake success (log looks complete, only step 1 ran). Verify actual results before proceeding.
5. **Reading/writing `.xci` directly (or committing Vivado's silent `upgrade_ip` rewrites of it)** — REASON: the xci is the tracked IP configuration the CI build starts from; hand-editing bypasses Vivado's legality checks, and tool-format rewrites are not design intent. Restore with `git checkout` and inspect after any Vivado run.
6. **Unconfirmed git operations (git reset --hard moving HEAD, deleting workspace files incl. untracked experiment artifacts)** — REASON: both are irreversible; branch history and workspace are shared assets.
7. **Putting experiment scripts inside `run_vivado/flow/`** — REASON: pre-receive hook hard-rejects any change there; the push fails and the branch is polluted.
8. **Merging multiple distinct changes into one commit** — REASON: a regression cannot be bisected to the offending change.
9. **Silently paying IPC cost for timing (e.g. unconditionally registering the EX redirect)** — REASON: not sacrificing IPC is the core goal; a silent sacrifice violates it. Must be announced and justified first.

The only acceptable levers are: RTL changes, XDC placement/timing constraints, default-strategy WNS, and IPC-preserving restructuring — verified by the 5-step loop (difftest IPC baseline → fix → full difftest + IPC proof → synthesis margin WNS>2ns → implementation WNS≥0 with 40-min fuse).

## Cache Storage Instantiation (HARD RULE)

Cache storage (and any other inferable RAM) MUST be instantiated as `ram_sdpram` instances, one per read port, never as in-module arrays with `ram_style` attributes. Vivado 2019.2 does not infer BRAM/LUTRAM macros from multi-dimensional in-module arrays or from arrays with multiple/registered-complex read ports — it silently expands them into LUT logic (~24k Unisim elements in the two-level cache), and implementation routing never converges. Concretely:

- Data memory: `ram_sdpram` with `READ_LATENCY=1` (per-way x per-word instances) so it maps to BRAM.
- Tag/dirty/PLRU (0-cycle combinational read required): `ram_sdpram` with `READ_LATENCY=0` (per-way instances) so it maps to LUTRAM macros.
- One read port per instance: converge all combinational reads on a single address mux, and capture multi-cycle-away reads (e.g. fill-write-side tag/dirty) into registers at the moment the port reads the right index. Never let the port switch away from the request's index while a 0-cycle hit check runs.
- Verify with `report_utilization` after synthesis (check Block RAM tiles and LUT-as-memory counts), not only with simulation.

## Testing Guidelines

Run the affected software build and at least the SIMPLE Verilator scenario for narrow changes. Changes to RTL, memory, UART, cache handling, or simulation control require the full Verilator suite and a Windows Vivado XSIM smoke test. XSIM loads BaseRAM and ExtRAM through runtime `base_ram_mif` and `ext_ram_mif` plusargs. Report exact commands and any test not run.

## Commit & Pull Request Guidelines

Use short imperative subjects and keep commits focused by area. Pull requests must describe behavioral impact, list build and simulation commands, and identify required Vivado/toolchain versions. Include waveforms or timing reports only when they support a hardware finding.
