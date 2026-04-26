#!/bin/bash
set -e

# Configuration
REPO="multica-ai/multica"
INSTALL_DIR="$HOME/.local/bin"
DESKTOP_FILE="$HOME/.local/share/applications/multica.desktop"
ICON_DIR="$HOME/.local/share/icons"
ICON_NAME="multica"
EXEC_PATH="$INSTALL_DIR/multica"
ICON_PATH="$ICON_DIR/multica.png"
CURRENT_VERSION=""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -i, --install     Force install (default)"
    echo "  -u, --update      Update to latest version"
    echo "  -v, --version     Show current installed version"
    echo "  -h, --help        Show this help"
    echo ""
    echo "Run without arguments to install or update."
}

# Get latest version from GitHub
get_latest_version() {
    curl -sSL "https://api.github.com/repos/${REPO}/releases/latest" | grep -oP '"tag_name": "v\K[^"]+'
}

# Get installed version
get_installed_version() {
    if [[ -f "$EXEC_PATH" ]]; then
        grep -oP 'multica-desktop-\K[0-9.]+(?=-linux)' "$EXEC_PATH" 2>/dev/null || echo ""
    fi
}

# Install icon
install_icon() {
    local VERSION="$1"
    local LIGHT_SVG="/tmp/multica-light.svg"
    local DARK_SVG="/tmp/multica-dark.svg"
    local LIGHT_PNG="$ICON_DIR/${ICON_NAME}-light.png"
    local DARK_PNG="$ICON_DIR/${ICON_NAME}-dark.png"
    local FALLBACK_PNG="$ICON_PATH"
    
    echo -e "${YELLOW}🎨 Installing adaptive icon...${NC}"
    
    mkdir -p "$ICON_DIR"
    
    # Download SVG logos
    curl -sSL "https://raw.githubusercontent.com/multica-ai/multica/main/docs/assets/logo-light.svg" -o "$LIGHT_SVG"
    curl -sSL "https://raw.githubusercontent.com/multica-ai/multica/main/docs/assets/logo-dark.svg" -o "$DARK_SVG"
    
    # Convert SVG to PNG (512x512 for high-res icon)
    if command -v convert &>/dev/null; then
        convert -background none -size 512x512 "$LIGHT_SVG" "$LIGHT_PNG"
        convert -background none -size 512x512 "$DARK_SVG" "$DARK_PNG"
        # Fallback for apps that don't support adaptive icons
        cp "$LIGHT_PNG" "$FALLBACK_PNG"
        echo "  ✓ Converted SVG to PNG (ImageMagick)"
    else
        # Try rsvg-convert
        if command -v rsvg-convert &>/dev/null; then
            rsvg-convert -w 512 -h 512 "$LIGHT_SVG" -o "$LIGHT_PNG"
            rsvg-convert -w 512 -h 512 "$DARK_SVG" -o "$DARK_PNG"
            cp "$LIGHT_PNG" "$FALLBACK_PNG"
            echo "  ✓ Converted SVG to PNG (rsvg-convert)"
        else
            echo -e "${RED}  ⚠ No SVG converter found. Skipping icon.${NC}"
            echo "  Install ImageMagick: sudo apt install imagemagick"
            return
        fi
    fi
    
    # Set up adaptive icon symlinks in icon theme directories
    local SIZES=(16 32 48 64 128 256 512)
    local THEMES=("hicolor" "Adwaita")
    
    for THEME in "${THEMES[@]}"; do
        for SIZE in "${SIZES[@]}"; do
            local ICON_THEME_DIR="$ICON_DIR/${THEME}/${SIZE}x${SIZE}/apps"
            mkdir -p "$ICON_THEME_DIR"
            
            # Create symbolic links for light/dark variants
            ln -sf "../../../${ICON_NAME}-light.png" "$ICON_THEME_DIR/${ICON_NAME}.light" 2>/dev/null || true
            ln -sf "../../../${ICON_NAME}-dark.png" "$ICON_THEME_DIR/${ICON_NAME}.dark" 2>/dev/null || true
            
            # Create scalable symlink for symbolic icon names
            local SCALABLE_DIR="$ICON_DIR/${THEME}/scalable/apps"
            mkdir -p "$SCALABLE_DIR"
            ln -sf "../../../${ICON_NAME}-light.svg" "$SCALABLE_DIR/${ICON_NAME}.light" 2>/dev/null || true
            ln -sf "../../../${ICON_NAME}-dark.svg" "$SCALABLE_DIR/${ICON_NAME}.dark" 2>/dev/null || true
        done
    done
    
    # Copy SVG files for scalable icons
    cp "$LIGHT_SVG" "$ICON_DIR/${ICON_NAME}-light.svg"
    cp "$DARK_SVG" "$ICON_DIR/${ICON_NAME}-dark.svg"
    
    # Update icon cache
    gtk-update-icon-cache "$ICON_DIR/${THEME}" 2>/dev/null || true
    
    rm -f "$LIGHT_SVG" "$DARK_SVG"
    echo "  ✓ Adaptive icon installed"
}

