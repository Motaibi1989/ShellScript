#!/bin/bash

# --------------------------------------------
# LAZARUS INSTALLER 2.8 - COMPLETE CLEAN INSTALL
# Author: Mohammed Alotaibi
# Last Update: 2025-08-03
# --------------------------------------------

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
WHITE='\033[1;37m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

# Configuration
LAZARUS_SOURCE_DIR="$HOME/lazarus-source"
DESKTOP_FILE="$HOME/.local/share/applications/lazarus.desktop"
INSTALL_LOG="/tmp/lazarus_install_$(date +%Y%m%d_%H%M%S).log"
LAZARUS_EXEC="/usr/local/bin/lazarus"
ICON_PATH="/usr/local/share/lazarus/images/icons/lazarus.ico"
BUILD_JOBS=$(nproc)
MIN_DISK_SPACE=2000 # Minimum disk space needed in MB

# Initialize log file
init_log() {
    echo "=== Lazarus Installation Log ===" > "$INSTALL_LOG"
    echo "Started at: $(date)" >> "$INSTALL_LOG"
    echo "System Info:" >> "$INSTALL_LOG"
    lsb_release -d >> "$INSTALL_LOG" 2>&1
    uname -a >> "$INSTALL_LOG" 2>&1
    echo "CPU Cores: $BUILD_JOBS" >> "$INSTALL_LOG"
    
    # Log disk space
    echo -e "\nDisk Space:" >> "$INSTALL_LOG"
    df -h >> "$INSTALL_LOG" 2>&1
    
    # Log memory
    echo -e "\nMemory:" >> "$INSTALL_LOG"
    free -h >> "$INSTALL_LOG" 2>&1
}

# Status functions
status_msg() { echo -e "${CYAN}[*] ${WHITE}$1${NC}"; echo "[*] $1" >> "$INSTALL_LOG"; }
success_msg() { echo -e "${GREEN}[✓] ${WHITE}$1${NC}"; echo "[✓] $1" >> "$INSTALL_LOG"; }
warning_msg() { echo -e "${YELLOW}[!] ${WHITE}$1${NC}"; echo "[!] $1" >> "$INSTALL_LOG"; }
error_msg() { echo -e "${RED}[✗] ${WHITE}$1${NC}"; echo "[✗] $1" >> "$INSTALL_LOG"; exit 1; }

# Check if command exists
command_exists() { command -v "$1" >/dev/null 2>&1; }

# Get sudo privileges
get_sudo() {
    status_msg "Checking sudo privileges..."
    sudo -v || error_msg "Failed to get sudo privileges"
    success_msg "Sudo privileges confirmed"
}

# Show banner
show_banner() {
    clear
    echo -e "${MAGENTA}# --------------------------------------------${NC}"
    echo -e "${MAGENTA}# ${WHITE}LAZARUS INSTALLER 2.8${NC}"
    echo -e "${MAGENTA}# ${WHITE}Complete Clean Installation${NC}"
    echo -e "${MAGENTA}# ${WHITE}Author: Mohammed Alotaibi${NC}"
    echo -e "${MAGENTA}# ${WHITE}Last Update: 2025-08-03${NC}"
    echo -e "${MAGENTA}# --------------------------------------------${NC}\n"
}

# Check root
check_root() {
    [ "$EUID" -eq 0 ] && error_msg "Please run as normal user (not root)"
    success_msg "User check passed (normal user)"
}

