#!/usr/bin/env bash

set -e

# ============================================================
#  MTProto FakeTLS Proxy Installer
#  Ubuntu / Debian
# ============================================================

APP_DIR="/opt/mtprotoproxy"
SERVICE_FILE="/etc/systemd/system/mtproxy.service"

# ---------- Colors ----------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
RESET='\033[0m'

clear

echo -e "${CYAN}${BOLD}"
echo "╔══════════════════════════════════════════════════════╗"
echo "║          MTProto FakeTLS Proxy Installer            ║"
echo "║                  Ubuntu Edition                     ║"
echo "╚══════════════════════════════════════════════════════╝"
echo -e "${RESET}"

# ---------- Root Check ----------
if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}✘ Please run this script as root.${RESET}"
    echo
    echo "Example:"
    echo "sudo bash $0"
    exit 1
fi

# ---------- Detect OS ----------
if [[ -f /etc/os-release ]]; then
    source /etc/os-release
else
    echo -e "${RED}✘ Cannot detect operating system.${RESET}"
    exit 1
fi

echo -e "${GREEN}✔ OS detected:${RESET} $PRETTY_NAME"
echo

# ---------- User Input ----------

read -rp "$(echo -e "${CYAN}➜ Enter proxy port [443]: ${RESET}")" PORT
PORT=${PORT:-443}

if ! [[ "$PORT" =~ ^[0-9]+$ ]] || (( PORT < 1 || PORT > 65535 )); then
    echo -e "${RED}✘ Invalid port.${RESET}"
    exit 1
fi

echo
echo -e "${YELLOW}Generating a secure MTProto secret...${RESET}"

SECRET=$(openssl rand -hex 16)

echo
echo -e "${GREEN}✔ Secret generated:${RESET}"
echo -e "${BOLD}${SECRET}${RESET}"
echo

read -rp "$(echo -e "${CYAN}➜ Enter TAG from @MTProxybot: ${RESET}")" AD_TAG

if [[ -z "$AD_TAG" ]]; then
    echo -e "${RED}✘ TAG cannot be empty.${RESET}"
    exit 1
fi

echo

read -rp "$(echo -e "${CYAN}➜ Enter TLS domain [google.com]: ${RESET}")" TLS_DOMAIN
TLS_DOMAIN=${TLS_DOMAIN:-google.com}

echo
read -rp "$(echo -e "${CYAN}➜ Enter username [tg]: ${RESET}")" USERNAME
USERNAME=${USERNAME:-tg}

echo

# ---------- Server IP ----------
SERVER_IP=$(curl -4 -fsS https://api.ipify.org || true)

if [[ -z "$SERVER_IP" ]]; then
    read -rp "$(echo -e "${CYAN}➜ Enter server public IPv4: ${RESET}")" SERVER_IP
fi

echo -e "${GREEN}✔ Server IP:${RESET} $SERVER_IP"
echo

# ---------- Summary ----------
echo -e "${MAGENTA}${BOLD}"
echo "════════════════ CONFIGURATION ════════════════"
echo -e "${RESET}"

echo -e "Server IP   : ${BOLD}$SERVER_IP${RESET}"
echo -e "Port        : ${BOLD}$PORT${RESET}"
echo -e "Username    : ${BOLD}$USERNAME${RESET}"
echo -e "Secret      : ${BOLD}$SECRET${RESET}"
echo -e "TAG         : ${BOLD}$AD_TAG${RESET}"
echo -e "TLS Domain  : ${BOLD}$TLS_DOMAIN${RESET}"

echo
read -rp "$(echo -e "${YELLOW}➜ Continue installation? [Y/n]: ${RESET}")" CONFIRM
CONFIRM=${CONFIRM:-Y}

if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}Installation cancelled.${RESET}"
    exit 0
fi

# ---------- Update ----------
echo
echo -e "${BLUE}${BOLD}[1/6] Updating package lists...${RESET}"

apt-get update -y

# ---------- Dependencies ----------
echo -e "${BLUE}${BOLD}[2/6] Installing dependencies...${RESET}"

DEBIAN_FRONTEND=noninteractive apt-get install -y \
    git \
    python3 \
    python3-pip \
    python3-uvloop \
    python3-cryptography \
    openssl \
    curl

