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

### Timing-report archival (HARD RULE)

Every `run_vivado.sh {synth|impl}` run archives its timing/utilization
reports under `run_vivado/reports/<timestamp>-<commit>/` (done
automatically by the script — `run_vivado/project/` is overwritten on
every run).  Commit the archived reports with the run's RTL change (or
as a standalone docs commit for a baseline).  WNS comparisons must
reference the archived reports, never memory or `/tmp` logs: the report
for every commit in the 100MHz push must be reproducible from git.

### No waveform analysis (HARD RULE)

Functional/deadlock debugging must NOT use waveform analysis (VCD / FST /
gtkwave dumps — including `+wave` traces).  Locate bugs only through the
difftest output (Commit Instr Trace, register snapshots, NEMU-vs-DUT
compare), static RTL analysis, and the `unittest/UNITTEST-WORKFLOW.md`
single-test extraction flow.  Waveform digging was repeatedly used during
the 100MHz push and never produced a root cause; it burns hours and
distracts from the code-level cause.

### Edit and commit discipline (HARD RULE)

- Edit RTL only with the edit/apply_patch tools.  NEVER script string
  rewrites over source files (python heredocs etc.) — they silently
  rewrite line endings (CRLF -> LF) and turn a 7-line change into a
  full-file diff, polluting the commit history.
- After a timing change passes its verification (gate + full difftest +
  IPC proof + synth WNS improved), commit it IMMEDIATELY.  Do not stack
  the next change on top of an uncommitted verified one — a regression
  or a failed experiment then cannot be separated from the good change.
- Every commit must be verified from ITS OWN content.  Never carry a
  verification result over from an earlier version of the code (e.g.
  after a git checkout + replay of an edit, re-run gate/difftest/synth
  before committing) and never claim a verification that was not run on
  the committed content.

## Build / Test

- `make test-<case>` (simple / fibonacci / matrix / stream / cryptonight /
  mixed) — difftest; RUN SERIALLY (the `make test-*` targets share build
  directories; parallel invocation corrupts the builds).
- `make build` — NEMU + supervisor artifacts.
