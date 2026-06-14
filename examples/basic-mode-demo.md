# Basic Mode Demo

Example Basic mode input:

```text
Network: 192.168.47.0/24
Output directory: basic_scan
Mode: Basic
Custom password list: N
```

Example summarized output:

```text
Live Hosts Found:
1  192.168.47.1
2  192.168.47.136
3  192.168.47.2
4  192.168.47.254

Detected TCP Services:
192.168.47.136:21/tcp  ftp   vsftpd 3.0.5
192.168.47.136:22/tcp  ssh   OpenSSH 10.2p1 Debian 3
192.168.47.136:80/tcp  http  Apache httpd 2.4.66

Weak Credential Finding:
Host: 192.168.47.136 | Service: FTP | Username: ftp | Password: admin
```

This is controlled lab output only.
