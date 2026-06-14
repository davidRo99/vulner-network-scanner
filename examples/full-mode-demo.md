# Full Mode Demo

Full mode includes all Basic mode actions and adds:

- Nmap NSE vulnerability scan
- Searchsploit analysis based on Nmap XML results

Example indicators of successful Full mode execution:

```text
[OK] NSE vulnerability scan output exists
[OK] Searchsploit analysis output exists
Full scan completed successfully.
```

The Searchsploit output helps map detected service versions to known public exploit references. Findings must always be manually validated before being reported as exploitable.
