#!/bin/bash

# =============================================================================
# rnsd-pi-setup.sh
# Reticulum Network Stack Setup Wizard for Raspberry Pi / Linus Debian-based distros.
# Author: ag/Andrew  |  v2.0
# Compatible with Raspberry Pi or linux machines running Debian-based distros.
# =============================================================================

# ── Colour palette (DOS-style blue wizard) ───────────────────────────────────
BLUE='\033[1;34m'
CYAN='\033[1;36m'
WHITE='\033[1;37m'
YELLOW='\033[1;33m'
GREEN='\033[1;32m'
RED='\033[1;31m'
DIM='\033[2m'
RESET='\033[0m'

# ── Terminal width (capped at 100) ────────────────────────────────────────────
TW=$(tput cols 2>/dev/null || echo 76)
[ "$TW" -gt 100 ] && TW=100

# ── Box-drawing helpers ───────────────────────────────────────────────────────
_rep() {
  local s="$1" n="$2" out=""
  for ((i=0;i<n;i++)); do out+="$s"; done
  printf '%s' "$out"
}

box_top()   { printf "${BLUE}╔$(_rep '═' $((TW-2)))╗${RESET}\n"; }
box_mid()   { printf "${BLUE}╠$(_rep '═' $((TW-2)))╣${RESET}\n"; }
box_bot()   { printf "${BLUE}╚$(_rep '═' $((TW-2)))╝${RESET}\n"; }
box_blank() { printf "${BLUE}║${RESET}$(_rep ' ' $((TW-2)))${BLUE}║${RESET}\n"; }

