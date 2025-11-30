#!/bin/bash

###############################################################################
#  wspnow – Windows ISO + QEMU + noVNC launcher
#  Fully automated local emulator on http://localhost:8080
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
               QEMU + noVNC for Windows
EOF
echo ""
echo "[wspnow] Starting setup…"

###############################################################################
# CONFIGURATION
###############################################################################

ISO_URL="https://www.mediafire.com/file/smwzrjuwq0j7eo0/Windows+11+Powerless+Edition.iso/file"
ISO_FILE="Windows.iso"
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
# ENSURE PORT 8080 IS FREE
###############################################################################
echo "[wspnow] Ensuring port $NOVNC_PORT is free…"

if lsof -i :$NOVNC_PORT >/dev/null 2>&1; then
    echo "[wspnow] Port $NOVNC_PORT is in use. Attempting to free it…"
    kill $(lsof -t -i:$NOVNC_PORT) 2>/dev/null
fi

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
# START QEMU (WITH KVM DISABLED)
###############################################################################
echo "[wspnow] Launching QEMU in the background (KVM disabled)…"

qemu-system-x86_64 \
    -m 2048 \
    -cdrom "$ISO_FILE" \
    -boot d \
    -vnc :0 \
    -vga virtio \
    >/dev/null 2>&1 &

QEMU_PID=$!
echo "[wspnow] QEMU PID: $QEMU_PID"

###############################################################################
# START noVNC
###############################################################################
echo "[wspnow] Starting noVNC on http://localhost:$NOVNC_PORT…"

cd noVNC
./utils/novnc_proxy --vnc localhost:$VNC_PORT --listen $NOVNC_PORT >/dev/null 2>&1 &

NOVNC_PID=$!
echo "[wspnow] noVNC PID: $NOVNC_PID"

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

          http://localhost:8080

   Enjoy your virtual environment 🚀
EOF
