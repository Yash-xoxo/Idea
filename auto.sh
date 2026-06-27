#!/usr/bin/env bash

set -euo pipefail

# ===== Configuration =====
REPO_DIR="$HOME/Idea"               # Change to your Git repository
OUTPUT_DIR="$REPO_DIR/autologs/data"

TIMEOUT_BIN="/usr/bin/timeout"
TCPDUMP_BIN="/usr/sbin/tcpdump"

mkdir -p "$OUTPUT_DIR"

# ===== User Input =====
read -rp "Enter number of runs: " RUNS

if ! [[ "$RUNS" =~ ^[0-9]+$ ]] || [ "$RUNS" -lt 1 ]; then
    echo "Please enter a positive integer."
    exit 1
fi

cd "$REPO_DIR"

for ((i=1; i<=RUNS; i++)); do
    TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
    OUTFILE="$OUTPUT_DIR/netdump_${TIMESTAMP}.txt"

    echo "=================================="
    echo "Run $i of $RUNS"
    echo "Capturing network traffic..."
    echo "Output: $OUTFILE"

    "$TIMEOUT_BIN" -k 2s -s SIGINT 10s \
        "$TCPDUMP_BIN" -i any -nn -XX -U ip \
        > "$OUTFILE" 2>&1

    echo "Capture complete."

    git add "$OUTFILE"

    if git diff --cached --quiet; then
        echo "No changes detected."
    else
        git commit -m "Auto network capture: ${TIMESTAMP} (Run ${i}/${RUNS})"
        git push origin main
        echo "Push completed."
    fi

    echo
done

echo "=================================="
echo "All $RUNS runs completed successfully."
