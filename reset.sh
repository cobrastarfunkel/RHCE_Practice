#!/bin/bash
#
# Reset things done to practice for RHCE

help_text="$(basename "$0") Usage: [-h] [-n] [-f] -- Resets various settings used for RHCE prep to make practice more efficient

	-h print this text
	-n reset network interface scripts (you will have no connections or routes)
	-f remove firewall rules that aren't part of the default (ssh, dhcpv6-client)"

[ $# -eq 0 ] && { echo "${help_text}"; exit 1; }



################################################
# Reset Newtork configs by removing ifcfg files
################################################
reset_network() {
	# Clear out Network Configs
	find /etc/sysconfig/network-scripts/ -not -regex '.*ifcfg-[lo].*' -regex '.*ifcfg-.*' -exec rm {} +

    # Clear Routes
    ip route flush all

	# restart network and reload network manager
	systemctl restart network;
	nmcli con reload
	printf "Network configs reset!\n"
}



################################################
# Reset firewalld Zones to default settings.
#
# Deleteing the zone files will set the zones 
# back to default values.
# Defaults are defined in /usr/lib/firewalld.
# Once you add a rule a new file will be created 
# in /etc/firewalld/zones
################################################
reset_firewalld() {
    yes| rm -I /etc/firewalld/zones/* 2> /dev/null
    firewall-cmd --reload
    printf "Firewall rules reset\n"
}




while getopts :hnf opt; do
	case $opt in
		h)
			echo "{$help_text}"
			exit
			;;
		n)
			echo "Resetting Network Configs"
			reset_network
			;;
		f)
			echo "Resetting Firewall"
			reset_firewalld
			;;
		\?)	echo "{$help_text}"
			;;
	esac
done




