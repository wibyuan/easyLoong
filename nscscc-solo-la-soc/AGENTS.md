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

## GitLab CI Submission

- **Before any push to the competition GitLab, read `../docs/CI-WORKFLOW.md` and use `../scripts/submit-ci.sh`.** Never `git push gitlab <dev-branch>` directly: the pre-receive hook rejects anything inconsistent with protected `main`.
- When adding a NEW `.sv/.v` file under `rtl/`, add a matching symlink in `../src/soc/<same-dir>/` and commit it, or the CI branch will miss the file (Verilator simulation reads `rtl/` directly and will NOT catch this).

## Coding Style & Naming Conventions

Follow existing lowercase underscore-separated Verilog names and preserve local indentation. Makefile recipes require tabs. Use `apply_patch` for manual edits. Keep CPU-specific implementation inside `rtl/ip/myCPU/`; only the `core_top` interface is an SoC contract. Never commit Vivado projects, `.Xil`, generated IP output products, simulator object directories, waveforms, binaries, or MIF files.

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
