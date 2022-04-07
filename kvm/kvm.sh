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
	libosinfo-bin \
  genisoimage \
  xorriso

# genisoimage and xorriso allow us to create ISO files
# this is useful for creating cloudinit ISO disks or packer images.
# macvicar libvirt provider uses 'mkisofs' from genisoimage
# For some reason debian10 does not symlink 'mkisofs to 'genisoimage'
ln -s /usr/local/bin/mkisofs /usr/bin/genisoimage

# Create and manage VMs without root privileges. Logout is required 
sudo usermod -aG libvirt $USER
sudo usermod -aG kvm $USER

# By default qemu runs under the root user. This might cause issues
# when using the macvicar libvirt terraform provider, so its better to
# run qemu as our user, which we already added to libvirt & kvm groups
sudo sed -i "s/#user = \"root\"/user = \"${USER}\"/g" /etc/libvirt/qemu.conf
sudo sed -i "s/#group = \"root\"/group = \"libvirt\"/g" /etc/libvirt/qemu.conf
sudo systemctl restart libvirtd

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

# By default all VM networking is via NAT using virbr0 (default network)
# We can enable DHCP for that network. To do so 

sudo virsh net-edit default

# Then make sure the <dhcp> section is added.
# This will provide VMS with an IP in the range and netbooting capabilities via netboot.xyz

# <network>
#   <name>default</name>
#   <uuid>836520d9-fb0a-46f0-8745-033353151e93</uuid>
#   <forward mode='nat'/>
#   <bridge name='virbr0' stp='on' delay='0'/>
#   <mac address='52:54:00:5d:42:fc'/>
#   <ip address='192.168.122.1' netmask='255.255.255.0'>
#     <dhcp>
#       <range start='192.168.122.2' end='192.168.122.254'/>
#       <bootp file='http://boot.netboot.xyz/ipxe/netboot.xyz.kpxe'/>
#     </dhcp>
#   </ip>
# </network>


# This will provide the OS guests on virb0 with an IP.
# This makes it easier for netbooting the guests using IPXE 

# For changes in the default network to be in effect:
sudo virsh net-destroy default
sudo virsh net-start default

# If VMs need to be on the same network as the host (i.e: not NATed but bridged)
# then we need to create a new bridge bound to our host's primary physical interface,
# and then create a new virtual network in KVM so it uses this new bridge. Finally,
# we need to disable netfilter for the bridge to allow all traffic be forwarded to it.
# It is not recommended to bridge to your hosts Wirelss interface. Use ethernet.
# If you still want to bridge over the wlan iface then google "kvm arp proxy" "parprouted"
# but be prepared for a deep rabbit hole.

# To create the new bridge, we can proceed in different ways:
# issuing `ip` commands or via the OS network configuration service.
# The second method has the advantage that changes are persisted across reboots.

# First, let's try to retrieve which one is the primary iface on the host and 
# choose a name for our bridge, and ensure the iface is up
IFACE=$(ip route | grep default | cut -d' ' -f5)
BRIDGE=br0
sudo ip link set ${IFACE} up

## Method 1: ip commands (won't survive reboots)

# create network bridge
sudo ip link add br0 type bridge
sudo ip link show type bridge

# add the host's primary interface to the bridge
sudo ip link set ${IFACE} master ${BRIDGE}

# verify it did, should show our interface
sudo ip link show master ${BRIDGE}

# At this point we can assing an static ip to our newly created bridge
sudo ip address add dev br0 192.168.1.100/24
ip addr show br0

# Method 2: Bridge definition file for the OS (Debian derivatives)
sudo cat <<EOF > /etc/network/interfaces.d/${BRIDGE}-static.conf
# Primary network interface
auto ${IFACE}
iface ${IFACE} inet manual

# Bridge definition
auto ${BRIDGE}
iface ${BRIDGE} inet static
  bridge_ports    ${IFACE}
  address         192.168.1.100
  netmask         255.255.255.0
  broadcast       192.168.1.255
  gateway         192.168.1.1
  dns-nameservers 192.168.1.1
  bridge_stp off       # disable Spanning Tree Protocol
  bridge_waitport 0    # no delay before a port becomes available
  bridge_fd 0          # no forwarding delay
EOF

# If you wanted dynamic dchp for the bridge
sudo cat <<EOF > /etc/network/interfaces.d/${BRIDGE}-dhcp.conf
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


## Disable netfilter for the bridge
# To do this we can create a file with the .conf extension inside the /etc/sysctl.d directory, let’s call it 99-netfilter-bridge.conf. Inside of it we write the following content:
sudo cat <<EOF > /etc/sysctl.d/99-netfilter-bridge.conf
net.bridge.bridge-nf-call-ip6tables = 0
net.bridge.bridge-nf-call-iptables = 0
net.bridge.bridge-nf-call-arptables = 0
EOF

# Load the br_netfilter module in case is not
sudo modprobe br_netfilter

# Ensure the br_netfilter module is automatically loaded at boot:
echo 'br_netfilter' | sudo tee /etc/modules-load.d/br_netfilter.conf

# Apply the netfilter config we just created
sudo sysctl -p /etc/sysctl.d/99-netfilter-bridge.conf

### Create a new virtual network that uses our new bridge

# Define the new network
cat <<EOF > bridged.xml
<network>
    <name>bridged</name>
    <forward mode="bridge" />
    <bridge name="br0" />
</network>
EOF

sudo virsh net-define bridged.xml

# start the network
sudo virsh net-start bridged

# ensure it runs on startup
sudo virsh net-autostart bridged
