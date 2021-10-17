#!/usr/bin/env bash

docker-compose up -d

mv cloud-init/ubuntu/{user,meta}-data netbootxyz/config/nginx/site-confs/



virt-install \
--name ubuntu2004 \
--os-type linux \
--os-variant ubuntu20.04 \
--ram 1024 \
--disk path=/kvm/disk/server-01.img,device=disk,bus=virtio,size=10,format=qcow2 \
--graphics vnc,listen=0.0.0.0 \
--noautoconsole \
--hvm \
--cdrom /kvm/iso/ubuntu-20.04.1-live-server-amd64.iso \
--boot cdrom,hd


virt-install \
--name ubuntu2004 \
--ram 4096 \
--disk path=/var/kvm/images/ubuntu2004.img,size=20 \
--vcpus 2 \
--os-type linux \
--os-variant ubuntu20.04 \
--network bridge=virbr0 \
--graphics none \
--console pty,target_type=serial \
--location 'http://archive.ubuntu.com/ubuntu/dists/focal/main/installer-amd64/' \
--extra-args 'console=ttyS0,115200n8 serial'

virsh shutdown ubuntu2004


