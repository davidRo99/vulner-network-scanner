#!/usr/bin/env bash

set -euo pipefail

echo "[+] Updating package index"
sudo apt update

echo "[+] Installing required packages"
sudo apt install -y nmap hydra exploitdb zip python3

echo "[+] Verifying tools"
for tool in nmap hydra searchsploit zip python3; do
    if command -v "$tool" >/dev/null 2>&1; then
        echo "[OK] $tool found: $(command -v "$tool")"
    else
        echo "[MISSING] $tool"
        exit 1
    fi
done

echo "[OK] Dependencies installed successfully"
