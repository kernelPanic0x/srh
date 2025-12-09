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
cat << 'EOF' | base64 -d > "$WORK_DIR/osc52.sh"
IyEvYmluL3NoCiMgQ29weXJpZ2h0IChjKSAyMDEyIFRoZSBDaHJvbWl1bSBPUyBBdXRob3JzLiBB
bGwgcmlnaHRzIHJlc2VydmVkLgojIFVzZSBvZiB0aGlzIHNvdXJjZSBjb2RlIGlzIGdvdmVybmVk
IGJ5IGEgQlNELXN0eWxlIGxpY2Vuc2UgdGhhdCBjYW4gYmUKIyBmb3VuZCBpbiB0aGUgTElDRU5T
RSBmaWxlLgoKIyBNYXggbGVuZ3RoIG9mIHRoZSBPU0MgNTIgc2VxdWVuY2UuICBTZXF1ZW5jZXMg
bG9uZ2VyIHRoYW4gdGhpcyB3aWxsIG5vdCBiZQojIHNlbnQgdG8gdGhlIHRlcm1pbmFsLgpPU0Nf
NTJfTUFYX1NFUVVFTkNFPSIxMDAwMDAiCgojIFdyaXRlIGFuIGVycm9yIG1lc3NhZ2UgYW5kIGV4
aXQuCiMgVXNhZ2U6IDxtZXNzYWdlPgpkaWUoKSB7CiAgZWNobyAiRVJST1I6ICQqIgogIGV4aXQg
MQp9CgojIFNlbmQgYSBEQ1Mgc2VxdWVuY2UgdGhyb3VnaCB0bXV4LgojIFVzYWdlOiA8c2VxdWVu
Y2U+CnRtdXhfZGNzKCkgewogIHByaW50ZiAnXDAzM1B0bXV4O1wwMzMlc1wwMzNcXCcgIiQxIgp9
CgojIFNlbmQgYSBEQ1Mgc2VxdWVuY2UgdGhyb3VnaCBzY3JlZW4uCiMgVXNhZ2U6IDxzZXF1ZW5j
ZT4Kc2NyZWVuX2RjcygpIHsKICAjIFNjcmVlbiBsaW1pdHMgdGhlIGxlbmd0aCBvZiBzdHJpbmcg
c2VxdWVuY2VzLCBzbyB3ZSBoYXZlIHRvIGJyZWFrIGl0IHVwLgogICMgR29pbmcgYnkgdGhlIHNj
cmVlbiBoaXN0b3J5OgogICMgICAodjQuMi4xKSBBcHIgMjAxNCAtIHRvZGF5OiA3NjggYnl0ZXMK
ICAjICAgQXVnIDIwMDggLSBBcHIgMjAxNCAodjQuMi4wKTogNTEyIGJ5dGVzCiAgIyAgID8/PyAt
IEF1ZyAyMDA4ICh2NC4wLjMpOiAyNTYgYnl0ZXMKICAjIFNpbmNlIHY0LjIuMCBpcyBvbmx5IH40
IHllYXJzIG9sZCwgd2UnbGwgdXNlIHRoZSAyNTYgbGltaXQuCiAgIyBXZSBjYW4gcHJvYmFibHkg
c3dpdGNoIHRvIHRoZSA3NjggbGltaXQgaW4gMjAyMi4KICBsb2NhbCBsaW1pdD0yNTYKCiAgaWYg
WyAiJDIiIC1lcSAiMSIgXTsgdGhlbgogICAgIyBXZSBnbyA0IGJ5dGVzIHVuZGVyIHRoZSBsaW1p
dCBiZWNhdXNlIHdlJ3JlIGdvaW5nIHRvIGluc2VydCAyIGJ5dGVzCiAgICAjIGJlZm9yZSAoXGVQ
KSBhbmQgMiBieXRlcyBhZnRlciAoXGVcKSBlYWNoIHN0cmluZy4KICAgIGVjaG8gLW4gIiQxIiB8
IFwKICAgICAgc2VkIC1FICJzOi57JCgoIGxpbWl0IC0gNCApKX06JlxuOmciIHwgXAogICAgICBz
ZWQgLUUgLWUgJ3M6XjpceDFiUDonIC1lICdzOiQ6XHgxYlxcOicgfCBcCiAgICAgIHRyIC1kICdc
bicKICBlbGlmIFsgIiQyIiAtZXEgIjIiIF07IHRoZW4KICAgICMgV2UgZ28gMTAgYnl0ZXMgdW5k
ZXIgdGhlIGxpbWl0IGJlY2F1c2Ugd2UncmUgZ29pbmcgdG8gaW5zZXJ0IDQgYnl0ZXMKICAgICMg
YmVmb3JlIChcZVBcZVApIGFuZCA2IGJ5dGVzIGFmdGVyIChcZVwpIGVhY2ggc3RyaW5nLgogICAg
ZWNobyAtbiAiJDEiIHwgXAogICAgICBzZWQgLUUgInM6LnskKCggbGltaXQgLSAxMCApKX06Jlxu
OmciIHwgXAogICAgICBzZWQgLUUgLWUgJ3M6XjpceDFiUFx4MWJQOicgLWUgJ3M6JDpceDFiXHgx
YlxcXHgxYlxcXFw6JyB8IFwKICAgICAgdHIgLWQgJ1xuJwogIGZpCn0KCiMgU2VuZCBhbiBlc2Nh
cGUgc2VxdWVuY2UgdG8gaHRlcm0uCiMgVXNhZ2U6IDxzZXF1ZW5jZT4KcHJpbnRfc2VxKCkgewog
IGxvY2FsIHNlcT0iJDEiCgogIGNhc2UgJHtURVJNLX0gaW4KICBzY3JlZW4qKQogICAgIyBTaW5j
ZSB0bXV4IGRlZmF1bHRzIHRvIHNldHRpbmcgVEVSTT1zY3JlZW4gKHVnaCksIHdlIG5lZWQgdG8g
ZGV0ZWN0CiAgICAjIGl0IGhlcmUgc3BlY2lhbGx5LgogICAgaWYgWyAtbiAiJHtUTVVYLX0iIF07
IHRoZW4KICAgICAgdG11eF9kY3MgIiR7c2VxfSIKICAgIGVsc2UKICAgICAgc2NyZWVuX2RjcyAi
JHtzZXF9IiAiJHtTQ1JFRU5fTEVWRUw6LTF9IgogICAgZmkKICAgIDs7CiAgdG11eCopCiAgICB0
bXV4X2RjcyAiJHtzZXF9IgogICAgOzsKICAqKQogICAgZWNobyAtbiAiJHtzZXF9IgogICAgOzsK
ICBlc2FjCn0KCiMgQmFzZTY0IGVuY29kZSBzdGRpbi4KYjY0ZW5jKCkgewogIGJhc2U2NCB8IHRy
IC1kICdcbicKfQoKIyBTZW5kIHRoZSBPU0MgNTIgc2VxdWVuY2UgdG8gY29weSB0aGUgY29udGVu
dC4KIyBVc2FnZTogW3N0cmluZ10KY29weSgpIHsKICBsb2NhbCBzdHIKCiAgaWYgWyAkIyAtZXEg
MCBdOyB0aGVuCiAgICBzdHI9IiQoYjY0ZW5jKSIKICBlbHNlCiAgICBzdHI9IiQoZWNobyAiJEAi
IHwgYjY0ZW5jKSIKICBmaQoKICBpZiBbICR7T1NDXzUyX01BWF9TRVFVRU5DRX0gLWd0IDAgXTsg
dGhlbgogICAgbG9jYWwgbGVuPSR7I3N0cn0KICAgIGlmIFsgJHtsZW59IC1ndCAke09TQ181Ml9N
QVhfU0VRVUVOQ0V9IF07IHRoZW4KICAgICAgZGllICJzZWxlY3Rpb24gdG9vIGxvbmcgdG8gc2Vu
ZCB0byB0ZXJtaW5hbDoiIFwKICAgICAgICAiJHtPU0NfNTJfTUFYX1NFUVVFTkNFfSBsaW1pdCwg
JHtsZW59IGF0dGVtcHRlZCIKICAgIGZpCiAgZmkKCiAgcHJpbnRfc2VxICIkKHByaW50ZiAnXDAz
M101MjtjOyVzXGEnICIke3N0cn0iKSIKfQoKIyBXcml0ZSB0b29sIHVzYWdlIGFuZCBleGl0Lgoj
IFVzYWdlOiBbZXJyb3IgbWVzc2FnZV0KdXNhZ2UoKSB7CiAgaWYgWyAkIyAtZ3QgMCBdOyB0aGVu
CiAgICBleGVjIDE+JjIKICBmaQogIGNhdCA8PEVPRgpVc2FnZTogb3NjNTIgW29wdGlvbnNdIFtz
dHJpbmddCgpTZW5kIGFuIGFyYml0cmFyeSBzdHJpbmcgdG8gdGhlIHRlcm1pbmFsIGNsaXBib2Fy
ZCB1c2luZyB0aGUgT1NDIDUyIGVzY2FwZQpzZXF1ZW5jZSBhcyBzcGVjaWZpZWQgaW4geHRlcm06
CiAgaHR0cHM6Ly9pbnZpc2libGUtaXNsYW5kLm5ldC94dGVybS9jdGxzZXFzL2N0bHNlcXMuaHRt
bAogIFNlY3Rpb24gIk9wZXJhdGluZyBTeXN0ZW0gQ29udHJvbHMiLCBQcyA9PiA1Mi4KClRoZSBk
YXRhIGNhbiBlaXRoZXIgYmUgcmVhZCBmcm9tIHN0ZGluOgogICQgZWNobyAiaGVsbG8gd29ybGQi
IHwgb3NjNTIuc2gKCk9yIHNwZWNpZmllZCBvbiB0aGUgY29tbWFuZCBsaW5lOgogICQgb3NjNTIu
c2ggImhlbGxvIHdvcmxkIgoKT3B0aW9uczoKICAtaCwgLS1oZWxwICAgIFRoaXMgc2NyZWVuLgog
IC1mLCAtLWZvcmNlICAgSWdub3JlIG1heCBieXRlIGxpbWl0ICgke09TQ181Ml9NQVhfU0VRVUVO
Q0V9KQpFT0YKCiAgaWYgWyAkIyAtZ3QgMCBdOyB0aGVuCiAgICBlY2hvCiAgICBkaWUgIiRAIgog
IGVsc2UKICAgIGV4aXQgMAogIGZpCn0KCm1haW4oKSB7CiAgc2V0IC1lCgogIHdoaWxlIFsgJCMg
LWd0IDAgXTsgZG8KICAgIGNhc2UgJDEgaW4KICAgIC1ofC0taGVscCkKICAgICAgdXNhZ2UKICAg
ICAgOzsKICAgIC1mfC0tZm9yY2UpCiAgICAgIE9TQ181Ml9NQVhfU0VRVUVOQ0U9MAogICAgICA7
OwogICAgLSopCiAgICAgIHVzYWdlICJVbmtub3duIG9wdGlvbjogJDEiCiAgICAgIDs7CiAgICAq
KQogICAgICBicmVhawogICAgICA7OwogICAgZXNhYwogICAgc2hpZnQKICBkb25lCgogIGNvcHkg
IiRAIgp9Cm1haW4gIiRAIgo=
EOF
chmod +x "$WORK_DIR/osc52.sh"
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
screen -q -c "$WORK_DIR/.screenrc" -RR -S shared
echo "${GREEN}Ok${RESET}"
