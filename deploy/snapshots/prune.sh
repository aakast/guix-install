#!/usr/bin/env bash
set -euo pipefail

KEEP="${1:-14}"

prune_dir() {
  local dir="$1"
  [[ -d "$dir" ]] || return 0

mapfile -t entries < <(find "$dir" -mindepth 1 -maxdepth 1 -type d | sort)
  local count="${#entries[@]}"

if (( count <= KEEP )); then
    return 0
  fi

local remove_count=$((count - KEEP))
for ((i=0; i<remove_count; i++)); do
    printf 'Deleting snapshot: %s\n' "${entries[$i]}"
    btrfs subvolume delete "${entries[$i]}"
  done
}

prune_dir "/.snapshots/root"
prune_dir "/.snapshots/home"
prune_dir "/.snapshots/gnu"
prune_dir "/.snapshots/git"
prune_dir "/.snapshots/data"
