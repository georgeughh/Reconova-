#!/bin/bash

# Enable strict error handling
set -euo pipefail

# Colors for output
RED=$'\033[0;31m'
GREEN=$'\033[0;32m'
YELLOW=$'\033[1;33m'
BLUE=$'\033[0;34m'
CYAN=$'\033[0;36m'
NC=$'\033[0m'



echo -e "${CYAN}  ____                                                ${NC}"
echo -e "${CYAN} |  _ \\ ___  ___ ___  _ __   _____   ____ _         ${NC}"
echo -e "${CYAN} | |_) / _ \\/ __/ _ \\| '_ \\ / _ \\ \\ / / _\` |        ${NC}"
echo -e "${CYAN} |  _ <  __/ (_| (_) | | | | (_) \\ V / (_| |        ${NC}"
echo -e "${CYAN} |_| \\_\\___|\\___\\___/|_| |_|\\___/ \\_/ \\__,_|        ${NC}"
echo -e "${YELLOW}                                                         ${NC}"
echo -e "${GREEN}             # Coded By georgeughh - @GeorgeeSecc ${NC}"
echo ""





# Logging function
log() {
  local level=$1
  local message=$2
  case $level in
    "info") echo -e "${GREEN}[+] ${message}${NC}" ;;
    "warn") echo -e "${YELLOW}[!] ${message}${NC}" ;;
    "error") echo -e "${RED}[-] ${message}${NC}" ;;
    *) echo -e "${message}" ;;
  esac
}

# Check if the domain is provided
if [[ "${1:-}" != "-d" || -z "${2:-}" ]]; then
  log "error" "Usage: $0 -d <domain>"
  exit 1
fi

# Variables
DOMAIN=$2
OUTPUT_DIR="recon_$DOMAIN"
SUBDOMAINS_DIR="$OUTPUT_DIR/subdomains"
SUBZY_DIR="$OUTPUT_DIR/subdomain_takeover"
WHATWEB_DIR="$OUTPUT_DIR/web_technologies"
DIRSEARCH_DIR="$OUTPUT_DIR/endpoints"
ARJUN_DIR="$OUTPUT_DIR/parameters"

# Create output directories
mkdir -p "$OUTPUT_DIR" "$SUBDOMAINS_DIR" "$SUBZY_DIR" "$WHATWEB_DIR" "$DIRSEARCH_DIR" "$ARJUN_DIR"

# File paths
OUTPUT_FILE="$SUBDOMAINS_DIR/subdomains_$DOMAIN.txt"
UNIQUE_FILE="$SUBDOMAINS_DIR/unique_subdomains_$DOMAIN.txt"
SUBZY_OUTPUT="$SUBZY_DIR/subdomain_takeover_results_$DOMAIN.txt"
WHATWEB_OUTPUT="$WHATWEB_DIR/web_technologies_results_$DOMAIN.txt"
DIRSEARCH_OUTPUT="$DIRSEARCH_DIR/endpoints_results_$DOMAIN.txt"
ARJUN_OUTPUT="$ARJUN_DIR/parameters_results_$DOMAIN.json"
SUBDOMAINS_FILE="subdomains-enumirate.txt"

# Clear the output file if it exists
> "$OUTPUT_FILE"

# Check if required tools are installed
required_tools=("subfinder" "sublist3r" "gobuster" "httpx" "subzy" "whatweb" "dirsearch" "arjun" "amass")
for tool in "${required_tools[@]}"; do
  command -v "$tool" >/dev/null 2>&1 || { log "error" "$tool is required but it's not installed. Aborting."; exit 1; }
done

