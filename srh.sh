#!/bin/bash

set -e 

# 1. Define the specific version of magic-wormhole-rs
WORMHOLE_URL="https://github.com/magic-wormhole/magic-wormhole.rs/releases/download/0.7.6/magic-wormhole-cli-x86_64-unknown-linux-gnu.tgz"
WORK_DIR=$(mktemp -d)
export WORMHOLE_RELAY_URL=tcp://nbg.ell.dns64.de:4001

echo "---------------------------------------------------"
echo "               Shell Remote Help"
echo "             Authors: Elias Dalbeck"
echo "---------------------------------------------------"

# 2. Prepare the directory and download
mkdir -p "$WORK_DIR"
cd "$WORK_DIR"

echo "[+] Checking if screen is installed..."
if ! command -v screen >/dev/null 2>&1; then
    echo "[!] screen not found!"
    exit 1
fi 

echo "[+] Downloading Magic Wormhole..."
if command -v curl >/dev/null 2>&1; then
    curl -L -s -O "$WORMHOLE_URL"
elif command -v wget >/dev/null 2>&1; then
    wget -q "$WORMHOLE_URL"
else
    echo "Error: Neither curl nor wget found. Cannot download."
    exit 1
fi

# 3. Extract the binary
echo "[+] Extracting..."
tar -xzf magic-wormhole-cli-x86_64-unknown-linux-gnu.tgz

# Find the binary (it might be in a subdir or named differently)
BIN_PATH=$(find . -type f -name "wormhole-rs" -o -name "wormhole" | head -n 1)
chmod +x "$BIN_PATH"

# 4. Setup SSH Server
echo "[+] Starting SSH Server..."
sudo systemctl start sshd

if [ -z "$SKIP_PASSWD" ]; then
    echo "[+] Please change your user password for temp access:"
    sudo passwd $(whoami)
else
    echo "[+] Skipping passwd."
fi


echo "[+] Starting Wormhole Tunnel..."
echo "    Generating code... please wait."

# Start wormhole in background, log output to file for display
"$BIN_PATH" forward serve 127.0.0.1:22 > "$WORK_DIR/wormhole.log" 2>&1 &
WH_PID=$!

# Wait loop to display the code once it appears in the log
COUNT=0
while [ $COUNT -lt 10 ]; do
    if grep -q "code is:" "$WORK_DIR/wormhole.log" || true; then
        break
    fi
    sleep 1
    ((COUNT++))
done

echo ""
echo "###################################################"
echo "        YOUR SHARED SESSION CODE IS BELOW"
echo "###################################################"
echo ""
# Display the code cleanly
grep "code is:" "$WORK_DIR/wormhole.log" -A 1

read -p "Press [Enter] when ready..."

echo "[+] Starting shared screen session..."
screen -q -S help