# Download and install
do_install() {
    local VERSION="$1"
    local APPIMAGE_NAME="multica-desktop-${VERSION}-linux-x86_64.AppImage"
    local DOWNLOAD_URL="https://github.com/${REPO}/releases/download/v${VERSION}/${APPIMAGE_NAME}"

    echo -e "${YELLOW}📥 Downloading Multica ${VERSION}...${NC}"
    cd /tmp
    rm -f "${APPIMAGE_NAME}" 2>/dev/null || true
    wget -q --show-progress -O "${APPIMAGE_NAME}" "${DOWNLOAD_URL}"

    echo -e "${YELLOW}🔧 Installing...${NC}"
    mkdir -p "$INSTALL_DIR"
    mv "${APPIMAGE_NAME}" "${EXEC_PATH}"
    chmod +x "${EXEC_PATH}"

    # Install icon
    install_icon "$VERSION"

    # Create .desktop file
    echo -e "${YELLOW}📱 Creating desktop entry...${NC}"
    mkdir -p "$(dirname "$DESKTOP_FILE")"
    cat > "$DESKTOP_FILE" << EOF
[Desktop Entry]
Name=Multica
Comment=AI-powered development platform
Exec=${EXEC_PATH}
Icon=${ICON_PATH}
Icon[en_US]=${ICON_NAME}
SymbolicIcon=${ICON_NAME}
Terminal=false
Type=Application
Categories=Development;IDE;AI;
Keywords=multica;ai;coding;development;
StartupWMClass=multica-desktop
EOF

    update-desktop-database "$(dirname "$DESKTOP_FILE")" 2>/dev/null || true

    echo ""
    echo -e "${GREEN}✅ Installation complete!${NC}"
    echo "   Version: $VERSION"
    echo "   Executable: $EXEC_PATH"
}

# Main logic
ACTION="install"

while [[ $# -gt 0 ]]; do
    case "$1" in
        -i|--install) ACTION="install"; shift ;;
        -u|--update) ACTION="update"; shift ;;
        -v|--version) ACTION="version"; shift ;;
        -h|--help) usage; exit 0 ;;
        *) echo "Unknown option: $1"; usage; exit 1 ;;
    esac
done

case "$ACTION" in
    version)
        CURRENT_VERSION=$(get_installed_version)
        if [[ -n "$CURRENT_VERSION" ]]; then
            echo "Installed: $CURRENT_VERSION"
        else
            echo "Not installed"
        fi
        exit 0
        ;;

    update)
        if [[ ! -f "$EXEC_PATH" ]]; then
            echo -e "${RED}❌ Multica is not installed. Use '$0' to install.${NC}"
            exit 1
        fi

        CURRENT_VERSION=$(get_installed_version)
        echo -e "Current version: ${YELLOW}${CURRENT_VERSION}${NC}"

        echo -e "Checking for updates..."
        LATEST_VERSION=$(get_latest_version)
        echo -e "Latest version:   ${GREEN}${LATEST_VERSION}${NC}"

        if [[ "$CURRENT_VERSION" == "$LATEST_VERSION" ]]; then
            echo -e "${GREEN}✅ Already up to date!${NC}"
            exit 0
        fi

        echo ""
        echo -e "${YELLOW}🔄 Updating from ${CURRENT_VERSION} to ${LATEST_VERSION}...${NC}"
        do_install "$LATEST_VERSION"
        ;;

    install|*)
        LATEST_VERSION=$(get_latest_version)
        
        if [[ -f "$EXEC_PATH" ]]; then
            CURRENT_VERSION=$(get_installed_version)
            if [[ "$CURRENT_VERSION" != "$LATEST_VERSION" ]]; then
                echo -e "${YELLOW}⚠️  Multica ${CURRENT_VERSION} is installed.${NC}"
                echo -e "    New version ${LATEST_VERSION} available."
                echo -e "    Run '${0} --update' to update."
                echo ""
            else
                echo -e "${GREEN}✅ Multica ${CURRENT_VERSION} is already installed.${NC}"
                exit 0
            fi
        fi
        
        do_install "$LATEST_VERSION"
        ;;
esac
