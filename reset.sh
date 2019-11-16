#!/bin/bash

help_text="$(basename "$0") Usage: [-h] [-n] [-f] -- Resets various settings used for RHCE prep to make practice more efficient

	-h print this text
	-n reset network interface scripts (you will have no connections)
	-f remove firewall rules that aren't part of the default (ssh, dhcpv6-client)"

[ $# -eq 0 ] && { echo "$help_text"; exit 1; }


reset_network() {
	# Clear out Network Configs
	find /etc/sysconfig/network-scripts/ -not -regex '.*ifcfg-[lo].*' -regex '.*ifcfg-.*' -exec rm {} +

	# restart network and reload network manager
	systemctl restart network;
	nmcli con reload
	printf "Network configs reset!\n"
}



reset_firewalld() {
	# Reset firewalld Services to default
	for i in service port; do
		for srvc in $(firewall-cmd --list-$i's' | cut -d ' ' -f1-); do
			if [ $srvc != 'ssh' ] && [ $srvc != 'dhcpv6-client' ]; then
				firewall-cmd --permanent --remove-$i=$srvc
				printf "%s Firewall Rule Removed\n" $srvc;
			fi
		done;
	done;
	firewall-cmd --reload
	firewall-cmd --list-all
	printf "Firewall rules reset\n"
}




while getopts :hnf opt; do
	case $opt in
		h)
			echo "$help_text"
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
		\?)	echo "$help_text"
			;;
	esac
done




