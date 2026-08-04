# Repository Guidelines (easyLoong)

## HARD RULE: Vivado / Timing work must follow the operations manual

Before ANY synthesis / implementation / timing / PLL work, READ and FOLLOW:

- `DEVLOG.md` → 「Vivado 操作手册（交接必备）」 — the mandatory workflow:
  project pipeline (`scripts/vivado/run_vivado.sh {create|synth|impl}`),
  the regenerated-PLL-product cleanup, the `.xci` protection, the gate-first
  rule, and the serial-difftest rule.
- `scripts/vivado/run_vivado.sh` — the only sanctioned way to run the
  Vivado docker pipeline (default strategy only).
- `scripts/gate_diff.sh simple matrix cryptonight` — the mandatory gate
  before any RTL change reaches Vivado.

Other hard rules (see `nscscc-solo-la-soc/AGENTS.md` for the full list):
no non-default synthesis/implementation strategies, no timing-constraint
semantics changes, no backgrounding/polling Vivado, no direct `.xci`
edits, no experiment scripts in `run_vivado/flow/`, one logical change per
commit, no silent IPC sacrifice (announce first).

## Build / Test

- `make test-<case>` (simple / fibonacci / matrix / stream / cryptonight /
  mixed) — difftest; RUN SERIALLY (the `make test-*` targets share build
  directories; parallel invocation corrupts the builds).
- `make build` — NEMU + supervisor artifacts.
