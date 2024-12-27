#!/bin/bash



# Script to setup a reticulum rnsd on a rasberry pi (LoRa Interface)

# This node will then be used as a gateway for reticulum clients on your network to route over LoRa.

# Author: ag/Andrew

# Compatible with Raspberry Pi running Debian Bookworm



# Check for Debian Bookworm

if ! grep -q "bookworm" /etc/os-release; then

  echo "Error: This script is designed for Debian Bookworm.  Exit..."
  
  exit 1

fi

 echo " _____  _   _  _____ _____         _____ _____ "
 echo "|  __ \| \ | |/ ____|  __ \       |  __ \_   _|"
 echo "| |__) |  \| | (___ | |  | |______| |__) || |  "
 echo "|  _  /| .   |\___ \| |  | |______|  ___/ | |  "
 echo "| | \ \| |\  |____) | |__| |      | |    _| |_ "
 echo "|_|  \_\_| \_|_____/|_____/       |_|   |_____|"
 echo                                  

echo "Welcome to the rnsd Setup Wizard for Raspberry pi!"

echo

echo "This script will guide you through the installation and configuration"
echo "process to setup your pi as a LoRa gateway for reticulum."

echo

# Ask if user has run an to update and upgrade the system

echo "Before we begin, it is recommended to update and upgrade your system."
echo "To do this run 'sudo apt update && sudo apt upgrade -y' at the command prompt"

while true; do
    read -p "Press [Enter] key to continue or 'q' to quit: " choice
    case "$choice" in 
        [Qq]* ) echo "Quitting setup."; exit;;
        "" ) break;;
        * ) echo "Invalid input. Please press [Enter] to continue or 'q' to quit.";;
    esac
done

# Default values from the document

DEFAULT_USB_PATH="/dev/ttyUSB0"

DEFAULT_FREQUENCY="867500000"

DEFAULT_BANDWIDTH="125000"

DEFAULT_SPREADING_FACTOR="9"

DEFAULT_CODING_RATE="5"



# Prompt the user for input

echo

# List available USB devices
echo "Available USB devices:"
ls /dev/ttyUSB*

echo

read -p "Enter USB path (default: $DEFAULT_USB_PATH): " USB_PATH

USB_PATH=${USB_PATH:-$DEFAULT_USB_PATH}



read -p "Enter frequency in MHz (default: $DEFAULT_FREQUENCY): " FREQUENCY

FREQUENCY=${FREQUENCY:-$DEFAULT_FREQUENCY}



read -p "Enter bandwidth in kHz (default: $DEFAULT_BANDWIDTH): " BANDWIDTH

BANDWIDTH=${BANDWIDTH:-$DEFAULT_BANDWIDTH}



read -p "Enter spreading factor (default: $DEFAULT_SPREADING_FACTOR): " SPREADING_FACTOR

SPREADING_FACTOR=${SPREADING_FACTOR:-$DEFAULT_SPREADING_FACTOR}



read -p "Enter coding rate (default: $DEFAULT_CODING_RATE): " CODING_RATE

CODING_RATE=${CODING_RATE:-$DEFAULT_CODING_RATE}



# Confirm the input

echo

echo "You have provided the following configuration:"

echo "  USB Path: $USB_PATH"

echo "  Frequency: $FREQUENCY MHz"

echo "  Bandwidth: $BANDWIDTH kHz"

echo "  Spreading Factor: $SPREADING_FACTOR"

echo "  Coding Rate: $CODING_RATE"

echo

read -p "Do you want to proceed with these settings? (y/n): " CONFIRM

if [[ $CONFIRM != "y" ]]; then

  echo "Setup aborted."

  exit 1

fi

echo

# Install dependencies

echo "Installing dependencies..."

sudo apt install -y python3 python3-pip python3-cryptography python3-serial

echo

# Check if dependencies are installed
echo "Checking if dependencies are installed..."

