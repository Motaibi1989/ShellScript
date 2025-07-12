#!/bin/bash

# Ultimate Ubuntu Setup Script - English Version - for Mohammed Alotaibi
# Motaibi1989


set -eo pipefail

# ─── Formatting ──────────────────────────────────────
BOLD=$(tput bold)
RESET=$(tput sgr0)
RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
BLUE=$(tput setaf 4)
CYAN=$(tput setaf 6)

# ─── Logging ─────────────────────────────────────────
log_info()    { echo "${BLUE}[INFO] ${BOLD}${1}${RESET}"; }
log_success() { echo "${GREEN}[OK]   ${BOLD}${1}${RESET}"; }
log_warning() { echo "${YELLOW}[WARN] ${BOLD}${1}${RESET}"; }
log_error()   { echo "${RED}[ERROR]${BOLD} ${1}${RESET}"; exit 1; }

# ─── Setup Logging to File ───────────────────────────
exec > >(tee -a "setup.log")
exec 2>&1

# ─── Flags ───────────────────────────────────────────
SILENT=0
[[ "$1" == "--silent" ]] && SILENT=1

# ─── Root Check ──────────────────────────────────────
check_root() {
    if [[ $EUID -eq 0 ]]; then
        log_warning "Please run the script as a normal user. sudo will be used when needed."
        exit 1
    fi
}

# ─── Internet Check ──────────────────────────────────
check_internet() {
    if ! ping -c 1 -q google.com &> /dev/null; then
        log_error "No internet connection detected"
    fi
}

# ─── Prompt Helper ───────────────────────────────────
ask_user() {
    local prompt="${1:-Do you want to continue?} [y/N]: "
    if [[ $SILENT -eq 1 ]]; then
        echo "y"
    else
        read -p "${BOLD}${prompt}${RESET}" choice
        [[ "$choice" =~ ^[Yy]$ ]] && return 0 || return 1
    fi
}

# ─── System Update ───────────────────────────────────
update_system() {
    log_info "Updating system packages..."
    sudo apt update -qq || log_error "Failed to update package list"
    sudo apt upgrade -y -qq || log_warning "Some packages were not upgraded"
}

# ─── Package Installation ────────────────────────────
install_package() {
    local pkg=$1
    if dpkg -l | grep -qw "^ii  $pkg "; then
        log_info "$pkg is already installed"
        return 0
    fi

    log_info "Installing $pkg..."
    if sudo apt install -y -qq "$pkg"; then
        log_success "$pkg installed successfully"
    else
        log_warning "Failed to install $pkg"
        return 1
    fi
}

install_packages() {
    local category=$1
    shift
    local packages=("$@")
    log_info "Installing category: ${CYAN}$category${RESET}"
    local failed=0
    for pkg in "${packages[@]}"; do
        install_package "$pkg" || ((failed++))
    done
    if [[ $failed -gt 0 ]]; then
        log_warning "$failed packages failed under $category"
    else
        log_success "All $category packages installed successfully"
    fi
}

# ─── Add 3rd-Party Repositories ──────────────────────
add_repositories() {
    log_info "Adding external repositories..."

    # Brave
    if ! [[ -f /etc/apt/sources.list.d/brave-browser-release.list ]]; then
        curl -fsSLo brave-browser.gpg https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg
        sudo install -o root -g root -m 644 brave-browser.gpg /usr/share/keyrings/
        echo "deb [signed-by=/usr/share/keyrings/brave-browser.gpg] https://brave-browser-apt-release.s3.brave.com/ stable main" |
            sudo tee /etc/apt/sources.list.d/brave-browser-release.list > /dev/null
    fi

    # VS Code
    if ! [[ -f /etc/apt/sources.list.d/vscode.list ]]; then
        wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor | sudo tee /usr/share/keyrings/packages.microsoft.gpg > /dev/null
        echo "deb [arch=amd64 signed-by=/usr/share/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/vscode stable main" |
            sudo tee /etc/apt/sources.list.d/vscode.list > /dev/null
    fi

    sudo apt update -qq
}

# ─── Main Software Categories ────────────────────────
install_main_components() {
    declare -A PACKAGES=(
        ["System"]="build-essential dkms deborphan net-tools curl wget xclip fakeroot inxi jq whois iptraf-ng htop neofetch"
        ["Development"]="g++ gdb cmake code git emacs dotnet-sdk-8.0 dotnet-runtime-8.0"
        ["Network"]="firefox httpie openvpn remmina nmap"
        ["Desktop"]="gnome-tweaks baobab catfish engrampa cheese-common kate exif"
        ["Media"]="vlc"
        ["Remote"]="rustdesk discord bind9-dnsutils apg"
    )

    for category in "${!PACKAGES[@]}"; do
        IFS=' ' read -ra pkg_list <<< "${PACKAGES[$category]}"
        install_packages "$category" "${pkg_list[@]}"
    done
}

# ─── Optional Tools ──────────────────────────────────
install_optional_components() {
    if ask_user "Do you want to install Brave Browser?"; then
        install_packages "Brave" "brave-browser"
    fi

    if ask_user "Do you want to install Kali Linux tools?"; then
        log_info "Adding Kali repository..."
        echo "deb http://http.kali.org/kali kali-rolling main non-free contrib" |
            sudo tee /etc/apt/sources.list.d/kali.list > /dev/null
        wget -q -O - https://archive.kali.org/archive-key.asc | sudo apt-key add - || \
            log_warning "Failed to import Kali key"
        sudo apt update -qq

        declare -A KALI_TOOLS=(
            ["Recon"]="nmap netcat dnsutils whois whatweb nikto wafw00f"
            ["Sniffing"]="wireshark tcpdump ettercap-graphical bettercap"
            ["Vulnerability"]="sqlmap lynis searchsploit"
            ["Password"]="hydra john hashcat wordlists"
            ["Exploitation"]="metasploit-framework exploitdb"
            ["Shell"]="socat rlwrap"
            ["Wireless"]="aircrack-ng reaver wifite pixiewps"
        )

        for category in "${!KALI_TOOLS[@]}"; do
            IFS=' ' read -ra pkg_list <<< "${KALI_TOOLS[$category]}"
            install_packages "Kali $category" "${pkg_list[@]}"
        done

        log_success "Kali tools installed successfully"
    else
        log_info "Kali tools skipped"
    fi
}

# ─── System Cleanup ──────────────────────────────────
cleanup_system() {
    log_info "Cleaning up the system..."
    sudo apt autoremove -y -qq
    sudo apt clean -qq

    if command -v deborphan &> /dev/null; then
        orphans=$(deborphan)
        if [[ -n "$orphans" ]]; then
            log_warning "Orphaned packages detected:"
            echo "$orphans"
            if ask_user "Do you want to remove orphaned packages?"; then
                sudo apt remove --purge -y -qq $orphans
            fi
        fi
    fi
}

# ─── Main Entry Point ────────────────────────────────
main() {
    check_root
    check_internet
    update_system
    add_repositories
    install_main_components
    install_optional_components
    cleanup_system

    log_success "${BOLD}Setup completed successfully!${RESET}"
    echo -e "\n${BOLD}System Information:${RESET}"
    command -v neofetch &> /dev/null && neofetch --stdout | grep -E 'OS|Kernel|Uptime|Shell|CPU|GPU|Memory'
    echo -e "\n${YELLOW}Please reboot the system to apply all changes.${RESET}"
}

main
