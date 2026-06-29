#!/usr/bin/env bash

set -euo pipefail

# ========= CONFIG =========
REPO_ROOT="$(cd "$(dirname "$0")" && pwd)"
WORKDIR="$REPO_ROOT/autologs"
OUTDIR="$WORKDIR/data"
BRANCH="main"

mkdir -p "$OUTDIR"

TIMEOUT_BIN="$(command -v timeout)"
TCPDUMP_BIN="$(command -v tcpdump)"
GIT_BIN="$(command -v git)"
PING_BIN="$(command -v ping)"

if [[ -z "$TIMEOUT_BIN" || -z "$TCPDUMP_BIN" || -z "$GIT_BIN" ]]; then
    echo "Required command not found."
    exit 1
fi

cd "$REPO_ROOT"

if [[ ! -d ".git" ]]; then
    echo "Not inside a Git repository."
    exit 1
fi

echo "Repository : $REPO_ROOT"
echo "tcpdump    : $TCPDUMP_BIN"
echo "timeout    : $TIMEOUT_BIN"

getcap "$TCPDUMP_BIN"

echo
read -rp "How many times do you want to run? " RUNS

if ! [[ "$RUNS" =~ ^[0-9]+$ ]] || [[ "$RUNS" -lt 1 ]]; then
    echo "Invalid number."
    exit 1
fi

for ((i=1; i<=RUNS; i++)); do

    echo
    echo "===================================="
    echo "Run $i of $RUNS"
    echo "===================================="

    TS=$(date +"%Y-%m-%d_%H-%M-%S")
    OUTFILE="$OUTDIR/netdump_${TS}.txt"

    echo "Starting capture..."

    # Generate a little traffic in the background
    (
        if [[ -n "${PING_BIN:-}" ]]; then
            ping -c 10 1.1.1.1 >/dev/null 2>&1 || true
        fi
    ) &

    "$TIMEOUT_BIN" -k 2s -s SIGINT 20s \
        "$TCPDUMP_BIN" \
        -i any \
        -nn \
        -XX \
        -U \
        > "$OUTFILE" 2>&1

    echo "Capture finished."

    if [[ ! -s "$OUTFILE" ]]; then
        echo "Capture file is empty."
        continue
    fi

    "$GIT_BIN" add "$OUTFILE"

    if "$GIT_BIN" diff --cached --quiet; then
        echo "Nothing new to commit."
        continue
    fi

    "$GIT_BIN" commit -m "Auto network capture ${TS} (Run ${i}/${RUNS})"

    echo "Pushing..."

    "$GIT_BIN" push origin "$BRANCH"

    echo "Run $i completed."

done

echo
echo "All runs completed successfully."