dependencies=(python3 python3-pip python3-cryptography python3-serial)
for dep in "${dependencies[@]}"; do
  if ! dpkg -s "$dep" >/dev/null 2>&1; then
    echo "Error: $dep is not installed.  Cannot continue"
    exit 1
  fi
done

echo

echo "All dependencies are installed."

echo

# Clone and install Reticulum

echo "Installing Reticulum..."

pip install rns --break-system-packages

echo 

echo "Checking install..."
# Check if rns is installed
if ! pip show rns >/dev/null 2>&1; then
  echo "Error: rns was not installed. Cannot continue."
  echo "Please run the installation manually."
  exit 1
fi

echo

sudo ln -s $(which rnsd) /usr/local/bin/

echo

# Add ~/.local/bin to PATH for the current session

USER=$(whoami)

echo "Adding /home/$USER/.local/bin to the PATH..."

if ! grep -q "/home/$USER/.local/bin" ~/.bashrc; then
  echo "export PATH=\$PATH:/home/$USER/.local/bin" >> ~/.bashrc
fi

PATH=$PATH:/home/$USER/.local/bin

echo

# Apply changes immediately to the current session

source ~/.bashrc



# Create configuration file

CONFIG_PATH="$HOME/.reticulum"

mkdir -p $CONFIG_PATH



cat <<EOL > $CONFIG_PATH/config

[reticulum]

  enable_transport = Yes

  share_instance = Yes



  shared_instance_port = 37428

  instance_control_port = 37429



  panic_on_interface_error = No



[logging]

  loglevel = 4



[interfaces]

  [[Default Interface]]

    type = AutoInterface

    interface_enabled = True



  [[TCP Server Interface]]

    type = TCPServerInterface

    interface_enabled = True



    # This configuration will listen on all IP

    # interfaces on port 4242



    listen_ip = 0.0.0.0

    listen_port = 4242



  # Reticulum configuration for LoRa

  [LoRaInterface]

    enabled = true

    type = RNodeInterface

    device = $USB_PATH

    frequency = $FREQUENCY

    bandwidth = $BANDWIDTH

    spreading-factor = $SPREADING_FACTOR

    coding-rate = $CODING_RATE

    tx-power = 22

EOL



# Prompt user for service setup

echo

read -p "Do you want to set up rnsd as a system service? (y/n): " SERVICE_CONFIRM

if [[ $SERVICE_CONFIRM == "y" ]]; then

  echo "Setting up rnsd as a system service..."

 

  # Create systemd service file

  sudo bash -c 'cat <<EOF > /etc/systemd/system/rnsd.service

 [Unit]

Description=Reticulum Network Stack Daemon

After=multi-user.target



[Service]

ExecStartPre=/bin/sleep 30

Type=simple

Restart=always

RestartSec=3

User=$(whoami)

ExecStart=rnsd --service



[Install]

WantedBy=multi-user.target



EOF'



  # Enable and start the service

  sudo systemctl enable rnsd
  sudo systemctl start rnsd

  echo "rnsd has been set up as a system service and started."

fi

echo

sudo systemctl status rnsd

# Completion message

echo

echo "Congratulations!"

echo

echo "rnsd has been successfully installed and started with your configuration."

echo "To stop the service, use the command: sudo systemctl stop rnsd"

echo "If you wish to debug the service please stop it as above and run rnsd -vvv"

# Get the current hostname and IP address
HOSTNAME=$(hostname)
IP_ADDRESS=$(hostname -I | awk '{print $1}')

# Information on how to connect to this system in MeshChat via TCP
echo
echo "To connect to this rnsd instance in MeshChat via a TCP client interface, use the following details..."
echo "IP address: $IP_ADDRESS or Host: $HOSTNAME"
echo "Port: 4242"
echo
echo "Replace $IP_ADDRESS with the IP address of this system if it changes."
echo "It is best practice to set a static IP address for this system."

