#!/bin/bash
TIMEOUT_BIN="$(command -v timeout)"
TCPDUMP_BIN="$(command -v tcpdump)"

if [ -z "$TIMEOUT_BIN" ] || [ -z "$TCPDUMP_BIN" ]; then
  echo "ERROR: timeout or tcpdump not found"
  exit 10
fi

# ================= CONFIG =================
REPO_ROOT="$(cd "$(dirname "$0")" && pwd)"
WORKDIR="$REPO_ROOT/autologs"
OUTDIR="$WORKDIR/data"

TS="$(date +'%Y-%m-%d_%H-%M-%S')"
OUTFILE="$OUTDIR/netdump_$TS.txt"
BRANCH="main"

echo "[INIT] repo=$REPO_ROOT"

# ================= STAGE 0: PRE-FLIGHT =================
cd "$REPO_ROOT" || exit 1

if [ ! -d ".git" ]; then
  echo "ERROR: not inside a git repository"
  exit 2
fi

mkdir -p "$OUTDIR"
sleep 1
echo "[OK] pre-flight done"

# ================= STAGE 1: CAPTURE (50s HARD CAP) =================
echo "[RUN] starting tcpdump"

# -U = packet-buffered (forces write)
# timeout with KILL fallback guarantees exit
/usr/bin/timeout -k 2s -s SIGINT 20s \
  /usr/sbin/tcpdump -i any -nn -XX -U ip \
  > "$OUTFILE" 2>&1

echo "[OK] capture finished"
sleep 4

# ================= STAGE 2: VALIDATION =================
if [ ! -s "$OUTFILE" ]; then
  echo "ERROR: capture empty — aborting push" >> "$OUTFILE"
  exit 1
fi
echo "[OK] validation done"
sleep 4

# ================= STAGE 3: VERSION + PUSH =================
git add .
git commit -m "auto: 50s network capture $TS"
sleep 4
git push origin main
echo "[OK] push complete"
