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

### Systematic critical-path view (HARD RULE)

The synthesis and implementation reports of the SAME netlist show the
same set of long path families in different order — a family that tops
the impl report also exists in the synth netlist (just not ranked
first), and vice versa.  NEVER treat the synth top and the impl top as
unrelated families to be fixed one at a time: cutting the synth top
leaves the impl top untouched, and "fixing" one family merely lets
another ~10ns family surface.  Connect ALL runs as well: compare synth
top across runs, impl top across runs, and synth vs impl — the sequence
of which family surfaces after each change (and which disappears)
reveals the whole family set.  Before designing any change, merge the
synth and impl critical-path reports (of this run AND previous runs)
and enumerate ALL path families; each family must be dealt with for the
design to converge, and a change should be evaluated against the whole
family set, not against the single reported top.  This deviation
(treating the synth top and impl top as independent, and declaring a
family "short in the other report so it can be ignored") burned many
rounds during the 100MHz push.

### Cut one family, not ten fingers (HARD RULE)

A timing change must structurally ELIMINATE one path family from the
critical-path set — the family no longer appears in the reports — not
shave a few logic levels off several families.  Shaving every family a
little leaves all of them alive, and the WNS merely oscillates as one
shallow family surfaces another ~10ns path.  Structural elimination
(e.g. deleting a whole mechanism: the write-buffer coverage search from
the accept chain, the PLRU/way-selection dimension via direct-mapped
icache) removes a family from the set permanently, and each eliminated
family shrinks the routing/placement pressure for the rest.  Evaluate a
change by whether its target family disappears from the critical-path
list, never by whether WNS moved a few tenths of a ns — and fix the
families one at a time, committing each elimination before starting the
next.  Shaving attempts (e.g. deferring the PLRU write by one cycle,
dropping the line-level search while the word-level search stays,
registering the cacop request while the rf->ALU head remains) all
failed during the 100MHz push; every success was a structural
elimination.

## Build / Test

- `make test-<case>` (simple / fibonacci / matrix / stream / cryptonight /
  mixed) — difftest; RUN SERIALLY (the `make test-*` targets share build
  directories; parallel invocation corrupts the builds).
- `make build` — NEMU + supervisor artifacts.
