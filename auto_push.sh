#!/bin/bash
set -euo pipefail
#why
# ================= CONFIG =================
REPO_ROOT="$(cd "$(dirname "$0")" && pwd)"
WORKDIR="$REPO_ROOT/autologs"
OUTDIR="$WORKDIR/data"
BRANCH="main"

TS="$(date +'%Y-%m-%d_%H-%M-%S')"
OUTFILE="$OUTDIR/netdump_$TS.txt"

echo "[INIT] repo=$REPO_ROOT"

# ================= STAGE 0: PRE-FLIGHT =================
cd "$REPO_ROOT"

if [ ! -d ".git" ]; then
  echo "ERROR: not a git repository"
  exit 1
fi

mkdir -p "$OUTDIR"

TIMEOUT_BIN="$(command -v timeout || true)"
TCPDUMP_BIN="$(command -v tcpdump || true)"

if [ -z "$TIMEOUT_BIN" ] || [ -z "$TCPDUMP_BIN" ]; then
  echo "ERROR: tcpdump or timeout not found" > "$OUTFILE"
  exit 2
fi

echo "[OK] pre-flight done"

# ================= STAGE 1: CAPTURE =================
echo "[RUN] starting tcpdump"

"$TIMEOUT_BIN" -k 2s -s SIGINT 10s \
  "$TCPDUMP_BIN" -i any -nn -XX -U ip \
  > "$OUTFILE" 2>&1

echo "[OK] capture finished"

# ================= STAGE 2: VALIDATION =================
if [ ! -s "$OUTFILE" ]; then
  echo "ERROR: capture empty — aborting push" >> "$OUTFILE"
  exit 3
fi

if grep -q "No such file or directory" "$OUTFILE"; then
  echo "ERROR: tcpdump execution failed — aborting commit"
  exit 4
fi

echo "[OK] validation done"

# ================= STAGE 3: VERSION + PUSH =================
git add autologs/data
git commit -m "auto: 50s network capture $TS" || true
git push origin "$BRANCH"

echo "[OK] push complete"
