#!/usr/bin/env bash

# ANSI color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
LIME='\033[1;32m'
LIGHTBLUE='\033[1;34m'
NC='\033[0m' # No Color

echo -e "${LIGHTBLUE}installing dependencies${NC}"

check_root() {
	if [[ $EUID -ne 0 ]]; then
		echo -e "${RED}ERROR: this script must be run as root${NC}" >&2
		exit 1
	fi
}

check_root

echo -e "${LIME}tmux${NC}"
sudo dnf install -y tmux

echo -e "${LIGHTBLUE}vim${NC}"
sudo dnf install -y vim

echo -e "${GREEN}tree${NC}"
sudo dnf install -y tree

echo -e "${RED}tcpdump${NC}"
sudo dnf install -y tcpdump

echo -e "${LIGHTBLUE}oc${NC}"
sudo dnf install -y openshift-clients

echo -e "${RED}install more tools: nslookup, dig${NC}"
sudo dnf install -y bind-utils

echo -e "${LIME}DONE: ${GREEN}small dependencies installed!${NC}"

echo -e "${GREEN}install virtualization dependencies${NC}"

echo -e "${LIGHTBLUE}qemu-kvm${NC}"
sudo dnf install -y qemu-kvm

echo -e "${LIGHTBLUE}libvirt / libvirtd${NC}"
sudo dnf install -y libvirt

echo -e "${LIGHTBLUE}virt-virt-install${NC}"
sudo dnf install -y virt-install

echo -e "${LIGHTBLUE}virt-viewer${NC}"
sudo dnf install -y virt-viewer

echo -e "${LIGHTBLUE}enable virtualization${NC}"
sudo systemctl enable --now libvirtd

echo -e "${LIME}Virtualization layer installed & enabled!${NC}"

# virt-get-kernel