# Comprehensive cleanup
cleanup_old_install() {
    status_msg "Starting complete Lazarus/FPC removal..."
    
    # Remove all package variants
    local packages=($(dpkg -l | grep -E '^ii.*(fpc|lazarus)' | awk '{print $2}'))
    if [ ${#packages[@]} -gt 0 ]; then
        status_msg "Removing packages: ${packages[*]}"
        
        
        sudo apt-get remove --purge -y "${packages[@]}" >> "$INSTALL_LOG" 2>&1 || {
            warning_msg "Some packages couldn't be removed"
        }
        
        
        sudo apt-get remove --purge -y fp-compiler* >> "$INSTALL_LOG" 2>&1 || {
            warning_msg "Some packages couldn't be removed"
        }
        
        sudo apt-get autoremove -y >> "$INSTALL_LOG" 2>&1 || {
            warning_msg "Some packages couldn't be removed"
        }
        
        
        
        
        
        
    else
        warning_msg "No Lazarus/FPC packages found"
    fi

    # Remove all known directories
    local dirs=(
        "/usr/lib/fpc" "/usr/lib/lazarus" 
        "/usr/share/fpcsrc" "/usr/share/fpc"
        "/usr/share/doc/fpc" "/usr/share/lazarus"
        "/etc/lazarus" "$HOME/.lazarus" "$HOME/.fppkg" "$HOME/.fpc"
    )
    for dir in "${dirs[@]}"; do
        if [ -e "$dir" ]; then
            status_msg "Removing directory: $dir"
            sudo rm -rf "$dir" >> "$INSTALL_LOG" 2>&1 || warning_msg "Failed to remove $dir"
        fi
    done

    # Remove all configuration files
    local configs=(
        "/etc/fpc.cfg" "$HOME/.fpc.cfg" 
        "/etc/fppkg.cfg" "/etc/lazarus.cfg"
        "/etc/fpc-*.cfg" "/etc/fpc-*.bak"
    )
    for cfg in "${configs[@]}"; do
        if [ -e "$cfg" ]; then
            status_msg "Removing config: $cfg"
            sudo rm -f "$cfg" >> "$INSTALL_LOG" 2>&1
        fi
    done

    # Clean up binaries
    status_msg "Cleaning up binaries..."
    sudo find /usr/bin -name "fpc*" -delete >> "$INSTALL_LOG" 2>&1
    sudo find /usr/bin -name "pp*" -delete >> "$INSTALL_LOG" 2>&1
    sudo find /usr/bin -name "lazarus*" -delete >> "$INSTALL_LOG" 2>&1

    # Final cleanup
    sudo apt-get autoremove -y >> "$INSTALL_LOG" 2>&1
    sudo apt-get clean >> "$INSTALL_LOG" 2>&1

    success_msg "Complete cleanup finished"
}

# Install dependencies
install_deps() {
    status_msg "Installing required dependencies..."
    local deps=(
        git build-essential binutils gdb make
        libgtk2.0-dev libx11-dev libgpm-dev
        libglib2.0-dev libpango1.0-dev
        zlib1g-dev libncurses5-dev libssl-dev
        libsqlite3-dev libpq-dev
        fp-compiler fp-utils-3.2.2 fpc-source
    )
    
    # Check system resources first
    status_msg "Checking system resources..."
    local disk_space=$(df -m / | awk 'NR==2 {print $4}')
    local free_mem=$(free -m | awk '/Mem:/ {print $4}')
    
    echo -e "\n${YELLOW}System Resources:${NC}"
    echo -e "  Disk Space Available: ${disk_space}MB"
    echo -e "  Free Memory: ${free_mem}MB"
    
    if [ "$disk_space" -lt "$MIN_DISK_SPACE" ]; then
        error_msg "Insufficient disk space (need ${MIN_DISK_SPACE}MB, found ${disk_space}MB)"
    fi

    # Install FPC and utilities first
    status_msg "Installing Free Pascal Compiler and utilities..."
    sudo apt-get install -y fp-compiler fp-utils-3.2.2 fpc-source >> "$INSTALL_LOG" 2>&1 || {
        error_msg "FPC installation failed"
    }
    
    # Install remaining dependencies
    status_msg "Installing build dependencies..."
    sudo apt-get install -y "${deps[@]}" >> "$INSTALL_LOG" 2>&1 || {
        error_msg "Dependency installation failed"
    }
    
    # Verify FPC installation
    if ! command_exists fpc; then
        error_msg "FPC compiler not found after installation"
    fi
    
    success_msg "All dependencies installed"
}

# Install from source
install_source() {
    status_msg "Installing from source..."
    
    # Verify minimum disk space
    local available_space=$(df -m / | awk 'NR==2 {print $4}')
    [ "$available_space" -lt "$MIN_DISK_SPACE" ] && error_msg "Insufficient disk space"

    # Clone/update repo
    if [ -d "$LAZARUS_SOURCE_DIR" ]; then
        status_msg "Updating existing repository..."
        cd "$LAZARUS_SOURCE_DIR" || error_msg "Cannot access source directory"
        git pull >> "$INSTALL_LOG" 2>&1 || error_msg "Git pull failed"
    else
        status_msg "Cloning repository..."
        git clone --depth 1 https://gitlab.com/freepascal.org/lazarus/lazarus.git "$LAZARUS_SOURCE_DIR" >> "$INSTALL_LOG" 2>&1 || error_msg "Git clone failed"
        cd "$LAZARUS_SOURCE_DIR" || error_msg "Cannot access source directory"
    fi

    # Step 1: Build the IDE first (crucial step)
    status_msg "Building IDE components (Step 1/3)..."
    make -C ide clean ide >> "$INSTALL_LOG" 2>&1 || {
        echo -e "\n${RED}=== IDE BUILD FAILURE ==="
        tail -n 30 "$INSTALL_LOG"
        echo -e "\n${YELLOW}Troubleshooting:"
        echo -e "1. Verify FPC is installed: fpc -v"
        echo -e "2. Check dependencies: dpkg -l | grep 'libgtk2.0-dev\|libx11-dev'"
        echo -e "3. Clean and retry: make -C ide clean ide"
        echo -e "========================${NC}"
        error_msg "IDE build failed"
    }

    # Step 2: Build the LCL (Lazarus Component Library)
    status_msg "Building LCL components (Step 2/3)..."
    make -C lcl clean all >> "$INSTALL_LOG" 2>&1 || {
        echo -e "\n${RED}=== LCL BUILD FAILURE ==="
        tail -n 30 "$INSTALL_LOG"
        echo -e "\n${YELLOW}Troubleshooting:"
        echo -e "1. Check disk space: df -h"
        echo -e "2. Try with single core: make -j1 -C lcl all"
        echo -e "========================${NC}"
        error_msg "LCL build failed"
    }

    # Step 3: Build everything
    status_msg "Building complete system (Step 3/3)..."
    make -j$BUILD_JOBS all >> "$INSTALL_LOG" 2>&1 || {
        echo -e "\n${RED}=== BUILD FAILURE ==="
        tail -n 30 "$INSTALL_LOG"
        echo -e "\n${YELLOW}Troubleshooting:"
        echo -e "1. Try with single core: make -j1 all"
        echo -e "2. Check memory: free -h"
        echo -e "3. Clean and restart: make clean all"
        echo -e "========================${NC}"
        error_msg "Main build failed"
    }

    # Install
    status_msg "Installing system-wide..."
    sudo make install >> "$INSTALL_LOG" 2>&1 || error_msg "Installation failed"
    
    # Verify
    [ -x "$LAZARUS_EXEC" ] || error_msg "Lazarus executable not found"
    sudo ln -sf "$LAZARUS_EXEC" /usr/bin/lazarus
    
    # Final checks
    status_msg "Verifying installation..."
    if ! command_exists lazarus; then
        warning_msg "Lazarus not in PATH, you may need to log out and back in"
    else
        lazarus --version >> "$INSTALL_LOG" 2>&1 || warning_msg "Version check failed"
    fi
    
    success_msg "Lazarus successfully installed to $LAZARUS_EXEC"
}

# Create desktop file
create_desktop() {
    status_msg "Creating desktop shortcut..."
    mkdir -p "$(dirname "$DESKTOP_FILE")"
    
    # Find suitable icon
    local icon_path="$ICON_PATH"
    [ -f "$icon_path" ] || icon_path="/usr/share/pixmaps/lazarus.xpm"
    [ -f "$icon_path" ] || icon_path="/usr/share/icons/hicolor/48x48/apps/lazarus.png"
    [ -f "$icon_path" ] || icon_path=""
    
    cat > "$DESKTOP_FILE" <<EOL
[Desktop Entry]
Name=Lazarus IDE
GenericName=IDE
Comment=Free Pascal IDE
Exec=$LAZARUS_EXEC --pcp=\$HOME/.lazarus
Icon=$icon_path
Terminal=false
Type=Application
Categories=Development;IDE;Programming;
StartupWMClass=lazarus
Keywords=editor;Pascal;IDE;FreePascal;fpc;design;delphi;
EOL

    [ -f "$DESKTOP_FILE" ] || warning_msg "Desktop file creation failed"
    update-desktop-database "$HOME/.local/share/applications" >> "$INSTALL_LOG" 2>&1
    success_msg "Desktop shortcut created"
}

# Main installation menu
show_menu() {
    echo -e "\n${YELLOW}Installation Method:${NC}"
    echo -e "1) Clean Install from Source (Recommended)"
    echo -e "2) Install from System Repositories"
    echo -e "3) Install from Local .deb Packages"
    echo -e "4) Exit"
    echo -ne "\n${CYAN}Select option [1-4]: ${NC}"
}

# Main function
main() {
    show_banner
    init_log
    check_root
    get_sudo
    
    # Cleanup existing installations
    cleanup_old_install
    
    # Install dependencies
    install_deps
    
    # Installation method selection
    while true; do
        show_menu
        read -r choice
        case $choice in
            1) install_source; break ;;
            2) sudo apt-get install -y lazarus; break ;;
            3) sudo dpkg -i ./*.deb; sudo apt-get -f install; break ;;
            4) echo -e "\n${YELLOW}Installation cancelled.${NC}"; exit 0 ;;
            *) echo -e "${RED}Invalid choice!${NC}" ;;
        esac
    done
    
    # Final setup
    create_desktop
    
    # Completion message
    echo -e "\n${GREEN}# ====================================${NC}"
    echo -e "${GREEN}#  LAZARUS INSTALLATION COMPLETE!  ${NC}"
    echo -e "${GREEN}# ====================================${NC}"
    echo -e "Launch with: ${CYAN}lazarus${NC}"
    echo -e "Install log: ${CYAN}$INSTALL_LOG${NC}"
    echo -e "\n${YELLOW}System Status:${NC}"
    df -h /
    free -h
}

# Start installation
main "$@"