# ---------- Existing Installation ----------
if [[ -d "$APP_DIR" ]]; then
    echo -e "${YELLOW}Existing installation detected.${RESET}"

    read -rp "$(echo -e "${CYAN}Remove and reinstall? [y/N]: ${RESET}")" REINSTALL

    if [[ "$REINSTALL" =~ ^[Yy]$ ]]; then
        systemctl stop mtproxy 2>/dev/null || true
        rm -rf "$APP_DIR"
    else
        echo -e "${RED}Installation aborted.${RESET}"
        exit 1
    fi
fi

# ---------- Clone ----------
echo -e "${BLUE}${BOLD}[3/6] Downloading MTProxy source...${RESET}"

git clone \
    -b stable \
    https://github.com/alexbers/mtprotoproxy.git \
    "$APP_DIR"

cd "$APP_DIR"

# ---------- Config ----------
echo -e "${BLUE}${BOLD}[4/6] Creating configuration...${RESET}"

cat > "$APP_DIR/config.py" <<EOF
PORT = $PORT

USERS = {
    "$USERNAME": "$SECRET"
}

AD_TAG = "$AD_TAG"

TLS_DOMAIN = "$TLS_DOMAIN"
EOF

chmod 600 "$APP_DIR/config.py"

# ---------- Systemd ----------
echo -e "${BLUE}${BOLD}[5/6] Creating systemd service...${RESET}"

cat > "$SERVICE_FILE" <<EOF
[Unit]
Description=MTProto FakeTLS Proxy
Documentation=https://github.com/alexbers/mtprotoproxy
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
WorkingDirectory=$APP_DIR
ExecStart=/usr/bin/python3 $APP_DIR/mtprotoproxy.py
Restart=always
RestartSec=3

# Security
NoNewPrivileges=true
PrivateTmp=true

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable mtproxy
systemctl restart mtproxy

# ---------- Firewall ----------
echo -e "${BLUE}${BOLD}[6/6] Checking firewall...${RESET}"

if command -v ufw >/dev/null 2>&1; then
    if ufw status | grep -q "Status: active"; then
        echo -e "${YELLOW}UFW is active. Opening port $PORT/tcp...${RESET}"
        ufw allow "$PORT/tcp"
    fi
fi

# ---------- Wait ----------
sleep 3

# ---------- Service Status ----------
if systemctl is-active --quiet mtproxy; then

    echo
    echo -e "${GREEN}${BOLD}"
    echo "╔══════════════════════════════════════════════════════╗"
    echo "║             INSTALLATION SUCCESSFUL                 ║"
    echo "╚══════════════════════════════════════════════════════╝"
    echo -e "${RESET}"

    echo -e "${GREEN}✔ MTProto Proxy is running.${RESET}"
    echo

    echo -e "${CYAN}${BOLD}Proxy Information${RESET}"
    echo "──────────────────────────────────────────────"
    echo "Server IP : $SERVER_IP"
    echo "Port      : $PORT"
    echo "Secret    : $SECRET"
    echo "TAG       : $AD_TAG"
    echo "TLS       : $TLS_DOMAIN"
    echo

    # MTProto link
    PROXY_LINK="tg://proxy?server=${SERVER_IP}&port=${PORT}&secret=${SECRET}"

    echo -e "${CYAN}${BOLD}Telegram Proxy Link${RESET}"
    echo "──────────────────────────────────────────────"
    echo "$PROXY_LINK"
    echo

    echo -e "${YELLOW}${BOLD}Management Commands${RESET}"
    echo "──────────────────────────────────────────────"
    echo "Status : systemctl status mtproxy"
    echo "Logs   : journalctl -u mtproxy -f"
    echo "Restart: systemctl restart mtproxy"
    echo "Stop   : systemctl stop mtproxy"
    echo

    echo -e "${GREEN}✔ Your MTProto FakeTLS proxy is ready.${RESET}"
    echo

else

    echo
    echo -e "${RED}${BOLD}"
    echo "╔══════════════════════════════════════════════════════╗"
    echo "║                INSTALLATION FAILED                  ║"
    echo "╚══════════════════════════════════════════════════════╝"
    echo -e "${RESET}"

    echo
    echo -e "${YELLOW}Last service logs:${RESET}"
    journalctl -u mtproxy --no-pager -n 50

    exit 1
fi
