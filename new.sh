#!/bin/bash
set -euo pipefail

# ================= CONFIG =================
REPO_DIR="/home/yash/git_push_things/Idea"
WORKDIR="$REPO_DIR/autologs"
OUTDIR="$WORKDIR/data"
TS="$(date +'%Y-%m-%d_%H-%M-%S')"
OUTFILE="$OUTDIR/netdump_$TS.txt"
BRANCH="main"

echo "[INIT] config loaded"

# ================= STAGE 0: PRE-FLIGHT =================
mkdir -p "$OUTDIR"
cd "$REPO_DIR"

git rev-parse --is-inside-work-tree >/dev/null
echo "[OK] repo verified"

# ================= STAGE 1: CAPTURE =================
echo "[RUN] starting tcpdump"
/usr/bin/timeout -k 2s -s SIGINT 10s \
  /usr/sbin/tcpdump -i any -nn -XX -U ip \
  > "$OUTFILE" 2>&1

echo "[OK] capture finished"

# ================= STAGE 2: VALIDATION =================
if [ ! -s "$OUTFILE" ]; then
  echo "ERROR: empty capture — aborting"
  exit 1
fi

echo "[OK] validation done"

# ================= STAGE 3: VERSION + PUSH =================
git add autologs/
git commit -m "auto: tcpdump capture $TS" || echo "[INFO] nothing new to commit"
git push origin "$BRANCH"

echo "[DONE] capture committed and pushed"
