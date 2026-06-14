#!/usr/bin/env bash

# ==========================================================
# Project: VULNER - Automated Vulnerability Scanner
# Program Code: ZX301
# Author: David Rozi
# Academic Project: ZX301 VULNER
#
# Description:
# This script automates authorized local network scanning,
# service enumeration, weak credential checks, and vulnerability mapping.
#
# Scope:
# Use this script only in authorized lab environments or networks
# where explicit permission was granted.
# ==========================================================

set -o pipefail

AUTHOR_NAME="David Rozi"
PROJECT_CODE="ZX301"
PROGRAM_CODE="zx301"
SCRIPT_VERSION="1.0"

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RESULTS_ROOT="$BASE_DIR/results"
DEFAULT_PASSLIST="$BASE_DIR/password.lst"
DEFAULT_USERLIST="$BASE_DIR/user.lst"
RUN_ID="$(date +%Y%m%d_%H%M%S)"

NETWORK=""
OUTPUT_NAME=""
OUTPUT_DIR=""
MODE=""
PASSLIST=""
LOG_FILE="$RESULTS_ROOT/precheck_${RUN_ID}.log"
ZIP_FILE=""

mkdir -p "$RESULTS_ROOT"
touch "$LOG_FILE"

ensure_default_lists() {
    # Create the built-in password list if it does not exist.
    # This keeps the final .sh file self-contained for project submission.
    if [[ ! -f "$DEFAULT_PASSLIST" ]]; then
        cat > "$DEFAULT_PASSLIST" << 'EOF'
admin
password
123456
12345678
qwerty
letmein
toor
root
kali
user
test
Passw0rd
Password1
EOF
    fi

    # Create the default username list if it does not exist.
    # Hydra requires usernames and passwords for weak credential testing.
    if [[ ! -f "$DEFAULT_USERLIST" ]]; then
        cat > "$DEFAULT_USERLIST" << 'EOF'
admin
administrator
root
kali
user
test
guest
ftp
service
scanner
EOF
    fi
}



show_help() {
    cat << 'EOF'
VULNER - Automated Vulnerability Scanner

Usage:
  ./vulner.sh
  ./vulner.sh --help

Modes:
  Basic  Host discovery, TCP scan, UDP scan, service versions, weak credential checks
  Full   Basic mode plus Nmap NSE vulnerability scan and Searchsploit analysis

Scope:
  Use only on networks you own or have explicit authorization to test.

Outputs:
  results/<name>_<mode>_<timestamp>/
  results/<name>_<mode>_<timestamp>.zip
EOF
}

print_banner() {
    clear
    echo "=========================================================="
    echo " VULNER - Automated Vulnerability Scanner"
    echo " Program Code: $PROGRAM_CODE"
    echo " Author: $AUTHOR_NAME"
    echo " Version: $SCRIPT_VERSION"
    echo "=========================================================="
    echo
}

print_stage() {
    echo
    echo "[+] $1" | tee -a "$LOG_FILE"
}

print_info() {
    echo "[INFO] $1" | tee -a "$LOG_FILE"
}

print_warn() {
    echo "[WARNING] $1" | tee -a "$LOG_FILE"
}

die() {
    echo "[ERROR] $1" | tee -a "$LOG_FILE"
    exit 1
}

check_tools() {
    print_stage "Checking required tools"

    local missing=0
    local tools=(nmap hydra searchsploit zip grep awk sed tee python3)

    for tool in "${tools[@]}"; do
        if command -v "$tool" >/dev/null 2>&1; then
            echo "[OK] $tool found: $(command -v "$tool")" | tee -a "$LOG_FILE"
        else
            echo "[MISSING] $tool is not installed" | tee -a "$LOG_FILE"
            missing=1
        fi
    done

    if [[ "$missing" -eq 1 ]]; then
        die "Install the missing tools and run the script again."
    fi
}

validate_network() {
    python3 - "$1" << 'PYCODE'
import sys
import ipaddress

try:
    ipaddress.ip_network(sys.argv[1], strict=False)
    sys.exit(0)
except Exception:
    sys.exit(1)
PYCODE
}

