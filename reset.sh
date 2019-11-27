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
    -l reset ldap configs (Client)
    -i reset iscsi configs (target and initiator)
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



################################################
# Reset ldap configs and remove packages
################################################
reset_ldap() {
    yum remove -y openldap-clients nss-pam-ldapd 2>/dev/null
    yes| rm /etc/nslcd.conf 2>/dev/null
    sed -i -e 's/ldap:\/\/.*/ldap:\/\//g' -e 's/BASE.*/BASE/g' /etc/openldap/ldap.conf 2>/dev/null
    printf "${GREEN}LDAP Configs Reset\n${NC}"
}



reset_iscsi_initiator() {
    yum -y remove iscsi-initiator-utils
    yes| rm -rI /etc/isci 2>/dev/null
    yes| rm -rI /var/lib/iscsi/* 2>/dev/null
    yum -y install iscsi-initiator-utils
    printf "${GREEN}ISCSI Initiator Reset\n${NC}"
}



reset_iscsi_target() {
    targetcli clearconfig confirm=True
    yum -y remove targetcli
    printf "${GREEN}ISCSI Target Reset\n${NC}"
}
while getopts :hnfkliz opt; do
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
        l)
            printf "${CYAN}Resetting LDAP Configs\n${NC}"
            reset_ldap
            ;;
        i)
          if [ "$(rpm -qa | grep targetcli | wc -l)" -gt 0 ]; then
              printf "${CYAN}Resetting ISCSI Target\n${NC}"
              reset_iscsi_target
          else
              printf "${CYAN}Resetting ISCSI Initiator\n${NC}"
              reset_iscsi_initiator
          fi
            ;;
        z)
            printf "${CYAN}Resetting Everything\n${NC}"
            reset_kerberos
            reset_network
            reset_firewalld
            reset_ldap
            ;;
        \?)	printf "{$help_text}\n"
            ;;
    esac
done




