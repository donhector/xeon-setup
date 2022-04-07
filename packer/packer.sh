#!/usr/bin/env bash

set -eu

curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"

# xorriso and genisoimage allows us to create custom OS disk images (ie: bake cloud-init user data into an ISO)
# See https://www.packer.io/plugins/builders/qemu#cd-configuration
sudo apt-get update && sudo apt-get install -y packer xorriso genisoimage

# For some reason Debian does not symlink 'mkisofs to 'genisoimage' after installation
ln -s /usr/local/bin/mkisofs /usr/bin/genisoimage
