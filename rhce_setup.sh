#!/bin/bash

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



main() {
	# Comment ou sections below to disable chunks of the reset
	reset_network
	reset_firewalld

}

main
