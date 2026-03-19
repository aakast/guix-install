#!/usr/bin/env bash
set -euo pipefail

SNAPROOT="/.snapshots"
STAMP="$(date +%F_%H%M%S)"

mkdir -p "$SNAPROOT/root"
mkdir -p "$SNAPROOT/home"
mkdir -p "$SNAPROOT/gnu"
mkdir -p "$SNAPROOT/git"
mkdir -p "$SNAPROOT/data"

snapshot_ro() {
  local src="$1"
  local dst="$2"
  btrfs subvolume snapshot -r "$src" "$dst"
}

snapshot_ro /     "$SNAPROOT/root/$STAMP"
snapshot_ro /home "$SNAPROOT/home/$STAMP"
snapshot_ro /gnu  "$SNAPROOT/gnu/$STAMP"
snapshot_ro /git  "$SNAPROOT/git/$STAMP"
snapshot_ro /data "$SNAPROOT/data/$STAMP"

printf 'Created read-only snapshots at %s\n' "$STAMP"
