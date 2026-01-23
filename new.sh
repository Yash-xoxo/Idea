#!/bin/bash
set -euo pipefail

# ================= CONFIG =================
REPO_DIR="$HOME/net-capture-repo"
REMOTE_URL="git@github.com:YOUR_USERNAME/YOUR_REPO.git"
BRANCH="main"

CAPTURE_DIR="$REPO_DIR/data"
TS="$(date +'%Y-%m-%d_%H-%M-%S')"
OUTFILE="$CAPTURE_DIR/netdump_$TS.txt"

# ================= STAGE 0: INIT =================
mkdir -p "$CAPTURE_DIR"
cd "$REPO_DIR"

if [ ! -d ".git" ]; then
  echo "[INIT] initializing git repo"
  git init
  git branch -M "$BRANCH"
  git remote add origin "$REMOTE_URL"

  echo "[INIT] bootstrap commit"
  echo "# Network Captures" > README.md
  git add README.md
  git commit -m "init: repository bootstrap"
  git push -u origin "$BRANCH"
fi

echo "[OK] git repo ready"

# ================= STAGE 1: CAPTURE =================
echo "[RUN] tcpdump capture"
/usr/bin/timeout -k 2s -s SIGINT 10s \
  /usr/sbin/tcpdump -i any -nn -XX -U ip \
  > "$OUTFILE" 2>&1

# ================= STAGE 2: VALIDATION =================
if [ ! -s "$OUTFILE" ]; then
  echo "ERROR: empty capture, aborting"
  exit 1
fi

echo "[OK] capture validated"

# ================= STAGE 3: COMMIT + PUSH =================
git add data/
git commit -m "auto: tcpdump capture $TS"
git push origin "$BRANCH"

echo "[DONE] capture committed and pushed"
