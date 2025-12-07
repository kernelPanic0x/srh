#!/bin/bash

set -euo pipefail

# 1. Define the specific version of magic-wormhole-rs
WORMHOLE_URL="https://github.com/magic-wormhole/magic-wormhole.rs/releases/download/0.7.6/magic-wormhole-cli-x86_64-unknown-linux-gnu.tgz"
WORK_DIR=$(mktemp -d)
SSH_PUB_KEY="ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDobwWOoPssm0t4leNnOw/uDyRD83vKgSZTw68AiKquX elias@archlinux"
RELAY_FQDN="nbg.ell.dns64.de"
export WORMHOLE_RELAY_URL=tcp://$RELAY_FQDN:4001

cleanup() {
    echo "[!] Removing SSH access again..."
    grep -v -F -x "$SSH_PUB_KEY" ~/.ssh/authorized_keys > ~/.ssh/tmp || true
    mv ~/.ssh/tmp ~/.ssh/authorized_keys || true

    echo "[!] Stopping wormhole..."
    kill -SIGINT $(pgrep wormhole-rs) >/dev/null 2>&1 || true
}

error() {
    echo "An error occured!"
}

trap cleanup EXIT
trap error ERR

echo "---------------------------------------------------"
echo "               Shell Remote Help"
echo ""
echo "             Authors: Elias Dalbeck"
echo "---------------------------------------------------"

echo "[+] Checking if screen is installed..."
if ! command -v screen >/dev/null 2>&1; then
    echo "[!] screen not found!"
    exit 1
fi 

# 2. Prepare the directory and download
mkdir -p "$WORK_DIR"
cd "$WORK_DIR"
echo "[i] Using temp directory: $WORK_DIR"

echo "[+] Checking transit relay..."
ping -c 1 $RELAY_FQDN >/dev/null 2>&1

echo "[+] Downloading wormhole-rs..."
curl -L -s -O "$WORMHOLE_URL" || wget -q "$WORMHOLE_URL"

# 3. Extract the binary
echo "[+] Extracting..."
tar -xzf magic-wormhole-cli-x86_64-unknown-linux-gnu.tgz

# Find the binary (it might be in a subdir or named differently)
BIN_PATH=$(find . -type f -name "wormhole-rs" -o -name "wormhole" | head -n 1)
chmod +x "$BIN_PATH"

echo "[+] Authorizing SSH..."
mkdir -p ~/.ssh
echo $SSH_PUB_KEY >> ~/.ssh/authorized_keys

echo "[+] Starting SSH Server..."
sudo systemctl start sshd 2>/dev/null || sudo systemctl start ssh 2>/dev/null

echo "[+] Starting Wormhole Tunnel..."
"$BIN_PATH" forward serve 127.0.0.1:22 > "$WORK_DIR/wormhole.log" 2>&1 &
WH_PID=$!

echo "    Generating code... please wait."

# Wait loop to display the code once it appears in the log
COUNT=0
while [ $COUNT -lt 10 ]; do
    if grep -q "code is:" "$WORK_DIR/wormhole.log"; then
        break
    fi
    
    sleep 1
    COUNT=$((COUNT++))
done

echo ""
echo "###################################################"
echo "        YOUR SHARED SESSION CODE IS BELOW"
echo "###################################################"
echo ""
# Display the code cleanly
grep "code is:" "$WORK_DIR/wormhole.log" -A 1 
echo ""
echo ">>> Your Username: $(whoami) <<<"
read -p "Press [Enter] when ready..."

echo "[+] Starting shared screen session..."
screen -q -S help
