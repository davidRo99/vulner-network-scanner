# Project Summary

VULNER is an automated penetration testing support script developed for a controlled training environment.

## Objective

Create a self-running tool that maps services and potential vulnerabilities on a local authorized network.

## Implemented Requirements

- User input for network range
- User input for output directory name
- Basic and Full scan modes
- Input validation
- TCP and UDP scanning
- Service version detection
- Weak credential testing
- Built-in password list generation
- Optional custom password list
- Login service checks for SSH, FTP, TELNET, and RDP
- Full mode vulnerability mapping with NSE and Searchsploit
- Terminal stage output
- Final summary generation
- Search inside generated results
- ZIP archive creation
- Function-based Bash structure
- Code comments and project header

## Lab Findings

A lab execution discovered:

- 4 live hosts
- FTP on port 21
- SSH on port 22
- HTTP on port 80
- Weak FTP credential in the lab environment

## Portfolio Value

This project demonstrates practical Bash automation, Linux tooling, network scanning methodology, evidence handling, and controlled vulnerability mapping.
