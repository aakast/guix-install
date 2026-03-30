#!/usr/bin/env bash
set -euo pipefail

# Install a rendered Guix system config to a mounted target.
#
# Prerequisites:
#   - Target filesystem tree mounted at $TARGET (default: /mnt)
#   - Config already rendered with real UUIDs (see render-config.sh)
#
# What this script does:
#   1. Enable copy-on-write store (so builds go to disk, not RAM)
#   2. Run guix system init
#   3. Copy this repository to the target so reconfigure works after boot
#
# Usage:
#   sudo ./scripts/install-system.sh system/hosts/workstation.scm [/mnt]

if [[ -z "${BASH_VERSION:-}" ]]; then
  printf 'Please run with bash, not sh. Example: bash %s\n' "$0" >&2
  exit 1
fi

if [[ "$(id -u)" -ne 0 ]]; then
  printf 'Run as root: sudo %s <config.scm> [target]\n' "$0" >&2
  exit 1
fi

CONFIG="${1:?Usage: $0 <config.scm> [target]}"
TARGET="${2:-/mnt}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

if [[ "$CONFIG" = /* ]]; then
  CONFIG_PATH="$CONFIG"
else
  CONFIG_PATH="$REPO_ROOT/$CONFIG"
fi

if [[ -t 1 ]]; then
  C_RESET='\033[0m'
  C_CYAN='\033[36m'
  C_GREEN='\033[32m'
else
  C_RESET=''
  C_CYAN=''
  C_GREEN=''
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

# --- Validation ---

if [[ ! -f "$CONFIG_PATH" ]]; then
  printf 'Config not found: %s\n' "$CONFIG_PATH" >&2
  exit 1
fi

if ! findmnt "$TARGET" >/dev/null 2>&1; then
  printf 'Target is not mounted: %s\n' "$TARGET" >&2
  printf 'Mount the target filesystem tree before running this script.\n' >&2
  exit 1
fi

printf 'Config:  %s\n' "$CONFIG_PATH"
printf 'Target:  %s\n' "$TARGET"
printf 'Repo:    %s\n\n' "$REPO_ROOT"

# --- Install ---

TOTAL=4

step "1" "$TOTAL" "Enabling copy-on-write store at $TARGET"
herd start cow-store "$TARGET"
done_step "cow-store active"

step "2" "$TOTAL" "Running guix system init"
guix system init --load-path="$REPO_ROOT" "$CONFIG_PATH" "$TARGET"
done_step "System installed to $TARGET"

step "3" "$TOTAL" "Copying repository to $TARGET/git/guix"
TARGET_REPO="$TARGET/git/guix"
if [[ -d "$TARGET_REPO" ]]; then
  rm -rf "$TARGET_REPO"
fi
mkdir -p "$(dirname "$TARGET_REPO")"
cp -a "$REPO_ROOT" "$TARGET_REPO"
done_step "Repository copied to $TARGET_REPO"

step "4" "$TOTAL" "Syncing disks"
sync
done_step "Sync complete"

printf '\nInstall complete.\n'
printf 'After rebooting into the new system:\n'
printf '  sudo /git/guix/scripts/post-install.sh          # set passwords\n'
printf '  just -f /git/guix/justfile home                 # uses hostname -s by default\n'
printf '\nTo reconfigure later:\n'
printf '  sudo guix system reconfigure --load-path=/git/guix /git/guix/system/hosts/<host>.scm\n'
