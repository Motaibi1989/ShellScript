#!/bin/bash

# --------------------------------------------
# LAZARUS INSTALLER 2.0
# Author: Mohammed Alotaibi (motaibi1989.com)
# Last Update: 2025-07-27
# --------------------------------------------

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Configuration
LAZARUS_SOURCE_DIR="$HOME/lazarus-source"
DESKTOP_FILE="$HOME/.local/share/applications/lazarus.desktop"
INSTALL_LOG="/tmp/lazarus_install.log"

# Banner
show_banner() {
    clear
    echo -e "${WHITE}# --------------------------------------------${NC}"
    echo -e "${WHITE}# LAZARUS INSTALLER 2.0${NC}"
    echo -e "${WHITE}# Author: Mohammed Alotaibi (motaibi1989.com)${NC}"
    echo -e "${WHITE}# Last Update: 2025-07-27${NC}"
    echo -e "${WHITE}# --------------------------------------------${NC}\n"
}

# Check if running as root
check_root() {
    if [ "$EUID" -eq 0 ]; then
        echo -e "${RED}Please do not run this script as root.${NC}"
        exit 1
    fi
}

# Cleanup previous installations
cleanup_old_install() {
    echo -e "${YELLOW}[+] Removing existing Lazarus/FPC installations...${NC}"
    
    sudo sh -c "apt autoremove --purge -y fpc lazarus lazarus-ide \
    lazarus-ide-2.0 lazarus-project fpc-source 2>>$INSTALL_LOG && \
    rm -Rf /usr/lib/fpc && \
    rm -Rf /usr/lib/lazarus && \
    rm -Rf /usr/share/fpcsrc && \
    rm -Rf /etc/lazarus && \
    rm -rf /etc/fpc.* && \
    rm -rf /etc/fpc-* && \
    rm -rf /etc/fppkg* && \
    rm -f ~/.fpc* && \
    rm -Rf ~/.lazarus" 2>>$INSTALL_LOG
    
    echo -e "${GREEN}[✓] Cleanup completed${NC}"
}

# Install dependencies
install_dependencies() {
    echo -e "${YELLOW}[+] Installing build dependencies...${NC}"
    sudo apt update >>$INSTALL_LOG 2>&1
    sudo apt install -y git build-essential binutils libgtk2.0-dev >>$INSTALL_LOG 2>&1
    echo -e "${GREEN}[✓] Dependencies installed${NC}"
}

# Install from source
install_from_source() {
    echo -e "${YELLOW}[+] Installing Lazarus from source...${NC}"
    
    # Clone or update repository
    if [ -d "$LAZARUS_SOURCE_DIR" ]; then
        echo -e "${WHITE}[*] Updating existing repository...${NC}"
        cd "$LAZARUS_SOURCE_DIR" && git pull >>$INSTALL_LOG 2>&1
    else
        echo -e "${WHITE}[*] Cloning repository...${NC}"
        git clone https://gitlab.com/freepascal.org/lazarus/lazarus.git "$LAZARUS_SOURCE_DIR" >>$INSTALL_LOG 2>&1
    fi
    
    # Build and install
    cd "$LAZARUS_SOURCE_DIR"
    make clean all >>$INSTALL_LOG 2>&1
    sudo make install >>$INSTALL_LOG 2>&1
    
    echo -e "${GREEN}[✓] Lazarus installed from source${NC}"
}

# Install from packages
install_from_packages() {
    echo -e "${YELLOW}[+] Installing Lazarus from packages...${NC}"
    
    # Find and install packages
    for pkg in ./fpc*.deb ./lazarus-project*.deb; do
        if [ -f "$pkg" ]; then
            echo -e "${WHITE}[*] Installing $pkg...${NC}"
            sudo dpkg --install "$pkg" >>$INSTALL_LOG 2>&1
        fi
    done
    
    # Fix potential dependencies
    sudo apt --fix-broken install -y >>$INSTALL_LOG 2>&1
    
    echo -e "${GREEN}[✓] Lazarus installed from packages${NC}"
}

# Create desktop file
create_desktop_file() {
    echo -e "${YELLOW}[+] Creating desktop shortcut...${NC}"
    
    mkdir -p "$HOME/.local/share/applications"
    cat > "$DESKTOP_FILE" <<EOL
[Desktop Entry]
Name=Lazarus IDE
GenericName=IDE
Comment=Free Pascal IDE
Exec=/usr/local/bin/lazarus --pcp=\$HOME/.lazarus
Icon=/usr/local/share/lazarus/images/icons/lazarus.ico
Terminal=false
Type=Application
Categories=Development;IDE;Programming;
StartupWMClass=lazarus
EOL
    
    echo -e "${GREEN}[✓] Desktop file created at $DESKTOP_FILE${NC}"
}

# Installation menu
show_menu() {
    echo -e "\n${YELLOW}Select installation method:${NC}"
    echo -e "1) Install from source (recommended)"
    echo -e "2) Install from local packages"
    echo -e "3) Exit"
    echo -ne "\n${WHITE}Enter your choice [1-3]: ${NC}"
}

# Main function
main() {
    show_banner
    check_root
    
    # Cleanup old installations
    cleanup_old_install
    
    # Install dependencies
    install_dependencies
    
    # Show installation menu
    while true; do
        show_menu
        read choice
        case $choice in
            1)
                install_from_source
                create_desktop_file
                break
                ;;
            2)
                install_from_packages
                create_desktop_file
                break
                ;;
            3)
                echo -e "${RED}Installation aborted.${NC}"
                exit 0
                ;;
            *)
                echo -e "${RED}Invalid option, please try again.${NC}"
                ;;
        esac
    done
    
    echo -e "\n${GREEN}Installation completed successfully!${NC}"
    echo -e "You can now launch Lazarus from your application menu."
    echo -e "Installation log: $INSTALL_LOG"
}

# Execute main function
main
