#!/bin/bash

###############################################################################
#  wspnow – ChromeOS ISO + QEMU + noVNC launcher
#  Fully automated local emulator on http://localhost:<dynamic_port>
###############################################################################

clear
cat << "EOF"
 __      __  __________________________   ________  __      __ 
/  \    /  \/   _____/\______   \      \  \_____  \/  \    /  \
\   \/\/   /\_____  \  |     ___/   |   \  /   |   \   \/\/   /
 \        / /        \ |    |  /    |    \/    |    \        / 
  \__/\  / /_______  / |____|  \____|__  /\_______  /\__/\  /  
       \/          \/                  \/         \/      \/    
             W S P N O W   E M U L A T O R
               QEMU + noVNC for ChromeOS
EOF
echo ""
echo "[wspnow] Starting setup…"

###############################################################################
# CONFIGURATION
###############################################################################

ISO_URL="https://archive.org/download/google-chrome-os-.-iso-team-mjy-movie-jockey.-com/Google%20Chrome%20OS%20.ISO%20~%20Team%20MJY%20~MovieJockey.Com.iso"
ISO_FILE="chromeos.iso"
VNC_PORT=5900
NOVNC_PORT=8080

###############################################################################
# CHECK DEPENDENCIES
###############################################################################

echo "[wspnow] Checking dependencies…"

if ! command -v qemu-system-x86_64 &> /dev/null; then
    echo "[wspnow] ERROR: QEMU not found. Install it first."
    exit 1
fi

if ! command -v git &> /dev/null; then
    echo "[wspnow] ERROR: git is required to fetch noVNC."
    exit 1
fi

###############################################################################
# ENSURE PORT IS FREE (FIND FIRST FREE PORT)
###############################################################################

echo "[wspnow] Ensuring noVNC port is free…"

# Function to find the first available port
find_free_port() {
  local start_port=$1
  while lsof -i :$start_port >/dev/null 2>&1; do
    start_port=$((start_port + 1))
  done
  echo $start_port
}

# Check and find a free port for noVNC
NOVNC_PORT=$(find_free_port $NOVNC_PORT)
echo "[wspnow] Using port $NOVNC_PORT for noVNC."

# Find available VNC port dynamically
VNC_PORT=$(find_free_port $VNC_PORT)
echo "[wspnow] Using VNC port $VNC_PORT for QEMU."

###############################################################################
# DOWNLOAD ISO IF NEEDED
###############################################################################
if [ ! -f "$ISO_FILE" ]; then
    echo "[wspnow] Downloading ChromeOS ISO…"
    curl -L "$ISO_URL" -o "$ISO_FILE"
else
    echo "[wspnow] ISO already exists: $ISO_FILE"
fi

###############################################################################
# FETCH noVNC IF NEEDED
###############################################################################
if [ ! -d "noVNC" ]; then
    echo "[wspnow] Cloning noVNC…"
    git clone https://github.com/novnc/noVNC.git
fi

###############################################################################
# START QEMU
###############################################################################
echo "[wspnow] Launching QEMU in the background…"

qemu-system-x86_64 \
    -m 2048 \
    -cdrom "$ISO_FILE" \
    -boot d \
    -vnc :$VNC_PORT \
    -vga virtio \
    # New network configuration for QEMU
    -netdev user,id=net0 \
    -device virtio-net,netdev=net0 \
    -monitor stdio &

QEMU_PID=$!
echo "[wspnow] QEMU PID: $QEMU_PID"

# Give QEMU some time to start up
sleep 5

# Check if QEMU is running
if ! ps -p $QEMU_PID > /dev/null; then
    echo "[wspnow] ERROR: QEMU failed to start. Please check logs for errors."
    exit 1
fi

###############################################################################
# START noVNC AUTOMATICALLY
###############################################################################
echo "[wspnow] Starting noVNC on http://localhost:$NOVNC_PORT…"

cd noVNC
./utils/novnc_proxy --vnc localhost:$VNC_PORT --listen $NOVNC_PORT &

NOVNC_PID=$!
echo "[wspnow] noVNC PID: $NOVNC_PID"

# Give noVNC a moment to start
sleep 2

# Check if noVNC is running
if ! ps -p $NOVNC_PID > /dev/null; then
    echo "[wspnow] ERROR: noVNC failed to start. Please check logs for errors."
    exit 1
fi

###############################################################################
# FINAL BANNER
###############################################################################

cat << "EOF"

 __      __  __________________________   ________  __      __ 
/  \    /  \/   _____/\______   \      \  \_____  \/  \    /  \
\   \/\/   /\_____  \  |     ___/   |   \  /   |   \   \/\/   /
 \        / /        \ |    |  /    |    \/    |    \        / 
  \__/\  / /_______  / |____|  \____|__  /\_______  /\__/\  /  
       \/          \/                  \/         \/      \/    
     Your VIRTUAL MACHINE is live and running!

   ▶ Open Chrome/Firefox and go to:

          http://localhost:$NOVNC_PORT

   Enjoy wspnow Virtual Environment 🚀
EOF