# Function to enumerate subdomains
enumerate_subdomains() {
  log "info" "Discovering subdomains..."
  subfinder -d "$DOMAIN" -silent > "$OUTPUT_FILE" 2>/dev/null

  sublist3r -d "$DOMAIN" -o "$SUBDOMAINS_DIR/sublist3r_results.txt" > /dev/null 2>&1
  grep -Eo "([a-zA-Z0-9._-]+\.$DOMAIN)" "$SUBDOMAINS_DIR/sublist3r_results.txt" >> "$OUTPUT_FILE" 2>/dev/null
  rm "$SUBDOMAINS_DIR/sublist3r_results.txt"

  gobuster dns -d "$DOMAIN" -w "$SUBDOMAINS_FILE" 2>/dev/null | grep "\.$DOMAIN" | awk '{print $2}' >> "$OUTPUT_FILE"

  amass enum -d "$DOMAIN" -o "$SUBDOMAINS_DIR/amass_results.txt" 2>/dev/null
  cat "$SUBDOMAINS_DIR/amass_results.txt" >> "$OUTPUT_FILE"
  rm "$SUBDOMAINS_DIR/amass_results.txt"

  log "info" "Removing duplicate subdomains..."
  cat "$OUTPUT_FILE" | anew "$UNIQUE_FILE" > /dev/null 2>&1
  rm "$OUTPUT_FILE"
}

# Function to check HTTP status codes
check_status_codes() {
  log "info" "Checking HTTP status codes for discovered subdomains..."
  httpx -l "$UNIQUE_FILE" -sc -silent | tee \
    >(grep "2[0-9][0-9]" > "$SUBDOMAINS_DIR/status_2xx_$DOMAIN.txt") \
    >(grep "3[0-9][0-9]" > "$SUBDOMAINS_DIR/status_3xx_$DOMAIN.txt") \
    >(grep "404" > "$SUBDOMAINS_DIR/status_404_$DOMAIN.txt") \
    >(grep "4[0-9][0-9]" | grep -v "404" > "$SUBDOMAINS_DIR/status_4xx_$DOMAIN.txt") > /dev/null 2>&1
}

# Function to check for subdomain takeovers
check_subdomain_takeovers() {
  log "info" "Checking for potential subdomain takeovers..."
  > "$SUBZY_OUTPUT"
  while read -r subdomain; do
    subzy -target "$subdomain" >> "$SUBZY_OUTPUT" 2>/dev/null
  done < "$UNIQUE_FILE"
}

# Function to check web technologies
check_web_technologies() {
  log "info" "Identifying web technologies used by subdomains..."
  > "$WHATWEB_OUTPUT"
  while read -r subdomain; do
    if host "$subdomain" &>/dev/null; then
      whatweb "$subdomain" >> "$WHATWEB_OUTPUT" 2>/dev/null || \
      echo "No web server found or request blocked." >> "$WHATWEB_OUTPUT"
    else
      echo "DNS resolution failed for $subdomain." >> "$WHATWEB_OUTPUT"
    fi
    echo "----------------------------------------" >> "$WHATWEB_OUTPUT"
  done < "$UNIQUE_FILE"
}

# Function to enumerate endpoints
enumerate_endpoints() {
  log "info" "Enumerating endpoints and directories..."
  dirsearch -L "$UNIQUE_FILE" -e "*" -t 50 -o "$DIRSEARCH_OUTPUT" > /dev/null 2>&1
}

# Function to enumerate parameters
enumerate_parameters() {
  log "info" "Enumerating URL parameters for discovered endpoints..."
  if [ -s "$DIRSEARCH_OUTPUT" ]; then
    grep -Eo 'http[s]?://[^ ]+' "$DIRSEARCH_OUTPUT" > "$ARJUN_DIR/urls_only.txt"
    if [ -s "$ARJUN_DIR/urls_only.txt" ]; then
      arjun -i "$ARJUN_DIR/urls_only.txt" -oJ "$ARJUN_OUTPUT"
    else
      log "warn" "No URLs found for parameter enumeration."
    fi
    rm "$ARJUN_DIR/urls_only.txt"
  else
    log "warn" "Dirsearch output is empty. Skipping parameter enumeration."
  fi
}

# Main execution
enumerate_subdomains
check_status_codes
check_subdomain_takeovers
check_web_technologies
enumerate_endpoints
enumerate_parameters

# Display results
log "info" "Done! Results saved in:"
log "info" "    - Subdomains: $SUBDOMAINS_DIR/"
log "info" "    - Subdomain Takeover Results: $SUBZY_OUTPUT"
log "info" "    - Web Technologies Results: $WHATWEB_OUTPUT"
log "info" "    - Endpoints Results: $DIRSEARCH_OUTPUT"
log "info" "    - URL Parameters Results: $ARJUN_OUTPUT"
