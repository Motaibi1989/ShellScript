#!/bin/bash

# --------------------------------------------
# NAMP SCANNER 2.1
# Author: Mohammed Alotaibi (motaibi1989.com)
# Last Update: 2025-07-12
# --------------------------------------------

# ===== CONFIGURATION =====
SCAN_DIR="./nmap_results"  # Save in current directory
MAX_PARALLEL_SCANS=3

# All available NSE scripts
NSE_SCRIPTS=(
    "http-vuln-*:Web vulnerability checks"
    "ssl-*:SSL/TLS checks"
    "smb-vuln-*:SMB vulnerabilities"
    "dns-*:DNS enumeration"
    "ftp-*:FTP server checks"
    "ssh-*:SSH security checks"
    "sql-injection:SQL injection detection"
)

# Advanced commands with full documentation
ADVANCED_COMMANDS=(
    # Format: "Name:Command:Description:Full documentation"
    "Stealth_SYN_scan:-sS -T4:Quick SYN scan:SYN scan never completes TCP connections, making it stealthier than full connect scans"
    "UDP_scan:-sU:Scan UDP services:Scans UDP ports which are often overlooked but critical for security"
    "OS_detection:-O:Remote OS detection:Uses TCP/IP fingerprinting to identify remote OS (requires root)"
    "Aggressive_scan:-A:Full aggressive scan:Enables OS detection, version detection, script scanning, and traceroute"
    "Firewall_evasion:-Pn -f --data-length 24:Bypass firewalls:Treats all hosts as online, fragments packets, and adds random data length"
    "ACK_scan:-sA:Firewall detection:ACK scan helps map firewall rulesets by sending ACK packets"
    "Ping_sweep:-sn:Network discovery:Ping scan that lists responsive hosts without port scanning"
    "Fast_scan:-F:Quick port scan:Scans only the 100 most common ports"
    "Version_detection:-sV:Service fingerprinting:Determines service/version info for open ports"
    "Null_scan:-sN:Firewall evasion:Sends packets with no flags set to bypass simple firewalls"
    "TCP_scan:-sT:Reliable connect scan:Completes full TCP connections (more reliable but detectable)"
    "Port_randomization:-r:Sequential port scan:Disables random port scanning for consecutive scanning"
    "Interface_list:--iflist:Show interfaces:Displays host interfaces and routes"
    "Custom_port_scan:-p:Specify ports:Scan specific ports (e.g., -p 80 or -p 1-1000)"
    "UDP_port_scan:-sU -p:UDP port scan:Scan specific UDP ports (e.g., -sU -p 53,67,161)"
    "TCP_SYN_ping:-PS:SYN ping discovery:Sends SYN packets to check for live hosts"
    "TCP_ACK_ping:-PA:ACK ping discovery:Sends ACK packets to check for live hosts"
)

# ===== FUNCTIONS =====
show_banner() {
    clear
    echo "=============================================="
    echo "            Nmap Advanced Scanner 2.1"
    echo "=============================================="
    echo
}

show_commands() {
    echo "=== AVAILABLE SCANNING COMMANDS ==="
    echo "1)  Network Discovery       (nmap -sn)"
    echo "2)  Quick Port Scan         (nmap -T4 -F)"
    echo "3)  Comprehensive Scan      (nmap -sV -O -A)"
    echo "4)  Vulnerability Scan      (nmap --script vuln)"
    echo "5)  Custom NSE Script Scan"
    echo "6)  Full Port Scan          (nmap -p-)"
    echo "7)  Parallel Scans          (Multiple scans)"
    echo "8)  Advanced Techniques"
    echo "9)  List All NSE Scripts"
    echo "10) List All Advanced Commands"
    echo "0)  Exit"
    echo
}

show_examples() {
    echo "=== QUICK EXAMPLES ==="
    echo "Network sweep:        nmap -sn 192.168.1.0/24"
    echo "Top ports scan:       nmap -T4 -F 192.168.1.1"
    echo "Full service scan:    nmap -sV -O -A target.com"
    echo "Vuln detection:       nmap --script vuln 10.0.0.5"
    echo "Custom NSE scan:      nmap --script http-* -p80,443 example.com"
    echo "Full port scan:       nmap -p- -T4 192.168.1.100"
    echo "OS detection:         nmap -O target.com"
    echo "Firewall detection:   nmap -sA 192.168.1.1"
    echo "UDP scan:             nmap -sU -p53,67,68 192.168.1.1"
    echo
}

