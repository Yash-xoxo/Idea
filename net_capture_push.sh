#!/bin/bash

# ================= CONFIG =================
WORKDIR="$HOME/autologs"
OUTDIR="$WORKDIR/data"
TS="$(date +'%Y-%m-%d_%H-%M-%S')"
OUTFILE="$OUTDIR/netdump_$TS.txt"
BRANCH="main"

echo "[INIT] config loaded"

# ================= STAGE 0: PRE-FLIGHT =================
mkdir -p "$OUTDIR"
cd "$WORKDIR"
sleep 4
echo "[OK] pre-flight done"

# ================= STAGE 1: CAPTURE (50s HARD CAP) =================
echo "[RUN] starting tcpdump"

# -U = packet-buffered (forces write)
# timeout with KILL fallback guarantees exit
/usr/bin/timeout -k 5s -s SIGINT 50s \
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
