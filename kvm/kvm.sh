#!/usr/bin/env bash

set -eu

# Check CPU support for virtualization
grep -E --color '(vmx|svm)' /proc/cpuinfo

# Install QEMU-KVM & Libvirt packages along with virt-manager
sudo apt install --no-install-recommends -y \
	qemu-kvm \
	libvirt-clients \
	libvirt-daemon \
	libvirt-daemon-system \
	bridge-utils \
	virtinst \
	virt-manager

echo

# Check if service is Running and Enabled
sudo systemctl status libvirtd.service

# Optional: Install some additional management tools
sudo apt install --no-install-recommends -y \
	virt-top \
	libguestfs-tools \
	libosinfo-bin

# Create and manage VMs without root privileges. Logout is required 
sudo usermod -aG libvirt $USER
sudo usermod -aG kvm $USER

### Network setup
# Check if the default network is active
sudo virsh net-list --all

# Activate the 'default' network and make is start on boot
sudo virsh net-start default
sudo virsh net-autostart default

# Load vhost_net kernel module for an improved virtual network performance
sudo modprobe vhost_net
echo "vhost_net" | sudo  tee -a /etc/modules

# Check it is loaded
lsmod | grep vhost

# By default all VM networking is via NAT using virbr0
# If external access is needed we need to create a new bridge bound to our primary interface
# It is not recommended to bridge your Wirelss interface. So use ethernet
# if you still want to bridge over the wlan iface then google "kvm arp proxy" "parprouted"
IFACE=$(ip route | grep default | cut -d' ' -f5)
BRIDGE=br0

# Bridge definition file
sudo cat <<EOF > /etc/network/interfaces.d/${BRIDGE}
# Primary network interface
auto ${IFACE}
iface ${IFACE} inet manual

# Bridge definition
auto ${BRIDGE}
iface ${BRIDGE} inet static
  address         192.168.1.100
  netmask         255.255.255.0
  broadcast       192.168.1.255
  gateway         192.168.1.1
  dns-nameservers 192.168.1.1
  bridge_ports ${IFACE}
  bridge_stp off       # disable Spanning Tree Protocol
  bridge_waitport 0    # no delay before a port becomes available
  bridge_fd 0          # no forwarding delay
EOF

# If you wanted dynamic dchp for the bridge
sudo cat <<EOF > /etc/network/interfaces.d/${BRIDGE}
# Primary network interface
auto ${IFACE}
iface ${IFACE} inet manual

# Bridge definition
auto ${BRIDGE}
iface ${BRIDGE} inet dhcp
  bridge_ports ${IFACE}
  bridge_stp off       # disable Spanning Tree Protocol
  bridge_waitport 0    # no delay before a port becomes available
  bridge_fd 0          # no forwarding delay
EOF