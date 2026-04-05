# Changelog

All notable changes to LigoloSupport will be documented in this file.

Format based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
versioning follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2025-01-01

### Added
- Full auto-setup command: download, TUN creation, file server, proxy launch
- Automatic ligolo-ng binary download from GitHub releases (proxy + agents)
- Multi-platform agent support: Linux (amd64/arm64), Windows (amd64), macOS (arm64)
- TUN interface creation and teardown management
- HTTP file server for agent transfer (python3)
- Automatic attack IP detection (tun0, tun1, tap0, default route)
- CIDR route management (add-route, del-route) with format validation
- Step-by-step guided instructions with auto-filled IP addresses
- Cleanup command: removes routes, stops servers, tears down TUN
- Status command: shows binary, TUN, route, and proxy state
- Agent command display for all platforms
- Configurable environment variables (LIGOLO_DIR, TUN_NAME, PROXY_PORT)
- Dependency checking (curl, jq, tar, ip)
- Exit trap for cleanup on Ctrl+C during auto mode