# Centred line inside box
box_line() {
  local text="$1" colour="${2:-$WHITE}"
  local inner=$((TW-2))
  local tlen=${#text}
  local lpad=$(( (inner - tlen) / 2 ))
  local rpad=$(( inner - tlen - lpad ))
  printf "${BLUE}║${RESET}$(_rep ' ' $lpad)${colour}${text}${RESET}$(_rep ' ' $rpad)${BLUE}║${RESET}\n"
}

# Left-aligned line inside box
box_left() {
  local text="$1" colour="${2:-$WHITE}" indent="${3:-2}"
  local inner=$((TW-2))
  local tlen=${#text}
  local rpad=$(( inner - indent - tlen ))
  [ $rpad -lt 0 ] && rpad=0
  printf "${BLUE}║${RESET}$(_rep ' ' $indent)${colour}${text}${RESET}$(_rep ' ' $rpad)${BLUE}║${RESET}\n"
}

# ── Prompt/output helpers ─────────────────────────────────────────────────────
section_header() {
  echo; box_mid; box_line "  $1" "$YELLOW"; box_mid
}

step_banner() {
  local step="$1" title="$2"
  local label="  Step ${step}: ${title}"
  local inner=$((TW-2))
  local rpad=$(( inner - ${#label} ))
  [ $rpad -lt 0 ] && rpad=0
  echo
  printf "${BLUE}┌$(_rep '─' $((TW-2)))┐${RESET}\n"
  printf "${BLUE}│${RESET}  ${YELLOW}Step ${step}:${WHITE} ${title}${RESET}$(_rep ' ' $rpad)${BLUE}│${RESET}\n"
  printf "${BLUE}└$(_rep '─' $((TW-2)))┘${RESET}\n"
}

info()  { printf "  ${CYAN}ℹ${RESET}  %s\n" "$*"; }
ok()    { printf "  ${GREEN}✔${RESET}  %s\n" "$*"; }
warn()  { printf "  ${YELLOW}⚠${RESET}  %s\n" "$*"; }
err()   { printf "  ${RED}✘${RESET}  %s\n" "$*"; }
ask()   { printf "  ${YELLOW}?${RESET}  ${WHITE}%s${RESET} " "$*"; }

press_enter() {
  printf "\n  ${DIM}Press [Enter] to continue, or type 'q' to quit...${RESET} "
  read -r _pe
  [[ "$_pe" =~ ^[Qq] ]] && { echo; err "Setup aborted by user."; exit 0; }
}

yn_prompt() {
  # yn_prompt "Question" [default=y]
  local q="$1" def="${2:-y}"
  local yn_hint="[Y/n]"; [ "$def" = "n" ] && yn_hint="[y/N]"
  while true; do
    printf "  ${YELLOW}?${RESET}  ${WHITE}%s ${DIM}%s${RESET} " "$q" "$yn_hint"
    read -r _ans
    _ans="${_ans:-$def}"
    case "$_ans" in
      [Yy]*) return 0 ;;
      [Nn]*) return 1 ;;
      *) warn "Please answer y or n." ;;
    esac
  done
}

yn_to_str() { [ "$1" = "y" ] && echo "Yes" || echo "No"; }

# =============================================================================
# SPLASH SCREEN
# =============================================================================
show_splash() {
  clear
  box_top
  box_blank

  # RNS logo – each line centred inside box
  _logo_line() {
    local t="$1"
    local inner=$((TW-2))
    local lp=$(( (inner - ${#t}) / 2 ))
    local rp=$(( inner - ${#t} - lp ))
    [ $lp -lt 0 ] && lp=0; [ $rp -lt 0 ] && rp=0
    printf "${BLUE}║${RESET}$(_rep ' ' $lp)${CYAN}${t}${RESET}$(_rep ' ' $rp)${BLUE}║${RESET}\n"
  }

  _logo_line "██████╗ ███╗   ██╗███████╗    ██████╗ ██╗"
  _logo_line "██╔══██╗████╗  ██║██╔════╝    ██╔══██╗██║"
  _logo_line "██████╔╝██╔██╗ ██║███████╗    ██████╔╝██║"
  _logo_line "██╔══██╗██║╚██╗██║╚════██║    ██╔═══╝ ██║"
  _logo_line "██║  ██║██║ ╚████║███████║    ██║     ██║"
  _logo_line "╚═╝  ╚═╝╚═╝  ╚═══╝╚══════╝    ╚═╝     ╚═╝"

  box_blank
  box_mid
  box_line "R E T I C U L U M   N E T W O R K   S T A C K" "$CYAN"
  box_line "Raspberry Pi or Linux LoRa Gateway  ·  Setup Wizard v2.0" "$WHITE"
  box_mid
  box_blank
  box_line "Guides you through installing & configuring your Pi" "$WHITE"
  box_line "as an off-grid LoRa gateway for Reticulum mesh comms." "$DIM"
  box_blank
  box_line "Designed for small off grid reticulum meshes." "$DIM"
  box_blank
  box_line "Features: Transport node (meshing)" "$DIM"
  box_line "LoRa (with rnode)" "$DIM"
  box_line "Propagation Server (optional)" "$DIM"
  box_line "NomadNet Hosting (optional)" "$DIM"
  box_line "Group Message Host (optional)" "$DIM"
  box_bot
  echo
  warn "Before continuing, ensure you have run:"
  info "  sudo apt update && sudo apt upgrade -y"
  echo
  press_enter
}

# =============================================================================
# STEP 1 – Environment name
# =============================================================================
get_env_name() {
  step_banner 1 "Name Your Environment"
  echo
  info "Give your Reticulum setup a short identifier (no spaces)."
  info "Example: Andrew uses 'AG', giving nodes names like AG-PropServer."
  echo
  while true; do
    ask "Environment name (e.g. AG, HOME, MESH1):"
    read -r ENV_NAME
    ENV_NAME=$(echo "$ENV_NAME" | tr -d '[:space:]')
    if [ -n "$ENV_NAME" ]; then
      ok "Environment set to: ${YELLOW}${ENV_NAME}${RESET}"
      break
    else
      warn "Name cannot be empty."
    fi
  done
}

# =============================================================================
# STEP 2 – RNode port / TCP address
# =============================================================================
get_rnode_port() {
  step_banner 2 "RNode Interface / Port"
  echo
  info "Detected serial devices:"
  ls /dev/ttyUSB* /dev/ttyACM* 2>/dev/null \
    | while read -r d; do printf "      ${GREEN}%s${RESET}\n" "$d"; done
  echo

  box_top
  box_line "TIP  –  TCP RNode (Recommended for power saving)" "$YELLOW"
  box_mid
  box_left "If your RNode is on the same WiFi network as the Pi, you can" "$WHITE"
  box_left "connect over TCP.  This lets a more powerful PC run the RNode" "$WHITE"
  box_left "and saves power on the Pi." "$WHITE"
  box_blank
  box_left "TCP format:   tcp://192.168.1.115" "$CYAN"
  box_blank
  box_left "To put the RNode on WiFi, run this on the host PC first:" "$WHITE"
  box_blank
  box_left "  rnodeconf /dev/ttyACM0 -w STATION \\" "$YELLOW"
  box_left "      --ssid your_wifi_ssid --psk your_wifi_password" "$YELLOW"
  box_blank
  box_left "Tip: check your router DHCP table before & after to find the IP." "$DIM"
  box_bot
  echo

  local DEFAULT_PORT="/dev/ttyUSB0"
  ask "RNode port or TCP address (default: ${DEFAULT_PORT}):"
  read -r RNODE_PORT
  RNODE_PORT=${RNODE_PORT:-$DEFAULT_PORT}
  ok "RNode interface: ${YELLOW}${RNODE_PORT}${RESET}"
}

# =============================================================================
# STEP 3 – LoRa settings
# =============================================================================
get_lora_settings() {
  step_banner 3 "LoRa Radio Settings"
  echo

  # Built-in UK defaults
  FREQUENCY="869431000"
  BANDWIDTH="125000"
  SPREADING_FACTOR="8"
  CODING_RATE="5"

  # Try to download frequency presets YAML from GitHub
  local PRESETS_URL="https://raw.githubusercontent.com/Andrew-a-g/rnsd-pi/main/frequency_presets.yaml"
  local PRESETS_FILE="/tmp/rns_freq_presets.yaml"

  info "Fetching frequency presets from GitHub..."
  if wget -qO "$PRESETS_FILE" "$PRESETS_URL" 2>/dev/null && [ -s "$PRESETS_FILE" ]; then
    ok "Presets downloaded."
    echo

    # Parse simple YAML arrays
    mapfile -t PRESET_NAMES < <(grep '^\s*name:' "$PRESETS_FILE" | sed 's/.*name:[[:space:]]*//')
    mapfile -t PRESET_FREQS < <(grep '^\s*frequency:' "$PRESETS_FILE" | sed 's/.*frequency:[[:space:]]*//')
    mapfile -t PRESET_BWS   < <(grep '^\s*bandwidth:' "$PRESETS_FILE" | sed 's/.*bandwidth:[[:space:]]*//')
    mapfile -t PRESET_SFS   < <(grep '^\s*spreading_factor:' "$PRESETS_FILE" | sed 's/.*spreading_factor:[[:space:]]*//')
    mapfile -t PRESET_CRS   < <(grep '^\s*coding_rate:' "$PRESETS_FILE" | sed 's/.*coding_rate:[[:space:]]*//')

    if [ ${#PRESET_NAMES[@]} -gt 0 ]; then
      info "Available frequency presets:"
      for i in "${!PRESET_NAMES[@]}"; do
        printf "    ${YELLOW}[%d]${RESET} %s\n" "$((i+1))" "${PRESET_NAMES[$i]}"
      done
      local manual_idx=$(( ${#PRESET_NAMES[@]} + 1 ))
      printf "    ${YELLOW}[%d]${RESET} Enter manually\n" "$manual_idx"
      echo
      ask "Select preset [1-${manual_idx}] (default: 1):"
      read -r SEL
      SEL=${SEL:-1}

      if [[ "$SEL" =~ ^[0-9]+$ ]] && [ "$SEL" -ge 1 ] && [ "$SEL" -le "${#PRESET_NAMES[@]}" ]; then
        local pi=$((SEL-1))
        FREQUENCY="${PRESET_FREQS[$pi]}"
        BANDWIDTH="${PRESET_BWS[$pi]}"
        SPREADING_FACTOR="${PRESET_SFS[$pi]}"
        CODING_RATE="${PRESET_CRS[$pi]}"
        ok "Preset: ${YELLOW}${PRESET_NAMES[$pi]}${RESET}"
      else
        info "Manual entry selected – using UK defaults as starting point."
      fi
    fi
  else
    warn "Could not download presets.  Using built-in UK 868 MHz defaults."
  fi

  echo
  info "Current settings (press Enter to keep each value):"
  ask "  Frequency Hz      (current: ${FREQUENCY}):"
  read -r _v; [ -n "$_v" ] && FREQUENCY="$_v"
  ask "  Bandwidth Hz      (current: ${BANDWIDTH}):"
  read -r _v; [ -n "$_v" ] && BANDWIDTH="$_v"
  ask "  Spreading Factor  (current: ${SPREADING_FACTOR}):"
  read -r _v; [ -n "$_v" ] && SPREADING_FACTOR="$_v"
  ask "  Coding Rate       (current: ${CODING_RATE}):"
  read -r _v; [ -n "$_v" ] && CODING_RATE="$_v"

  echo
  info "RNode interface mode:"
  printf "    ${YELLOW}[1]${RESET} full  – Transport node (recommended, forwards packets)\n"
  printf "    ${YELLOW}[2]${RESET} ap    – Access point (for busy meshes with many nodes)\n"
  ask "Select mode [1/2] (default: 1 – full):"
  read -r MODE_SEL
  case "$MODE_SEL" in
    2) RNODE_MODE="ap" ;;
    *) RNODE_MODE="full" ;;
  esac
  ok "Mode: ${YELLOW}${RNODE_MODE}${RESET}"
}

# =============================================================================
# STEP 4 – Optional components
# =============================================================================
select_optional_components() {
  step_banner 4 "Optional Components"

  # ── LXMF PropServer ────────────────────────────────────────────────────────
  echo
  box_top
  box_line "LXMF Propagation Server" "$YELLOW"
  box_mid
  box_left "Stores and forwards messages so offline devices can collect" "$WHITE"
  box_left "them later.  Ideal for any permanent Pi gateway node." "$WHITE"
  box_bot
  echo

  if yn_prompt "Install and configure LXMF propagation server?"; then
    INSTALL_LXMF="y"
    local def_lxmf="${ENV_NAME}-LXMF-PropServer"
    ask "Propagation node name (default: ${def_lxmf}):"
    read -r LXMF_NODE_NAME
    LXMF_NODE_NAME=${LXMF_NODE_NAME:-$def_lxmf}
    ok "LXMF PropServer name: ${YELLOW}${LXMF_NODE_NAME}${RESET}"
  else
    INSTALL_LXMF="n"
    LXMF_NODE_NAME=""
  fi

  # ── NomadNet ───────────────────────────────────────────────────────────────
  echo
  box_top
  box_line "NomadNet – Reticulum Page Host" "$YELLOW"
  box_mid
  box_left "Lets your Pi host micron pages readable by any Reticulum client." "$WHITE"
  box_left "A default welcome page will be created for you." "$WHITE"
  box_bot
  echo

  if yn_prompt "Install NomadNet to host pages?"; then
    INSTALL_NOMADNET="y"
    NOMADNET_NAME="${ENV_NAME}-NomadNet"
    ok "NomadNet node name: ${YELLOW}${NOMADNET_NAME}${RESET}"
  else
    INSTALL_NOMADNET="n"
    NOMADNET_NAME=""
  fi

  # ── LXMF Distribution Group ────────────────────────────────────────────────
  echo
  box_top
  box_line "LXMF Distribution Group  –  Advanced Users Only" "$YELLOW"
  box_mid
  box_left "Distribution groups are NOT broadcast messages; they must be" "$WHITE"
  box_left "hosted on a Reticulum node.  Messages are retained on your" "$WHITE"
  box_left "propagation server.  Only proceed if you understand this." "$WHITE"
  box_blank
  box_left "Docs: github.com/SebastianObi/LXMF-Tools" "$CYAN"
  box_left "      lxmf_distribution_group_extended" "$CYAN"
  box_bot
  echo

  if yn_prompt "Install LXMF distribution group? (advanced)" "n"; then
    INSTALL_DISTGROUP="y"
    local def_grp="${ENV_NAME}-Group"
    ask "Distribution group name (default: ${def_grp}):"
    read -r DISTGROUP_NAME
    DISTGROUP_NAME=${DISTGROUP_NAME:-$def_grp}
    ok "Group name: ${YELLOW}${DISTGROUP_NAME}${RESET}"
  else
    INSTALL_DISTGROUP="n"
    DISTGROUP_NAME=""
  fi
}

# =============================================================================
# STEP 5 – Summary & confirm
# =============================================================================
show_summary() {
  step_banner 5 "Configuration Summary"
  echo
  box_top
  box_line "${ENV_NAME} Node Configuration" "$CYAN"
  box_mid
  box_blank
  box_left "Environment      : ${ENV_NAME}" "$WHITE"
  box_left "RNode port       : ${RNODE_PORT}" "$WHITE"
  box_left "Frequency (Hz)   : ${FREQUENCY}" "$WHITE"
  box_left "Bandwidth (Hz)   : ${BANDWIDTH}" "$WHITE"
  box_left "Spreading factor : ${SPREADING_FACTOR}" "$WHITE"
  box_left "Coding rate      : ${CODING_RATE}" "$WHITE"
  box_left "RNode mode       : ${RNODE_MODE}" "$WHITE"
  box_blank
  box_mid
  box_line "Optional Components" "$YELLOW"
  box_mid
  box_blank
  box_left "LXMF PropServer  : $(yn_to_str "$INSTALL_LXMF")" "$WHITE"
  [ "$INSTALL_LXMF" = "y" ]      && box_left "  └ Name         : ${LXMF_NODE_NAME}" "$DIM"
  box_left "NomadNet         : $(yn_to_str "$INSTALL_NOMADNET")" "$WHITE"
  [ "$INSTALL_NOMADNET" = "y" ]  && box_left "  └ Name         : ${NOMADNET_NAME}" "$DIM"
  box_left "Dist. Group      : $(yn_to_str "$INSTALL_DISTGROUP")" "$WHITE"
  [ "$INSTALL_DISTGROUP" = "y" ] && box_left "  └ Name         : ${DISTGROUP_NAME}" "$DIM"
  box_blank
  box_bot
  echo
  yn_prompt "Proceed with installation?" || { info "Aborted."; exit 0; }
}

# ── Service helper: verify file written, enable, and start ───────────────────
_verify_and_start_service() {
  local svc="$1"
  local svc_file="/etc/systemd/system/${svc}.service"

  # Verify the file was actually written and has content
  if [ ! -s "$svc_file" ]; then
    err "Service file ${svc_file} is missing or empty — something went wrong writing it."
    return 1
  fi
  ok "Service file written: ${svc_file} ($(wc -c < "$svc_file") bytes)"

  sudo systemctl daemon-reload
  sudo systemctl enable "$svc"
  ok "${svc} enabled (will start on boot)."

  # Attempt to start now so the user sees immediately if it works
  info "Starting ${svc} now..."
  if sudo systemctl start "$svc" 2>/dev/null; then
    sleep 2
    if sudo systemctl is-active --quiet "$svc"; then
      ok "${svc} is running."
    else
      warn "${svc} started but is not active yet — check: sudo systemctl status ${svc}"
    fi
  else
    warn "Could not start ${svc} immediately — it may need a reboot, or check:"
    warn "  sudo systemctl status ${svc}"
    warn "  sudo journalctl -u ${svc} -n 30"
  fi
}

# =============================================================================

VENV_BASE="/opt/reticulum-venv"
VENV_PIP=""
VENV_PYTHON=""

install_system_deps() {
  info "Installing system dependencies..."
  sudo apt install -y \
    python3 python3-pip python3-venv \
    python3-cryptography python3-serial \
    wget curl git
  ok "System dependencies installed."
}

create_venv() {
  if [ ! -d "$VENV_BASE" ]; then
    info "Creating Python venv at ${VENV_BASE}..."
    sudo python3 -m venv "$VENV_BASE"
    sudo chown -R "$(whoami):$(whoami)" "$VENV_BASE"
    ok "Virtual environment created."
  else
    ok "Virtual environment already present at ${VENV_BASE}."
  fi
  VENV_PIP="$VENV_BASE/bin/pip"
  VENV_PYTHON="$VENV_BASE/bin/python3"
}

install_rns() {
  info "Installing Reticulum (rns) into venv..."
  "$VENV_PIP" install --upgrade pip
  "$VENV_PIP" install rns
  ok "Reticulum installed."

  for bin in rnsd rncp rnx rnodeconf; do
    local src="$VENV_BASE/bin/$bin"
    [ -f "$src" ] && sudo ln -sf "$src" "/usr/local/bin/$bin" \
      && ok "Symlinked: ${bin} → /usr/local/bin/${bin}"
  done
}

write_reticulum_config() {
  local CONFIG_DIR="$HOME/.reticulum"
  mkdir -p "$CONFIG_DIR"

  cat > "$CONFIG_DIR/config" <<EOL
[reticulum]
  enable_transport = Yes
  share_instance = Yes
  shared_instance_port = 37428
  instance_control_port = 37429
  panic_on_interface_error = No

[logging]
  loglevel = 4

[interfaces]

  [[TCP Server Interface]]
    type = TCPServerInterface
    interface_enabled = True
    listen_ip = 0.0.0.0
    listen_port = 4242
    mode = gw

  [[RNode LoRa Interface]]
    type = RNodeInterface
    interface_enabled = True
    mode = ${RNODE_MODE}
    port = ${RNODE_PORT}
    frequency = ${FREQUENCY}
    bandwidth = ${BANDWIDTH}
    txpower = 22
    spreadingfactor = ${SPREADING_FACTOR}
    codingrate = ${CODING_RATE}

    # European 10% hourly airtime restriction
    airtime_limit_long = 10
EOL
  ok "Reticulum config written: ${CONFIG_DIR}/config"
}

install_rnsd_service() {
  local SVC_USER
  SVC_USER=$(whoami)
  info "Setting up rnsd systemd service..."

  sudo tee /etc/systemd/system/rnsd.service > /dev/null <<EOF
[Unit]
Description=Reticulum Network Stack Daemon (${ENV_NAME})
After=multi-user.target network.target time-sync.target
Wants=network.target
StartLimitIntervalSec=0

[Service]
ExecStartPre=/bin/sleep 5
Type=simple
Restart=always
RestartSec=10
User=${SVC_USER}
ExecStart=${VENV_BASE}/bin/rnsd --service

[Install]
WantedBy=multi-user.target
EOF

  _verify_and_start_service "rnsd"
}

# ── LXMF PropServer ──────────────────────────────────────────────────────────
install_lxmf() {
  info "Installing LXMF into venv..."
  "$VENV_PIP" install lxmf
  ok "LXMF installed."

  local LXMD_DIR="$HOME/.lxmd"
  mkdir -p "$LXMD_DIR"

  cat > "$LXMD_DIR/config" <<EOL
[propagation]
  enable_node = yes
  node_name = ${LXMF_NODE_NAME}
  announce_interval = 360
  announce_at_start = yes
  autopeer = yes
  autopeer_maxdepth = 4
  auth_required = no

[lxmf]
  display_name = ${ENV_NAME}-LXMF-Server
  announce_at_start = yes
  announce_interval = 360
  delivery_transfer_max_accepted_size = 1000

[logging]
  loglevel = 4
EOL
  ok "LXMF config written: ${LXMD_DIR}/config"

  local SVC_USER
  SVC_USER=$(whoami)
  local lxmd_bin="$VENV_BASE/bin/lxmd"
  [ -f "$lxmd_bin" ] && sudo ln -sf "$lxmd_bin" /usr/local/bin/lxmd

  sudo tee /etc/systemd/system/lxmd.service > /dev/null <<EOF
[Unit]
Description=LXMF Propagation Daemon (${LXMF_NODE_NAME})
After=rnsd.service
Requires=rnsd.service
StartLimitIntervalSec=0

[Service]
ExecStartPre=/bin/sleep 40
Type=simple
Restart=always
RestartSec=15
User=${SVC_USER}
ExecStart=${VENV_BASE}/bin/lxmd --service

[Install]
WantedBy=multi-user.target
EOF

  _verify_and_start_service "lxmd"
}

# ── NomadNet ─────────────────────────────────────────────────────────────────
install_nomadnet() {
  info "Installing NomadNet into venv..."
  "$VENV_PIP" install nomadnet msgpack
  ok "NomadNet installed."

  local NN_DIR="$HOME/.nomadnetwork"
  local PAGES_DIR="$NN_DIR/storage/pages"
  mkdir -p "$PAGES_DIR"

  # NomadNet config – node announces for page hosting, client does not
  cat > "$NN_DIR/config" <<EOL
[logging]
  loglevel = 4

[client]
  enable_client = yes
  announce_at_start = no
  announce_interval = 0

[node]
  enable_node = yes
  node_name = ${NOMADNET_NAME}
  announce_at_start = yes
  announce_interval = 360
EOL
  ok "NomadNet config written: ${NN_DIR}/config"

  # Default welcome index page in micron format
  cat > "$PAGES_DIR/index.mu" <<MICRON
>>\`c255Welcome to ${NOMADNET_NAME}\`<<

This node is part of the ${ENV_NAME} Reticulum mesh network.

>>About This Node<<

This Pi is running Reticulum as a LoRa gateway.  Any Reticulum
client on the local network can route through this node.

>>Editing This Page<<

1. SSH into the Raspberry Pi.
2. Edit the file at:
   \`~/.nomadnetwork/storage/pages/index.mu\`
3. Pages use the Nomad Network micron format.
   See the NomadNet docs for syntax help:
   \`https://github.com/markqvist/NomadNet\`

>>Connecting Clients<<

Open MeshChat or Sideband and add a TCP Client interface:
  Host : <your-pi-ip>
  Port : 4242

73 de ${ENV_NAME}
MICRON

  ok "Default index page created: ${PAGES_DIR}/index.mu"

  local SVC_USER
  SVC_USER=$(whoami)
  local nn_bin="$VENV_BASE/bin/nomadnet"
  [ -f "$nn_bin" ] && sudo ln -sf "$nn_bin" /usr/local/bin/nomadnet

  sudo tee /etc/systemd/system/nomadnet.service > /dev/null <<EOF
[Unit]
Description=NomadNet Node (${NOMADNET_NAME})
After=rnsd.service
Requires=rnsd.service
StartLimitIntervalSec=0

[Service]
ExecStartPre=/bin/sleep 40
Type=simple
Restart=always
RestartSec=15
User=${SVC_USER}
ExecStart=${VENV_BASE}/bin/nomadnet --daemon

[Install]
WantedBy=multi-user.target
EOF

  _verify_and_start_service "nomadnet"
}

# ── LXMF Distribution Group ──────────────────────────────────────────────────
install_distgroup() {
  info "Cloning LXMF-Tools from GitHub..."
  local TOOLS_DIR="/opt/lxmf-tools"

  if [ ! -d "$TOOLS_DIR" ]; then
    sudo git clone https://github.com/SebastianObi/LXMF-Tools.git "$TOOLS_DIR"
    sudo chown -R "$(whoami):$(whoami)" "$TOOLS_DIR"
  fi

  local DISTGROUP_SCRIPT="$TOOLS_DIR/lxmf_distribution_group_extended/lxmf_distribution_group_extended.py"
  if [ ! -f "$DISTGROUP_SCRIPT" ]; then
    warn "Distribution group script not found at expected path:"
    warn "  $DISTGROUP_SCRIPT"
    warn "Please check: $TOOLS_DIR"
    return
  fi

  # Install requirements (rns and lxmf - already in venv, but be explicit)
  local REQ_FILE="$TOOLS_DIR/lxmf_distribution_group_extended/requirements.txt"
  [ -f "$REQ_FILE" ] && "$VENV_PIP" install -r "$REQ_FILE"

  # Create the config directory - the script will auto-generate config.cfg on first run
  local DG_CONFIG_DIR="$HOME/.lxmf_distribution_group"
  mkdir -p "$DG_CONFIG_DIR"
  ok "Distribution group config directory: ${DG_CONFIG_DIR}"

  # Write only the override file - config.cfg is auto-generated by the script on first run.
  # config.cfg.owr contains only our changes and takes precedence over the defaults.
  cat > "$DG_CONFIG_DIR/config.cfg.owr" <<EOL
# User overrides for ${DISTGROUP_NAME}
# All settings here take precedence over config.cfg.
# Edit this file to customise - do not edit config.cfg directly.

[lxmf]
display_name = ${DISTGROUP_NAME}
propagation_node_auto = True

# Once lxmd has started, find the propagation node hash with:
#   lxmd --info
# Then uncomment and set the line below, and restart this service.
# propagation_node =
EOL
  ok "Override config written: ${DG_CONFIG_DIR}/config.cfg.owr"

  local SVC_USER
  SVC_USER=$(whoami)

  sudo tee /etc/systemd/system/lxmf-distgroup.service > /dev/null <<EOF
[Unit]
Description=LXMF Distribution Group (${DISTGROUP_NAME})
After=lxmd.service rnsd.service
Requires=lxmd.service
StartLimitIntervalSec=0

[Service]
ExecStartPre=/bin/sleep 60
Type=simple
Restart=always
RestartSec=15
User=${SVC_USER}
ExecStart=${VENV_BASE}/bin/python3 ${DISTGROUP_SCRIPT} -p ${DG_CONFIG_DIR} -s -rs

[Install]
WantedBy=multi-user.target
EOF

  _verify_and_start_service "lxmf-distgroup"
  warn "After first run, check ${DG_CONFIG_DIR}/config.cfg and set:"
  warn "  propagation_node = <hash from: lxmd --info>"
  warn "Then: sudo systemctl restart lxmf-distgroup"
}

# =============================================================================
# COMPLETION SCREEN
# =============================================================================
show_completion() {
  clear
  local IP_ADDR
  IP_ADDR=$(hostname -I | awk '{print $1}')
  local HOSTNAME_LOCAL
  HOSTNAME_LOCAL=$(hostname)

  box_top
  box_blank
  box_line "✔  Installation Complete!" "$GREEN"
  box_blank
  box_mid
  box_line "${ENV_NAME}  –  Reticulum LoRa Gateway" "$CYAN"
  box_mid
  box_blank
  box_left "Hostname   : ${HOSTNAME_LOCAL}" "$WHITE"
  box_left "IP address : ${IP_ADDR}" "$WHITE"
  box_blank
  box_mid
  box_line "Client connection details  (TCP)" "$YELLOW"
  box_mid
  box_blank
  box_left "Host : ${IP_ADDR}  or  ${HOSTNAME_LOCAL}" "$WHITE"
  box_left "Port : 4242" "$WHITE"
  box_blank
  box_mid
  box_line "Recommended Next Steps" "$YELLOW"
  box_mid
  box_blank
  box_left "1.  Test manually first:  rnsd -vvv" "$WHITE"
  box_left "2.  Reboot to activate all services." "$WHITE"
  box_left "3.  Connect MeshChat / Sideband via the TCP details above." "$WHITE"
  if [ "$INSTALL_NOMADNET" = "y" ]; then
    box_blank
    box_left "NomadNet page:  ~/.nomadnetwork/storage/pages/index.mu" "$CYAN"
  fi
  if [ "$INSTALL_DISTGROUP" = "y" ]; then
    box_blank
    box_left "Dist. group:  run 'lxmd --info' after boot and copy the" "$YELLOW"
    box_left "  propagation_node hash into ~/.lxmf_distribution_group/config" "$YELLOW"
  fi
  box_blank
  box_bot
  echo
}

# =============================================================================
# MAIN
# =============================================================================
main() {
  show_splash

  get_env_name
  get_rnode_port
  get_lora_settings
  select_optional_components
  show_summary

  echo
  info "════════════════════════════  Installing  ════════════════════════════"
  echo

  install_system_deps
  create_venv
  install_rns
  write_reticulum_config

  echo
  yn_prompt "Set up rnsd as a system service (starts on boot)?" && install_rnsd_service

  if [ "$INSTALL_LXMF" = "y" ]; then
    echo; info "── LXMF Propagation Server ────────────────────────────────────────"
    install_lxmf
  fi

  if [ "$INSTALL_NOMADNET" = "y" ]; then
    echo; info "── NomadNet ───────────────────────────────────────────────────────"
    install_nomadnet
  fi

  if [ "$INSTALL_DISTGROUP" = "y" ]; then
    echo; info "── LXMF Distribution Group ────────────────────────────────────────"
    install_distgroup
  fi

  show_completion
}

main "$@"