require_private_network() {
    python3 - "$1" << 'PYCODE'
import sys
import ipaddress

net = ipaddress.ip_network(sys.argv[1], strict=False)

if net.is_private:
    sys.exit(0)

print("[ERROR] The selected network is not a private local network.")
print("[ERROR] This project script is restricted to authorized lab/private ranges only.")
print("[ERROR] Use ranges such as 10.0.0.0/8, 172.16.0.0/12, or 192.168.0.0/16.")
sys.exit(1)
PYCODE
}

normalize_mode() {
    local raw
    raw="$(echo "$1" | tr '[:upper:]' '[:lower:]')"

    case "$raw" in
        basic|b)
            echo "Basic"
            ;;
        full|f)
            echo "Full"
            ;;
        *)
            return 1
            ;;
    esac
}

sanitize_name() {
    echo "$1" | tr -cd '[:alnum:]_.-'
}

get_user_input() {
    print_stage "Collecting user input"

    read -rp "Enter network to scan in CIDR format, example 192.168.47.0/24: " NETWORK

    if ! validate_network "$NETWORK"; then
        die "Invalid network format. Use CIDR format, for example 192.168.47.0/24"
    fi

    if ! require_private_network "$NETWORK" | tee -a "$LOG_FILE"; then
        die "Network validation failed."
    fi

    read -rp "Enter output directory name, example basic_scan: " OUTPUT_NAME
    OUTPUT_NAME="$(sanitize_name "$OUTPUT_NAME")"

    if [[ -z "$OUTPUT_NAME" ]]; then
        die "Output directory name cannot be empty."
    fi

    read -rp "Choose scan mode [Basic/Full]: " MODE_RAW

    if ! MODE="$(normalize_mode "$MODE_RAW")"; then
        die "Invalid scan mode. Choose Basic or Full."
    fi

    read -rp "Use custom password list? [y/N]: " CUSTOM_PASSLIST

    if [[ "$CUSTOM_PASSLIST" =~ ^[Yy]$ ]]; then
        read -erp "Enter full path to password list: " PASSLIST

        if [[ ! -f "$PASSLIST" ]]; then
            die "Custom password list was not found: $PASSLIST"
        fi
    else
        PASSLIST="$DEFAULT_PASSLIST"
    fi

    if [[ ! -f "$PASSLIST" ]]; then
        die "Password list was not found: $PASSLIST"
    fi

    if [[ ! -f "$DEFAULT_USERLIST" ]]; then
        die "User list was not found: $DEFAULT_USERLIST"
    fi

    local mode_lower
    mode_lower="$(echo "$MODE" | tr '[:upper:]' '[:lower:]')"

    OUTPUT_DIR="$RESULTS_ROOT/${OUTPUT_NAME}_${mode_lower}_${RUN_ID}"
    mkdir -p "$OUTPUT_DIR"

    LOG_FILE="$OUTPUT_DIR/run.log"
    touch "$LOG_FILE"

    print_info "Network: $NETWORK"
    print_info "Output directory: $OUTPUT_DIR"
    print_info "Scan mode: $MODE"
    print_info "Password list: $PASSLIST"
    print_info "User list: $DEFAULT_USERLIST"
}

run_privileged_nmap() {
    if [[ "$EUID" -eq 0 ]]; then
        nmap "$@"
    else
        sudo nmap "$@"
    fi
}

run_host_discovery() {
    print_stage "Running host discovery"

    nmap -sn "$NETWORK" -oA "$OUTPUT_DIR/01_host_discovery" | tee -a "$LOG_FILE"

    awk '/Status: Up/ {print $2}' "$OUTPUT_DIR/01_host_discovery.gnmap" | sort -u > "$OUTPUT_DIR/live_hosts.txt"

    local count
    count="$(wc -l < "$OUTPUT_DIR/live_hosts.txt")"

    print_info "Live hosts found: $count"

    if [[ "$count" -eq 0 ]]; then
        die "No live hosts found. Check the network range and connectivity."
    fi

    echo
    cat "$OUTPUT_DIR/live_hosts.txt" | tee -a "$LOG_FILE"
}

run_tcp_scan() {
    print_stage "Running TCP service scan with version detection"

    nmap -sT -sV --open -T4 -iL "$OUTPUT_DIR/live_hosts.txt" -oA "$OUTPUT_DIR/02_tcp_services" | tee -a "$LOG_FILE"
}

