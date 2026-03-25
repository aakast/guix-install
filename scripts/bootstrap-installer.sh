#!/usr/bin/env bash
set -euo pipefail

if [[ -z "${BASH_VERSION:-}" ]]; then
  printf 'Please run with bash, not sh. Example: bash %s\n' "$0" >&2
  exit 1
fi

if [[ -t 1 ]]; then
  C_RESET='\033[0m'
  C_CYAN='\033[36m'
  C_GREEN='\033[32m'
  C_YELLOW='\033[33m'
else
  C_RESET=''
  C_CYAN=''
  C_GREEN=''
  C_YELLOW=''
fi

step() {
  local idx="$1"
  local total="$2"
  local msg="$3"
  printf '\n%s[%s/%s]%s %s\n' "$C_CYAN" "$idx" "$total" "$C_RESET" "$msg"
}

done_step() {
  printf '%s[ok]%s %s\n' "$C_GREEN" "$C_RESET" "$1"
}

step "1" "2" "Pulling latest Guix in current shell"
guix pull
hash guix
done_step "Guix pull complete"

step "2" "2" "Installing installer tools (git)"
guix install git
done_step "Installer tools installed"

printf '\nBootstrap complete\n'
printf 'Next steps:\n'
printf '  git clone <repo-url> guix\n'
printf '  cd guix\n'
printf '  sudo ./scripts/full-install.sh /dev/<disk> /path/to/backup-dir\n\n'
