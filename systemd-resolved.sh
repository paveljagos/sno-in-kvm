#!/usr/bin/env bash

# ANSI color codes
RED='\033[0;31m'
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

echo -e "${LIME}installing systemd-resolved${NC}"
sudo dnf install -y systemd-resolved

sudo systemctl enable --now systemd-resolved

echo -e "${LIGHTBLUE}configuring systemd-resolved${NC}"
sudo ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf

sudo systemctl restart systemd-resolved

sudo mkdir -p /etc/systemd/resolved.conf.d/
sudo bash -c 'cat <<EOF > /etc/systemd/resolved.conf.d/sno-dev-01.conf
[Resolve]
DNS=192.168.123.1
Domains=~sno.ocp.dev
EOF'

## restart resolver to load confirutation
sudo systemctl restart systemd-resolved

# confirm the resolver is running
verify_resolved() {
	echo -e "${LIGHTBLUE}verifying systemd-resolved is up and running${NC}"

	# is-active returns 0 only when the unit is running
	if ! systemctl is-active --quiet systemd-resolved; then
		echo -e "${RED}ERROR: systemd-resolved is not active${NC}" >&2
		systemctl status systemd-resolved --no-pager -l >&2
		exit 1
	fi

	# make sure it is enabled to start on boot
	if ! systemctl is-enabled --quiet systemd-resolved; then
		echo -e "${RED}WARNING: systemd-resolved is not enabled on boot${NC}" >&2
	fi

	# optional: confirm DNS resolution actually works via the stub resolver
	if command -v resolvectl >/dev/null 2>&1; then
		resolvectl status >/dev/null 2>&1 &&
			echo -e "${LIME}resolvectl responding${NC}" ||
			echo -e "${RED}WARNING: resolvectl did not respond${NC}" >&2
	fi

	echo -e "${LIME}systemd-resolved is up and running${NC}"
}

verify_resolved