run_udp_scan() {
    print_stage "Running UDP service scan with version detection"

    print_info "UDP scanning can be slow. The script scans the top 20 UDP ports to keep the project practical."

    run_privileged_nmap -sU -sV --top-ports 20 --open -iL "$OUTPUT_DIR/live_hosts.txt" -oA "$OUTPUT_DIR/03_udp_services" | tee -a "$LOG_FILE"
}

run_weak_credentials() {
    print_stage "Checking weak credentials on SSH, FTP, TELNET, and RDP"

    local gnmap_file="$OUTPUT_DIR/02_tcp_services.gnmap"
    local hydra_dir="$OUTPUT_DIR/hydra_results"

    mkdir -p "$hydra_dir"

    if [[ ! -f "$gnmap_file" ]]; then
        print_warn "TCP scan output was not found. Skipping weak credential checks."
        return
    fi

    local found_services=0

    while IFS= read -r line; do
        local ip
        ip="$(echo "$line" | awk '{print $2}')"

        local ports_part
        ports_part="${line#*Ports: }"

        IFS=',' read -ra entries <<< "$ports_part"

        for entry in "${entries[@]}"; do
            entry="$(echo "$entry" | sed 's/^ *//;s/ *$//')"

            IFS='/' read -ra fields <<< "$entry"

            local port="${fields[0]}"
            local state="${fields[1]}"
            local proto="${fields[2]}"
            local service="${fields[4]}"

            if [[ "$state" != "open" || "$proto" != "tcp" ]]; then
                continue
            fi

            local hydra_service=""

            case "$service" in
                ssh)
                    hydra_service="ssh"
                    ;;
                ftp)
                    hydra_service="ftp"
                    ;;
                telnet)
                    hydra_service="telnet"
                    ;;
                ms-wbt-server)
                    hydra_service="rdp"
                    ;;
            esac

            if [[ "$port" == "3389" ]]; then
                hydra_service="rdp"
            fi

            if [[ -z "$hydra_service" ]]; then
                continue
            fi

            found_services=1

            local out_file="$hydra_dir/${ip}_${port}_${hydra_service}.txt"

            print_info "Running Hydra against $hydra_service on $ip:$port"

            timeout 420 hydra \
                -L "$DEFAULT_USERLIST" \
                -P "$PASSLIST" \
                -s "$port" \
                -t 4 \
                -W 5 \
                -f \
                -o "$out_file" \
                "$ip" \
                "$hydra_service" 2>&1 | tee -a "$LOG_FILE" || true

            if [[ -s "$out_file" ]]; then
                print_info "Hydra output saved to $out_file"
            else
                print_info "No weak credentials found for $ip:$port ($hydra_service)"
            fi
        done
    done < <(grep "Ports:" "$gnmap_file" || true)

    if [[ "$found_services" -eq 0 ]]; then
        print_info "No supported login services were found for weak credential testing."
    fi
}

run_nse_vulnerability_scan() {
    print_stage "Running Nmap NSE vulnerability scan"

    run_privileged_nmap -sV --script vuln --open -iL "$OUTPUT_DIR/live_hosts.txt" -oA "$OUTPUT_DIR/04_nse_vuln" | tee -a "$LOG_FILE"
}

run_searchsploit_analysis() {
    print_stage "Running Searchsploit vulnerability analysis"

    local tcp_xml="$OUTPUT_DIR/02_tcp_services.xml"
    local out_file="$OUTPUT_DIR/05_searchsploit.txt"

    if [[ -f "$tcp_xml" ]]; then
        searchsploit --nmap "$tcp_xml" | tee "$out_file" | tee -a "$LOG_FILE"
    else
        print_warn "Nmap XML file not found. Searchsploit analysis skipped."
    fi
}

