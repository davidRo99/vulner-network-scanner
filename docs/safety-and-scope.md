# Safety and Scope

This project is a defensive learning tool for authorized environments.

## Allowed Use

- Local lab networks
- Owned virtual machines
- Internal training environments
- Systems where written authorization exists

## Not Allowed

- Public targets without permission
- Third-party networks
- Internet-wide scanning
- Credential testing against systems you do not own or administer

## Why Scope Matters

Network scanning and weak credential testing can generate logs, trigger security systems, and affect services. The project restricts scans to private ranges as a basic safety control, but authorization is still required.

## Recommended Lab Setup

- Kali Linux attacker VM
- One or more intentionally vulnerable VMs
- NAT or host-only private network
- No public IP targets

## Evidence Handling

Do not publish real scan results from production networks. Sanitize IP addresses, hostnames, usernames, and credentials before sharing screenshots or reports.
