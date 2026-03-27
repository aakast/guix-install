#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
root="$(cd -- "${script_dir}/.." && pwd)"
profiles_root="${HOME}/.guix-extra-profiles"
map_file="${root}/profiles/host-feature-map.scm"
channels_file="${root}/channels.scm"

guix_bin="$(command -v guix)"

host="workstation"
dry_run=0
strict=0
max_retries="${GUIX_RETRY_MAX:-4}"
retry_base_delay="${GUIX_RETRY_BASE_DELAY:-4}"

usage() {
  cat <<EOF
Usage:
  ./install-host-profiles.sh [--dry-run] [--strict] [host]

Options:
  --dry-run  Print planned installs without running guix package
  --strict   Fail when a mapped manifest is missing
  -h, --help Show this help text

Environment:
  GUIX_RETRY_MAX         Number of retry attempts for transient failures (default: 4)
  GUIX_RETRY_BASE_DELAY  Base retry delay in seconds (default: 4)

Examples:
  ./install-host-profiles.sh
  ./install-host-profiles.sh workstation
  ./install-host-profiles.sh --dry-run workstation
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run)
      dry_run=1
      shift
      ;;
    --strict)
      strict=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    --*)
      echo "Error: unknown option: $1" >&2
      usage >&2
      exit 1
      ;;
    *)
      host="$1"
      shift
      ;;
  esac
done

if [[ ! -f "${map_file}" ]]; then
  echo "Error: host-feature-map.scm not found at ${map_file}" >&2
  exit 1
fi

if [[ ! -f "${channels_file}" ]]; then
  echo "Error: channels.scm not found at ${channels_file}" >&2
  exit 1
fi

mapfile -t features < <(
  guile -c '
    (define map-file (cadr (command-line)))
    (define host (caddr (command-line)))
    (load map-file)
    (let ((entry (assoc host %host-feature-map)))
      (when entry
        (for-each (lambda (f)
                    (display f)
                    (newline))
                  (cdr entry))))
  ' "${map_file}" "${host}"
)

if [[ ${#features[@]} -eq 0 ]]; then
  echo "Error: no features found for host '${host}' in ${map_file}" >&2
  echo "Available hosts:" >&2
  guile -c '
    (define map-file (cadr (command-line)))
    (load map-file)
    (for-each (lambda (entry)
                (display "  ")
                (display (car entry))
                (newline))
              %host-feature-map)
  ' "${map_file}" >&2
  exit 1
fi

echo "Host: ${host}"
echo "Features (${#features[@]}): ${features[*]}"
if (( dry_run )); then
  echo "Mode: dry-run"
fi
if (( strict )); then
  echo "Mode: strict"
fi
echo

installed=0
skipped=0

run_guix_package_with_retry() {
  local manifest="$1"
  local profile_path="$2"
  local attempt=1
  local status=0

  while (( attempt <= max_retries )); do
    if "${guix_bin}" time-machine -C "${channels_file}" -- \
      package -m "${manifest}" -p "${profile_path}"; then
      return 0
    fi

    status=$?
    if (( attempt == max_retries )); then
      echo "Error: guix command failed after ${attempt} attempts." >&2
      return "${status}"
    fi

    delay=$((retry_base_delay * attempt))
    echo "Warning: guix command failed (attempt ${attempt}/${max_retries}, exit ${status})." >&2
    echo "Retrying in ${delay}s..." >&2
    sleep "${delay}"
    attempt=$((attempt + 1))
  done

  return "${status}"
}

for feature in "${features[@]}"; do
  if [[ "${feature}" == host-* ]]; then
    hostname="${feature#host-}"
    manifest="${root}/manifests/hosts/${hostname}.scm"
  else
    manifest="${root}/manifests/features/${feature}.scm"
  fi

  if [[ ! -f "${manifest}" ]]; then
    if (( strict )); then
      echo "Error: manifest not found: ${manifest}" >&2
      exit 1
    else
      echo "Warning: manifest not found, skipping: ${manifest}" >&2
      skipped=$((skipped + 1))
      continue
    fi
  fi

  profile_dir="${profiles_root}/${feature}"
  profile_path="${profile_dir}/${feature}"
  if (( dry_run )); then
    echo "[dry-run] Would install profile: ${feature}"
    echo "          manifest: ${manifest}"
    echo "          profile : ${profile_path}"
    installed=$((installed + 1))
    continue
  fi

  mkdir -p "${profile_dir}"
  echo "Installing profile: ${feature}"
  run_guix_package_with_retry "${manifest}" "${profile_path}"
  installed=$((installed + 1))
done

cat <<EOF

Done. Host ${host}
  - Installed: ${installed}
  - Skipped:   ${skipped}
  - Mapped:    ${#features[@]}

Profiles are sourced automatically if your shell startup loops over
~/.guix-extra-profiles/*/.
EOF