create_summary() {
    print_stage "Creating final summary"

    local summary="$OUTPUT_DIR/summary.md"

    {
        echo "# VULNER Scan Summary"
        echo
        echo "## Project Information"
        echo "Author: $AUTHOR_NAME"
        echo "Project Code: $PROJECT_CODE"
        echo "Program Code: $PROGRAM_CODE"
        echo
        echo "## Scan Configuration"
        echo "Network: $NETWORK"
        echo "Mode: $MODE"
        echo "Password List: $PASSLIST"
        echo "Output Directory: $OUTPUT_DIR"
        echo "Run ID: $RUN_ID"
        echo
        echo "## Live Hosts"
        cat "$OUTPUT_DIR/live_hosts.txt"
        echo
        echo "## TCP Services"
        if [[ -f "$OUTPUT_DIR/02_tcp_services.gnmap" ]]; then
            grep "Ports:" "$OUTPUT_DIR/02_tcp_services.gnmap" || true
        else
            echo "No TCP service output found."
        fi
        echo
        echo "## UDP Services"
        if [[ -f "$OUTPUT_DIR/03_udp_services.gnmap" ]]; then
            grep "Ports:" "$OUTPUT_DIR/03_udp_services.gnmap" || true
        else
            echo "No UDP service output found."
        fi
        echo
        echo "## Weak Credential Results"
        if compgen -G "$OUTPUT_DIR/hydra_results/*.txt" > /dev/null; then
            grep -Rni "login:" "$OUTPUT_DIR/hydra_results" || echo "No valid weak credentials were identified."
        else
            echo "No Hydra result files were created."
        fi
        echo
        echo "## Full Mode Vulnerability Mapping"
        if [[ "$MODE" == "Full" ]]; then
            echo "NSE vulnerability scan and Searchsploit analysis were executed."
        else
            echo "Full vulnerability mapping was not executed because Basic mode was selected."
        fi
    } > "$summary"

    cat "$summary" | tee -a "$LOG_FILE"
}

search_inside_results() {
    print_stage "Interactive search inside results"

    read -rp "Do you want to search inside the results? [y/N]: " SEARCH_ANSWER

    if [[ ! "$SEARCH_ANSWER" =~ ^[Yy]$ ]]; then
        print_info "Search skipped by user."
        return
    fi

    read -rp "Enter search keyword, example ssh, ftp, vuln, login: " SEARCH_TERM

    if [[ -z "$SEARCH_TERM" ]]; then
        print_warn "Empty search term. Search skipped."
        return
    fi

    local safe_term
    safe_term="$(echo "$SEARCH_TERM" | tr -cd '[:alnum:]_.-')"

    local search_file="$OUTPUT_DIR/search_${safe_term}_${RUN_ID}.txt"

    grep -Rni -- "$SEARCH_TERM" "$OUTPUT_DIR" | tee "$search_file" | tee -a "$LOG_FILE" || true

    print_info "Search output saved to $search_file"
}

zip_results() {
    print_stage "Creating ZIP archive with all results"

    ZIP_FILE="$RESULTS_ROOT/$(basename "$OUTPUT_DIR").zip"

    cd "$OUTPUT_DIR" || die "Cannot enter output directory."
    zip -r "$ZIP_FILE" . >/dev/null
    cd "$BASE_DIR" || exit 1

    print_info "ZIP file created: $ZIP_FILE"
}

fix_permissions() {
    if [[ -n "${SUDO_USER:-}" && -d "$OUTPUT_DIR" ]]; then
        chown -R "$SUDO_USER:$SUDO_USER" "$OUTPUT_DIR" 2>/dev/null || true

        if [[ -n "$ZIP_FILE" && -f "$ZIP_FILE" ]]; then
            chown "$SUDO_USER:$SUDO_USER" "$ZIP_FILE" 2>/dev/null || true
        fi
    fi
}

main() {
    print_banner
    ensure_default_lists
    check_tools
    get_user_input
    run_host_discovery
    run_tcp_scan
    run_udp_scan
    run_weak_credentials

    if [[ "$MODE" == "Full" ]]; then
        run_nse_vulnerability_scan
        run_searchsploit_analysis
    else
        print_info "Basic mode selected. NSE and Searchsploit were skipped."
    fi

    create_summary
    search_inside_results
    zip_results
    fix_permissions

    echo
    echo "=========================================================="
    echo " Scan completed successfully"
    echo " Results directory: $OUTPUT_DIR"
    echo " ZIP archive: $ZIP_FILE"
    echo "=========================================================="
}

if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
    show_help
    exit 0
fi

main "$@"
