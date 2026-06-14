# Usage Guide

## 1. Clone the Repository

```bash
git clone https://github.com/<your-username>/vulner-network-scanner.git
cd vulner-network-scanner
```

## 2. Install Dependencies

```bash
chmod +x scripts/install_kali_dependencies.sh
./scripts/install_kali_dependencies.sh
```

## 3. Run the Tool

```bash
chmod +x vulner.sh
./vulner.sh
```

## 4. Basic Mode Example

```text
Network: 192.168.47.0/24
Output directory: basic_scan
Mode: Basic
Custom password list: N
Search inside results: N
```

## 5. Full Mode Example

```text
Network: 192.168.47.0/24
Output directory: full_scan
Mode: Full
Custom password list: N
Search inside results: Y
Search keyword: ftp
```

## 6. Results

The tool creates a timestamped directory under `results/` and then creates a matching ZIP archive.

Example:

```text
results/full_scan_full_20260608_172436/
results/full_scan_full_20260608_172436.zip
```

## 7. Common Troubleshooting

### Missing tools

Run:

```bash
./scripts/install_kali_dependencies.sh
```

### UDP scan asks for sudo password

UDP scans require elevated privileges. Enter the local Kali password when requested.

### No live hosts found

Verify the network range:

```bash
ip -4 addr
ip route
```

Use the private CIDR range shown in the routing table.
