#!/bin/bash

set -euo pipefail

# Check if stdout is a terminal AND if the terminal supports at least 8 colors
if [ -t 1 ] && command -v tput >/dev/null && [ $(tput colors) -ge 8 ]; then
    RED=$'\e[31m'
    GREEN=$'\e[32m'
    YELLOW=$'\e[33m'
    BLUE=$'\e[34m'
    CYAN=$'\e[36m'
    BOLD=$'\e[1m'
    RESET=$'\e[0m'
else
    # If not a terminal or no color support, set variables to empty strings
    RED=''
    GREEN=''
    YELLOW=''
    BLUE=''
    CYAN=''
    BOLD=''
    RESET=''
fi

# 1. Define the specific version of magic-wormhole-rs
WORMHOLE_URL="https://github.com/magic-wormhole/magic-wormhole.rs/releases/download/0.7.6/magic-wormhole-cli-x86_64-unknown-linux-gnu.tgz"
WORK_DIR=$(mktemp -d)
SSH_PUB_KEY="ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIziMsLm7/0XKmq6z4mFqpmdJ/05Kblt92TZHI0IlXvB shell_remote_help"
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
    echo "${RED}${BOLD}An error occured!${RESET}"
}

trap cleanup EXIT
trap error ERR

echo "${BLUE}---------------------------------------------------${RESET}"
echo "${BOLD}               Shell Remote Help${RESET}"
echo ""
echo "             Authors: Elias Dalbeck"
echo "${BLUE}---------------------------------------------------${RESET}"

echo -n "[+] Checking if screen is installed..."
if ! command -v screen >/dev/null 2>&1; then
    echo "${RED}[!] screen not found!${RESET}"
    exit 1
fi 
echo "${GREEN}Ok${RESET}"

echo -n "[+] Creating temp directory..."
mkdir -p "$WORK_DIR"
cd "$WORK_DIR"
cat << 'EOF' > "$WORK_DIR/.screenrc"
truecolor on
hardstatus alwaysfirstline
hardstatus string '%{= 0;5}%= Shared Shell Session %{= 0;5}%= %c'
EOF
echo "${GREEN}Ok${RESET}"

echo -n "[+] Downloading wormhole-rs..."
curl -L -s -O "$WORMHOLE_URL" || wget -q "$WORMHOLE_URL"
echo "${GREEN}Ok${RESET}"

# 3. Extract the binary
echo -n "[+] Extracting..."
tar -xzf magic-wormhole-cli-x86_64-unknown-linux-gnu.tgz
BIN_PATH=$(find . -type f -name "wormhole-rs" -o -name "wormhole" | head -n 1)
chmod +x "$BIN_PATH"
echo "${GREEN}Ok${RESET}"

echo -n "[+] Authorizing SSH..."
mkdir -p ~/.ssh
echo $SSH_PUB_KEY >> ~/.ssh/authorized_keys
echo "${GREEN}Ok${RESET}"

echo -n "[+] Starting SSH Server..."
sudo systemctl start sshd 2>/dev/null || sudo systemctl start ssh 2>/dev/null
echo "${GREEN}Ok${RESET}"

echo -n "[+] Starting wormhole tunnel..."
"$BIN_PATH" forward serve 127.0.0.1:22 > "$WORK_DIR/wormhole.log" 2>&1 &
WH_PID=$!
echo "${GREEN}Ok${RESET}"

echo -n "[+] Generating wormhole code..."
COUNT=0
while [ $COUNT -lt 10 ]; do
    if grep -q "code is:" "$WORK_DIR/wormhole.log"; then
        break
    fi
    
    sleep 1
    COUNT=$((COUNT+1))
done
WORMHOLE_CODE=$(grep -o "[0-9]\+-[^ ]\+" "$WORK_DIR/wormhole.log" | head -n 1)
echo "${GREEN}Ok${RESET}"

echo ""
echo "${CYAN}###################################################${RESET}"
echo "${BOLD}        YOUR SHARED SESSION CODE IS BELOW${RESET}"
echo "${CYAN}###################################################${RESET}"
echo ""
echo "Code is: ${YELLOW}${BOLD}${WORMHOLE_CODE}${RESET}"
echo ""
echo "Username is: ${BOLD}$(whoami)${RESET}"
echo ""
read -p "Press [Enter] when ready..."

echo -n "[+] Starting shared screen session..."
screen -q -c $WORK_DIR/.screenrc -S help
echo "${GREEN}Ok${RESET}"