list_nse_scripts() {
    echo "=== AVAILABLE NSE SCRIPTS ==="
    for script in "${NSE_SCRIPTS[@]}"; do
        IFS=':' read -r name desc <<< "$script"
        printf "%-20s %s\n" "$name" "$desc"
    done
    echo
}

show_advanced_commands() {
    echo "=== ADVANCED COMMANDS (Full Documentation) ==="
    for i in "${!ADVANCED_COMMANDS[@]}"; do
        IFS=':' read -r name cmd short_desc full_desc <<< "${ADVANCED_COMMANDS[$i]}"
        printf "%2d) %-20s %-20s\n" "$((i+1))" "$name" "$cmd"
        printf "     Short: %s\n" "$short_desc"
        printf "     Full:  %s\n\n" "$full_desc"
    done
}

create_output_dir() {
    mkdir -p "$SCAN_DIR" || {
        echo "[!] Failed to create output directory"
        exit 1
    }
    echo "[*] Scan results will be saved in: $SCAN_DIR"
}

run_scan() {
    local target=$1
    local choice=$2
    
    case $choice in
        1) nmap -sn --stats-every 10s "$target" -oN "$SCAN_DIR/network_discovery.txt" ;;
        2) nmap -T4 -F --stats-every 10s "$target" -oN "$SCAN_DIR/quick_scan.txt" ;;
        3) nmap -sV -O -A --stats-every 10s "$target" -oN "$SCAN_DIR/full_scan.txt" ;;
        4) nmap --script vuln --stats-every 10s "$target" -oN "$SCAN_DIR/vuln_scan.txt" ;;
        5) run_custom_nse_scan "$target" ;;
        6) nmap -p- -T4 --stats-every 10s "$target" -oN "$SCAN_DIR/all_ports.txt" ;;
        7) run_parallel_scans "$target" ;;
        8) run_advanced_scan "$target" ;;
        *) echo "[!] Invalid option"; return 1 ;;
    esac
}

run_custom_nse_scan() {
    local target=$1
    list_nse_scripts
    read -p "[?] Enter script name (e.g. http-vuln-*): " script_name
    read -p "[?] Enter ports (optional, e.g. 80,443): " ports
    
    local scan_cmd="nmap --script $script_name"
    [ -n "$ports" ] && scan_cmd+=" -p $ports"
    scan_cmd+=" --stats-every 10s $target -oN $SCAN_DIR/nse_scan.txt"
    
    echo "[*] Running: $scan_cmd"
    eval "$scan_cmd"
}

run_advanced_scan() {
    local target=$1
    show_advanced_commands
    read -p "[?] Select advanced command (1-${#ADVANCED_COMMANDS[@]}): " choice
    
    if [[ $choice -lt 1 || $choice -gt ${#ADVANCED_COMMANDS[@]} ]]; then
        echo "[!] Invalid selection"
        return 1
    fi
    
    IFS=':' read -r name cmd short_desc full_desc <<< "${ADVANCED_COMMANDS[$((choice-1))]}"
    local scan_cmd="nmap $cmd --stats-every 10s $target -oN $SCAN_DIR/advanced_$name.txt"
    
    echo "[*] Running: $scan_cmd"
    echo "[*] Purpose: $full_desc"
    eval "$scan_cmd"
}

run_parallel_scans() {
    local target=$1
    echo "[*] Running parallel scans (max $MAX_PARALLEL_SCANS)"
    
    # Define scans to run in parallel
    declare -A scans=(
        ["ping"]="nmap -sn"
        ["quick"]="nmap -T4 -F"
        ["services"]="nmap -sV"
    )
    
    # Run scans in background
    for scan in "${!scans[@]}"; do
        echo "[>] Starting $scan scan..."
        eval "${scans[$scan]} --stats-every 10s $target -oN $SCAN_DIR/parallel_$scan.txt" &
    done
    
    # Wait for all scans to complete
    wait
    echo "[+] Parallel scans completed"
}

# ===== MAIN PROGRAM =====
show_banner
create_output_dir
show_examples

while true; do
    show_commands
    read -p "[?] Enter command number: " choice
    
    case $choice in
        0) echo "[*] Exiting..."; exit 0 ;;
        9) list_nse_scripts ;;
        10) show_advanced_commands ;;
        [1-8]) 
            read -p "[?] Enter target (IP/CIDR/hostname): " target
            run_scan "$target" "$choice" 
            ;;
        *) echo "[!] Invalid choice"; continue ;;
    esac
    
    read -p "[?] Run another scan? (y/n): " again
    [[ "$again" =~ ^[Yy] ]] || break
done

echo "[+] All scan results saved in: $SCAN_DIR"
echo "[*] Use 'cat $SCAN_DIR/<filename>' to view results"
