#!/bin/bash
#
# Reset things done to practice for RHCE

GREEN='\033[0;32m'
LGREEN='\033[1;32m'
RED='\033[0;31m'
CYAN='\033[0;36m'
LCYAN='\033[1;36m'
NC='\033[0m'

help_text="${CYAN}$(basename "$0") Usage: [-hnfk] -- Resets various settings used for RHCE prep to make practice more efficient

    -h print this text

    -d This assumes you're using unbound for a cahing nameserver.  It removes it and all its configs
    -f remove firewall rules that aren't part of the default (ssh, dhcpv6-client)
    -i reset iscsi configs (target and initiator)
    -k reset kerberos configs
    -l reset ldap configs (Client)
    -m Remove postfix configs
    -n reset network interface scripts (you will have no connections or routes)
    -q Reset SELinux Requires Reboot
    -s Set SELinux to permissive mode if not already enabled
    -z Run all options listed above NOTE: Enables SELinux(Permissive mode) and tells you to reboot if you have it disabled${NC}\n"

[ $# -eq 0 ] && { printf "${help_text}"; exit 1; }

turn_on_selinux() {
      selinux_status=$(grep "SELINUX=" /etc/selinux/config | grep -v "#" | cut -d= -f 2)
      if [ "$selinux_status" = "disabled" ]; then
        sed -i 's/SELINUX=disabled/SELINUX=permissive/' /etc/selinux/config
        printf "${RED}Reboot required SELinux changed from disabled to permissive\n${NC}"
      else
        printf "${GREEN}SELinux already enabled\n${NC}"
      fi
}



################################################
# Resets SELinux to defaults.
# Requires Reboot
################################################
reset_selinux() {
      turn_on_selinux
      setenforce 0
      yum -y remove selinux-policy\* 2>/dev/null
      yes| rm -rf /etc/selinux/{targeted,config} 2>/dev/null
      yum -y install selinux-policy-targeted 2>/dev/null
      touch /.autorelabel

      printf "${RED}Reboot required SELinux Reset\n${NC}"
}



################################################
# Reset Network configs by removing ifcfg files
#
# vars:
#   mgmt_interface: defined in rhce_prep.yml
#     This is the name of the interface that
#     you would like to keep available when
#     the network is reset so you can still
#     ssh.
################################################
reset_network() {
    # Clear out Network Configs
#    find /etc/sysconfig/network-scripts/ -not -regex '.*ifcfg-[lo|{{ mgmt_interface }}].*' -regex '.*ifcfg-.*' -exec rm {} +
    ls /etc/sysconfig/network-scripts/ifcfg-* | grep -P '.*ifcfg-(?!(lo|{{ mgmt_interface }})+).*' | xargs rm

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
    firewall-cmd --set-default-zone=public > /dev/null
    firewall-cmd --reload > /dev/null
    printf "${GREEN}Firewall rules reset\n${NC}"
}




################################################
# Reset kerberos configs and remove packages
################################################
reset_kerberos() {
    yes| rm /etc/krb5.conf 2> /dev/null
    yum -y remove krb5-workstation pam_krb5 > /dev/null
    yum -y reinstall krb5-libs > /dev/null
    printf "${GREEN}Kerberos Configs Reset\n${NC}"
}



################################################
# Reset ldap configs and remove packages
################################################
reset_ldap() {
    yum remove -y openldap-clients nss-pam-ldapd >/dev/null
    yes| rm /etc/nslcd.conf 2>/dev/null
    sed -i -e 's/ldap:\/\/.*/ldap:\/\//g' -e 's/BASE.*/BASE/g' /etc/openldap/ldap.conf 2>/dev/null
    printf "${GREEN}LDAP Configs Reset\n${NC}"
}



################################################
# Reset Iscsi Initiator
################################################
reset_iscsi_initiator() {
    yum -y remove iscsi-initiator-utils >/dev/null
    yes| rm -rI /etc/iscsi 2>/dev/null
    yes| rm -rI /var/lib/iscsi/* 2>/dev/null
    printf "${GREEN}ISCSI Initiator Reset\n${NC}"
}



################################################
# Reset Iscsi Target
################################################
reset_iscsi_target() {
    targetcli clearconfig confirm=True
    yum -y remove targetcli
    yes| rm -rI /etc/target 2>/dev/null
    printf "${GREEN}ISCSI Target Reset\n${NC}"
}



################################################
# Remove autofs stuff
################################################
reset_autofs() {
    yum -y remove autofs nfs-utils
    printf "${GREEN}Autofs Reset\n${NC}"
}



################################################
# Remove Unbound and its config
################################################
reset_caching_nameserver() {
    yum -y remove unbound
    yes| rm -rI /etc/unbound 2>/dev/null
    printf "${GREEN}Caching Nameserver Reset\n${NC}"
}



################################################
# Remove postfix and main.cf
################################################
reset_postfix() {
    yes| rm -rI /etc/postfix/main.cf 2>/dev/null
    yum -y reinstall postfix
    printf "${GREEN}Postfix Reset\n${NC}"
}



while getopts :dhmnfkliqsz opt; do
    case $opt in
        h)
            printf "{$help_text}"
            exit
            ;;
        m)
            printf "${CYAN}Resetting Postfix \n${NC}"
            reset_postfix
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
        s)
            turn_on_selinux
            ;;
        q)
            printf "${CYAN}Resetting SELinux\n${NC}"
            reset_selinux            
            ;;
        d)
            printf "${CYAN}Resetting Caching NameServer \n${NC}"
            reset_caching_nameserver
            ;;
        z)
            printf "${CYAN}Resetting Everything\n${NC}"
            reset_postfix
            turn_on_selinux
            reset_kerberos
            reset_network
            reset_firewalld
            reset_ldap
            reset_autofs
            reset_selinux            
            if [ "$(rpm -qa | grep targetcli | wc -l)" -gt 0 ]; then
              reset_iscsi_target
            else
              reset_iscsi_initiator
            fi
            reset_caching_nameserver
            printf "${GREEN}Everything Reset\n${NC}"
            ;;
        \?)	
            printf "{$help_text}\n"
            ;;
    esac
done




