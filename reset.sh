#!/bin/bash

help_text="$(basename "$0") Usage: [-h] [-n] [-f] -- Resets various settings used for RHCE prep to make practice more efficient

	-h print this text
	-n reset network interface scripts (you will have no connections or routes)
	-f remove firewall rules that aren't part of the default (ssh, dhcpv6-client)"

[ $# -eq 0 ] && { echo "$help_text"; exit 1; }


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



reset_firewalld() {
	# Reset firewalld Services to default
    for zone in $(firewall-cmd --get-zones | cut -d ' ' -f1-);do
        for i in service port; do
            for srvc in $(firewall-cmd --zone=$zone --list-$i's' | cut -d ' ' -f1-); do
                if [ $srvc != 'ssh' ] && [ $srvc != 'dhcpv6-client' ]; then
                    firewall-cmd --permanent --zone=$zone --remove-$i=$srvc
                    printf "%s %s Firewall Rule in zone %s Removed\n" $srvc, $i, $zone;
                fi
            done;
        done;
    done
    firewall-cmd --reload
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




