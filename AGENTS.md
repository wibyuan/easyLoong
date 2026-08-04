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

### Timing-change commit gate (HARD RULE)

A timing change is committed ONLY after it is proven effective by a
synthesis run: gate (`scripts/gate_diff.sh simple matrix cryptonight`) +
full difftest + IPC proof first, then `run_vivado.sh synth`, and only if
the reported WNS improved over the previous run is the change committed.
If WNS did not improve (or regressed), the change is NOT committed — go
back to critical-path analysis.  Never commit first and verify later;
never run implementation while synthesis WNS is below the margin gate
(step 4 of the 100MHz flow: WNS > 2ns before impl).  Failed attempts are
kept only on a `shame/`-prefixed branch as lessons, never on master.

## Build / Test

- `make test-<case>` (simple / fibonacci / matrix / stream / cryptonight /
  mixed) — difftest; RUN SERIALLY (the `make test-*` targets share build
  directories; parallel invocation corrupts the builds).
- `make build` — NEMU + supervisor artifacts.
