#!/bin/bash
#
# Reset things done to practice for RHCE

GREEN='\033[0;32m'
LGREEN='\033[1;32m'
RED='\033[0;31m'
CYAN='\033[0;36m'
LCYAN='\033[1;36m'
NC='\033[0m'

help_text="${CYAN}$(basename "$0") Usage: [-h] [-n] [-f] [-k] -- Resets various settings used for RHCE prep to make practice more efficient

    -h print this text
    -n reset network interface scripts (you will have no connections or routes)
    -f remove firewall rules that aren't part of the default (ssh, dhcpv6-client)
    -k reset kerberos configs
    -z Run all options listed above${NC}\n"

[ $# -eq 0 ] && { printf "${help_text}"; exit 1; }



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
    printf "${GREEN}Network configs reset!\n${NC}"
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
    printf "${GREEN}Firewall rules reset\n${NC}"
}




################################################
# Reset kerberos configs and remove packages
################################################
reset_kerberos() {
    yes| rm /etc/krb5.conf 2> /dev/null
    yum -y remove krb5-workstation pam_krb5 2> /dev/null
    yum -y reinstall krb5-libs 2> /dev/null
    printf "${GREEN}Kerberos Configs Reset\n${NC}"
}


while getopts :hnfkz opt; do
    case $opt in
        h)
            printf "{$help_text}"
            exit
            ;;
        n)
            printf "${CYAN}Resetting Network Configs\n${NC}"
            reset_network
            ;;
        f)
            printf "${CYAN}Resetting Firewall\n${NC}"
            reset_firewalld
            ;;
        k)
            printf "${CYAN}Resetting Kerberos Configs\n${NC}"
            reset_kerberos
            ;;
        z)
            printf "${CYAN}Resetting Everything\n${NC}"
            reset_kerberos
            reset_network
            reset_firewalld
            ;;
        \?)	printf "{$help_text}\n"
            ;;
    esac
done




