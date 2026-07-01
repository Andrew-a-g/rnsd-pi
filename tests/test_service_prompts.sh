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

LXMF_NODE_NAME=$(default_if_yes_no "y" "TEST-LXMF-PropServer")
if [ "$LXMF_NODE_NAME" != "TEST-LXMF-PropServer" ]; then
  echo "Expected yes/no-looking LXMF node name to use default" >&2
  exit 1
fi

DISTGROUP_NAME=$(default_if_yes_no "no" "TEST-Group")
if [ "$DISTGROUP_NAME" != "TEST-Group" ]; then
  echo "Expected yes/no-looking group name to use default" >&2
  exit 1
fi

CUSTOM_NAME=$(default_if_yes_no "Roof-Node" "TEST-LXMF-PropServer")
if [ "$CUSTOM_NAME" != "Roof-Node" ]; then
  echo "Expected custom node name to be preserved" >&2
  exit 1
fi

if ! grep -q 'lxmd --service --propagation-node' "$REPO_ROOT/rnsd-pi-setup.sh"; then
  echo "lxmd systemd service must start propagation mode explicitly" >&2
  exit 1
fi

if ! grep -q 'systemctl reenable "$svc"' "$REPO_ROOT/rnsd-pi-setup.sh"; then
  echo "service helper must reenable units so changed WantedBy links are refreshed" >&2
  exit 1
fi

if ! grep -q 'WantedBy=multi-user.target rnsd.service' "$REPO_ROOT/rnsd-pi-setup.sh"; then
  echo "lxmd/nomadnet units should also be wanted by rnsd.service for boot ordering" >&2
  exit 1
fi

if ! grep -q 'WantedBy=multi-user.target lxmd.service' "$REPO_ROOT/rnsd-pi-setup.sh"; then
  echo "distribution group unit should also be wanted by lxmd.service for boot ordering" >&2
  exit 1
fi

if ! grep -q 'rnsd.service.d/optional-services.conf' "$REPO_ROOT/rnsd-pi-setup.sh"; then
  echo "installer should add an rnsd drop-in to start selected optional services after rnsd starts" >&2
  exit 1
fi

if ! grep -q 'ExecStartPost=/bin/sh -c' "$REPO_ROOT/rnsd-pi-setup.sh"; then
  echo "rnsd drop-in should use ExecStartPost to kick optional services at boot" >&2
  exit 1
fi

echo "service prompt tests passed"
