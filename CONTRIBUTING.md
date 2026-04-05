# Contributing to LigoloSupport

Thank you for your interest in contributing to LigoloSupport! This document provides guidelines and instructions for contributing.

## Development Environment Setup

### Prerequisites

- **Bash:** 4.0 or later
- **Linux:** Kali, Ubuntu, or Debian recommended
- **Git:** For version control

### Getting Started

```bash
# Fork and clone the repository
git clone https://github.com/<your-username>/LigoloSupport.git
cd LigoloSupport

# Test the script
chmod +x ligolo-helper.sh
./ligolo-helper.sh help

# Run with auto (requires root and network)
sudo ./ligolo-helper.sh auto
```

## Code Style

LigoloSupport is a Bash script. Follow these conventions:

- **Formatting:** Use 4-space indentation
- **Variables:** Use UPPER_CASE for constants, lower_case for locals
- **Functions:** Use snake_case naming
- **Quoting:** Always quote variables (`"$var"` not `$var`)
- **Error handling:** Use `set -e` and explicit error checks
- **Comments:** Document non-obvious logic with inline comments

## Testing

Test all subcommands before submitting:

```bash
# Verify help output
./ligolo-helper.sh help

# Test download (no root needed)
./ligolo-helper.sh download

# Test full workflow (requires root)
sudo ./ligolo-helper.sh auto
# Ctrl+C to stop

# Test cleanup
sudo ./ligolo-helper.sh cleanup

# Test status
./ligolo-helper.sh status
```

## Pull Request Process

1. **Fork** the repository and create a feature branch:
   ```bash
   git checkout -b feat/my-feature
   ```

2. **Make your changes** with clear, focused commits.

3. **Test thoroughly** on at least one Linux distribution.

4. **Push** your branch and open a Pull Request against `main`.

5. **Describe your changes** in the PR using the provided template.

6. **Respond to review feedback** promptly.

## Commit Message Format

This project follows [Conventional Commits](https://www.conventionalcommits.org/):

```
<type>(<optional scope>): <description>

[optional body]

[optional footer(s)]
```

### Types

| Type       | Description                          |
| ---------- | ------------------------------------ |
| `feat`     | New feature                          |
| `fix`      | Bug fix                              |
| `docs`     | Documentation changes                |
| `style`    | Formatting, no code change           |
| `refactor` | Code restructuring, no behavior change |
| `test`     | Adding or updating tests             |
| `ci`       | CI/CD changes                        |
| `chore`    | Maintenance, dependencies            |

### Examples

```
feat(download): add arm64 proxy binary support
fix(tun): handle existing interface gracefully
docs: update troubleshooting section with CIDR examples
```

### Important

- Do **not** include AI co-author signatures in commits.
- Keep commits focused on a single logical change.

## Questions?

If you have questions about contributing, feel free to open a discussion or issue on GitHub.
