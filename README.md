# cookiefy

**A cookie extractor and manipulator for web pentesting.**

Turn any Burp request/response into clean cookies instantly, with clipboard support and multiple output formats. Intended to improve the (or at least my) experience of working with Burp Suite w/ other tools (ffuf, gobuster, etc) when exporting Burp's requests.

---

### Features

- Extract cookies from Burp Suite raw requests/responses
- Add, override, or delete cookies on the fly
- Multiple output formats:
  - `Cookie:` header (default)
  - `curl -b` syntax
  - Python `requests` cookies
  - JSON
  - Pretty human-readable
- Automatic clipboard copy (Linux + macOS)
- Lightweight and dependency-free

### Installation

```bash
git clone https://github.com/EdgarHuemac/cookiefy.git
cd cookiefy
chmod +x cookiefy
sudo cp cookiefy /usr/local/bin/
```

### Usage
```
# basic usage
cat burp_request.txt | cookiefy

# with options
cookiefy -a "newtoken=xyz123" -d "old_session" request.txt

# different output formats
cookiefy -o python request.txt
cookiefy -o curl request.txt
cookiefy -o json request.txt

# pretty output
cookiefy -p request.txt
```

### Common Examples

```
# pipe directly from clipboard (Burp)
xclip -o | cookiefy

# add a cookie and get Python format
cookiefy -a "admin=true" -o python burp.txt

# delete a cookie
cookiefy -d "PHPSESSID" request.txt
```

### Options

"-a, --add",Add/override cookie (name=value)
"-d, --delete",Delete a cookie by name
"-o, --output","Output format (header, curl, python, json)"
"-p, --pretty",Human-readable output
"-s, --silent",Suppress messages
--compare FILE,Compare cookies with another request


### Why cookiefy

Because manually cleaning Burp cookies is annoying.
This tool makes copying, modifying, and reusing cookies frictionless.
Made for web pentesters and bug bounty hunters.
