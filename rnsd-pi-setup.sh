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



echo "Welcome to the rnsd Setup Wizard for rnsd on Raspberry pi!"

echo "This script will guide you through the installation and configuration process."

echo

# Ask if user has run an to update and upgrade the system

echo

echo "Before we begin, it is recommended to update and upgrade your system."
echo "This ensures that you have the latest software packages and security updates."
echo "If you allow this script to run the update and upgrade, it will take a few minutes to conplete and then quit."
echo "You can also choose to skip this step and continue with the installation."
echo "You will need to run the setup again to install rnsd if you run the updates."

read -p "Would you like to run 'sudo apt update && sudo apt upgrade -y' to update your system? (y/n): " UPDATE_CONFIRM

if [[ $UPDATE_CONFIRM == "y" ]]; then

  echo "Updating system..."

  sudo apt update && sudo apt upgrade -y

  exit 1

else

  echo "Skipping system update."

fi

# Default values from the document

DEFAULT_USB_PATH="/dev/ttyUSB0"

DEFAULT_FREQUENCY="867500000"

DEFAULT_BANDWIDTH="125000"

DEFAULT_SPREADING_FACTOR="9"

DEFAULT_CODING_RATE="5"



# Prompt the user for input

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


# Install dependencies

echo "Installing dependencies..."

sudo apt install -y python3 python3-pip python3-cryptography python3-serial

# Check if dependencies are installed
echo "Checking if dependencies are installed..."

dependencies=(python3 python3-pip python3-cryptography python3-serial)
for dep in "${dependencies[@]}"; do
  if ! dpkg -s "$dep" >/dev/null 2>&1; then
    echo "Error: $dep is not installed.  Cannot continue"
    exit 1
  fi
done

echo "All dependencies are installed."


# Clone and install Reticulum

echo "Installing Reticulum..."

pip install rns --break-system-packages

# Check if rns is installed
if ! pip show rns >/dev/null 2>&1; then
  echo "Error: rns was not installed. Cannot continue."
  echo "Please run the installation manually."
  exit 1
fi

sudo ln -s $(which rnsd) /usr/local/bin/



# Add ~/.local/bin to PATH for the current session

USER=$(whoami)

echo "Adding /home/$USER/.local/bin to the PATH for the current session..."

echo "export PATH=\$PATH:/home/$USER/.local/bin" >> ~/.bashrc

echo "export PATH=\$PATH:/home/$USER/.local/bin" >> ~/.profile



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



# Reticulum configuration for Scenario 2

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



# Completion message

echo

echo "Congratulations!"

echo "rnsd has been successfully installed and started with your configuration."

echo "To stop the service, use the command: sudo systemctl stop rnsd"

echo "If you wish to debug the service please stop it as above and run rnsd -vvv"


