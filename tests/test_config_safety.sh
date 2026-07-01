#!/bin/bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd "$SCRIPT_DIR/.." && pwd)
TMP_HOME=$(mktemp -d)
trap 'rm -rf "$TMP_HOME"' EXIT

export HOME="$TMP_HOME"
export RNSD_PI_SKIP_MAIN=1
# shellcheck source=../rnsd-pi-setup.sh
source "$REPO_ROOT/rnsd-pi-setup.sh"

assert_file_contains() {
  local file="$1" expected="$2"
  if ! grep -q "$expected" "$file"; then
    echo "Expected $file to contain: $expected" >&2
    exit 1
  fi
}

# Existing config should be left untouched when overwrite is declined.
mkdir -p "$HOME/.reticulum"
printf 'original-config\n' > "$HOME/.reticulum/config"
yn_prompt() { return 1; }
if prepare_config_write "$HOME/.reticulum/config" "Reticulum"; then
  echo "prepare_config_write should have skipped when overwrite was declined" >&2
  exit 1
fi
assert_file_contains "$HOME/.reticulum/config" "original-config"

# Existing config should be backed up when overwrite and backup are accepted.
answers=(y y)
yn_prompt() {
  local answer="${answers[0]}"
  answers=("${answers[@]:1}")
  [ "$answer" = "y" ]
}
if ! prepare_config_write "$HOME/.reticulum/config" "Reticulum"; then
  echo "prepare_config_write should allow overwrite when accepted" >&2
  exit 1
fi
backup_count=$(find "$HOME/.rnsd-pi/backups" -type f | wc -l)
if [ "$backup_count" -ne 1 ]; then
  echo "Expected exactly one backup, found $backup_count" >&2
  exit 1
fi
backup_file=$(find "$HOME/.rnsd-pi/backups" -type f | head -n 1)
assert_file_contains "$backup_file" "original-config"

echo "config safety tests passed"
