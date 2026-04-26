# Multica Installer

```bash
curl -sSL https://raw.githubusercontent.com/TaQuangKhoi/install-multica/main/install-multica.sh | bash
```

One-command installation script for [Multica](https://github.com/multica-ai/multica) — an AI-powered development platform for Linux.

## Features

- Downloads the latest AppImage from GitHub releases
- Installs to `~/.local/bin`
- Creates desktop entry with icon
- Works on any Linux distro

## Requirements

- `wget`
- `update-desktop-database` (optional, for desktop integration)

## Launch

- Terminal: `multica`
- App launcher: Search for "Multica"

## Uninstall

```bash
rm ~/.local/bin/multica
rm ~/.local/share/applications/multica.desktop
rm ~/.local/share/icons/multica.png
```

## Details

| Setting | Value |
|---------|-------|
| Version | 0.2.17 |
| Binary | `~/.local/bin/multica` |
| Desktop entry | `~/.local/share/applications/multica.desktop` |
| Icon | `~/.local/share/icons/multica.png` |
