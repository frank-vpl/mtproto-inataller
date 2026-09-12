# MTProto FakeTLS Proxy Installer

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](./LICENSE)
![Platform](https://img.shields.io/badge/platform-Ubuntu%20%7C%20Debian-blue)
![Shell](https://img.shields.io/badge/shell-bash-lightgrey)

A simple, interactive Bash installer that sets up an **MTProto FakeTLS proxy** for Telegram on Ubuntu/Debian servers. It installs dependencies, generates a secure secret, configures a `systemd` service, and prints a ready-to-use `tg://proxy` link when finished.

This installer wraps and configures the [`mtprotoproxy`](https://github.com/alexbers/mtprotoproxy) project by [alexbers](https://github.com/alexbers), licensed separately under its own terms. All credit for the core proxy implementation goes to that project — this repository only automates its installation and configuration.

---

## Features

- ✅ Interactive setup (port, username, TLS domain, ad tag)
- ✅ Automatic secure secret generation via `openssl`
- ✅ Auto-detects your server's public IP
- ✅ Creates and enables a `systemd` service (`mtproxy.service`)
- ✅ Opens the chosen port automatically if `ufw` is active
- ✅ Prints a ready-to-import Telegram proxy link

---

## Requirements

- Ubuntu or Debian (root access)
- Outbound internet access on the server
- A registration tag from [@MTProxybot](https://t.me/MTProxybot) on Telegram (optional but recommended for the ad tag)

---

## Installation

Run one of the following commands as **root** (or with `sudo`).

### Using `curl`

```bash
curl -fsSL https://raw.githubusercontent.com/frank-vpl/mtproto-inataller/main/install.sh -o install.sh
sudo bash install.sh
```

### Using `wget`

```bash
wget -O install.sh https://raw.githubusercontent.com/frank-vpl/mtproto-inataller/main/install.sh
sudo bash install.sh
```

During installation you'll be prompted for:

| Prompt | Default |
|---|---|
| Proxy port | `443` |
| TAG from @MTProxybot | *(required)* |
| TLS domain to masquerade as | `google.com` |
| Username label | `tg` |

---

## Managing the Service

```bash
# Check status
systemctl status mtproxy

# View live logs
journalctl -u mtproxy -f

# Restart
systemctl restart mtproxy

# Stop
systemctl stop mtproxy
```

Configuration is stored at `/opt/mtprotoproxy/config.py`.

---

## Uninstalling

```bash
sudo systemctl stop mtproxy
sudo systemctl disable mtproxy
sudo rm -rf /opt/mtprotoproxy /etc/systemd/system/mtproxy.service
sudo systemctl daemon-reload
```

---

## Credits

- Core proxy engine: [alexbers/mtprotoproxy](https://github.com/alexbers/mtprotoproxy) (see that repository for its own license terms).
- Installer script and automation: this repository's contributors.

---

## License

This installer script is released under the [MIT License](./LICENSE).
