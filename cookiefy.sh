#!/bin/bash
# =============================================
# cookiefy - small cookie tool for web pentesting
# =============================================

set -euo pipefail

usage() {
    cat <<EOF
Usage: cookiefy [OPTIONS] [FILE]

Options:
  -e, --extract            Extract cookies (default)
  -a, --add "name=value"   Add/override a cookie (can be used multiple times)
  -d, --delete NAME        Delete a cookie (can be used multiple times)
  -o, --output FORMAT      Output format: header, curl, python, json, pretty (default: header)
  -p, --pretty             Pretty human-readable output
  -c, --clipboard          Copy to clipboard (default: true)
  -s, --silent             Only output the final result
  -j, --jwt                Try to decode JWT cookies
  --compare FILE2          Compare cookies with another request
  -h, --help               Show this help

Examples:
  cat burp.txt | cookiefy
  cookiefy -a "new=123" -d "old" request.txt
  cookiefy -o python request.txt
EOF
    exit 1
}

# defaults
MODE="extract"
OUTPUT="header"
CLIPBOARD=true
SILENT=false
PRETTY=false
JWT_DECODE=false
ADD_COOKIES=()
DELETE_COOKIES=()
COMPARE_FILE=""

while [[ $# -gt 0 ]]; do
    case $1 in
        -e|--extract) MODE="extract"; shift ;;
        -a|--add) ADD_COOKIES+=("$2"); shift 2 ;;
        -d|--delete) DELETE_COOKIES+=("$2"); shift 2 ;;
        -o|--output) OUTPUT="$2"; shift 2 ;;
        -p|--pretty) PRETTY=true; shift ;;
        -c|--clipboard) CLIPBOARD=true; shift ;;
        -s|--silent) SILENT=true; shift ;;
        -j|--jwt) JWT_DECODE=true; shift ;;
        --compare) COMPARE_FILE="$2"; shift 2 ;;
        -h|--help) usage ;;
        *) break ;;
    esac
done

# read input
if [[ -n "${1:-}" && -f "$1" ]]; then
    input=$(cat "$1")
else
    input=$(cat)
fi

# extract Cookie or Set-Cookie lines
cookies_raw=$(echo "$input" | grep -iE '^(Cookie:|Set-Cookie:)' | sed -E 's/^(Cookie|Set-Cookie):\s*//i' | tr '\n' ';' | sed 's/;$//')

if [ -z "$cookies_raw" ]; then
    echo "No Cookie or Set-Cookie header found." >&2
    exit 1
fi

# convert to associative array for easy manipulation
declare -A cookies
while IFS='=' read -r key value; do
    key=$(echo "$key" | xargs)
    value=$(echo "$value" | sed 's/^\s*//;s/\s*$//' | cut -d';' -f1)
    [[ -n "$key" ]] && cookies["$key"]="$value"
done < <(echo "$cookies_raw" | tr ';' '\n' | sed 's/^\s*//;s/\s*$//')

# apply modifications
for add in "${ADD_COOKIES[@]}"; do
    IFS='=' read -r key value <<< "$add"
    cookies["$key"]="${value:-}"
done

for del in "${DELETE_COOKIES[@]}"; do
    unset "cookies[$del]"
done

# build final cookie string
final_cookies=""
for key in "${!cookies[@]}"; do
    final_cookies+="$key=${cookies[$key]};"
done
final_cookies=${final_cookies%;}

# output logic
case $OUTPUT in
    header)
        result="Cookie: $final_cookies"
        ;;
    curl)
        result="-b \"$final_cookies\""
        ;;
    python)
        result="cookies = {"
        for key in "${!cookies[@]}"; do
            result+="\n    \"$key\": \"${cookies[$key]}\","
        done
        result="${result%,}\n}"
        ;;
    json)
        result="{"
        for key in "${!cookies[@]}"; do
            result+="\n  \"$key\": \"${cookies[$key]}\","
        done
        result="${result%,}\n}"
        ;;
    pretty)
        echo "=== Cookies ===" >&2
        for key in $(echo "${!cookies[@]}" | tr ' ' '\n' | sort); do
            printf "%-20s = %s\n" "$key" "${cookies[$key]}" >&2
        done
        result="$final_cookies"
        ;;
    *)
        result="$final_cookies"
        ;;
esac

if [[ "$PRETTY" == false && "$OUTPUT" != "pretty" ]]; then
    echo "$result"
fi

# copy to clipboard
if [[ "$CLIPBOARD" == true && "$SILENT" == false ]]; then
    if command -v xclip >/dev/null 2>&1; then
        echo -n "$final_cookies" | xclip -selection clipboard
    elif command -v pbcopy >/dev/null 2>&1; then
        echo -n "$final_cookies" | pbcopy
    elif command -v wl-copy >/dev/null 2>&1; then
        echo -n "$final_cookies" | wl-copy
    fi
    [[ "$SILENT" == false ]] && echo "✅ Copied to clipboard" >&2
fi
