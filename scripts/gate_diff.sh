#!/bin/bash
# Gate: run difftest, FAIL (exit 1) on any mismatch/error.  Never chain
# synth/impl behind a grep that matches failure text (grep exits 0 on match!).
# Usage: scripts/gate_diff.sh simple matrix cryptonight ...
set -u
LOG_DIR="${GATE_LOG_DIR:-/tmp/opencode}"
mkdir -p "$LOG_DIR"
for t in "$@"; do
    log="$LOG_DIR/dt_$t.log"
    make test-$t > "$log" 2>&1
    if grep -qE "mismatch|ERROR|aborting" "$log"; then
        echo "GATE FAIL: $t (mismatch/error)"
        exit 1
    fi
    if ! grep -qE "\[difftest\] finished" "$log"; then
        echo "GATE FAIL: $t (no difftest finish)"
        exit 1
    fi
    echo "GATE OK: $t $(grep -oE 'IPC: [0-9.]+' "$log" | head -1)"
done
echo "GATE PASS"
