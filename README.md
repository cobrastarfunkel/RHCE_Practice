RHCE TEST PREP
======
This is meant to study for the RHCE by setting up some of the requirments to practice exam objectives.
##### Hostnames and fqdn's are set by ansible.  Configure group_vars/all "long_domain" "short_domain" for the domain and the "ansible_hostname" in the inventory file for the hostname. 

TOC
====
* [Reset Servers](#Reset-Servers)
* [Kerberos Server Setup](#Kerberos-setup)
* [LDAP Server Setup](#LDAP-setup)

TODO: Fix how hostname is set, ansible will assign the ip if you run the playbook against an individual host using the -i flag.

###### NOTE: /etc/hosts is based off of the ansible inventory file.  Set the path in group_vars/all.  It greps out your uncommented ansible host assignments.  It only looks for hosts in this format "hostname ansible_host=192.168.1.2".

TODO: Cover the rest of the inventory formats for hosts file

### Reset Servers
The reset.sh script will reset your server.  It will remove network connections, reset firewalld, and clear out kerberos and ldap configs.  Run ./reset.sh -h to view options.  If you run it aginst the kerberos server or you have kerberos running on the same server you're using to practice it will break it.  Running the Ansible playbook again should fix it but for that reason it may be hard to practice setting up a kerberos client if the kerberos server is on the server you're practicing on.

#### Volume Groups
Volume groups can be removed with the reset script if you want it to.  Set the names of the volume groups in the push_reset.yml (Keep this as a list even if you only have one lvm, so keep the same ['vgname'] format) and pass an extra variable(Example Below) setting remove_vgs to True.

#### Partitions
Partitions can also be removed.  The default is sdb but change it to whatever device the partitions you want to remove were created on in the push_reset.yml file under device_to_remove. **It will remove all partitions from that device.**

#### Network Interfaces
Assign the name of the connection you want preserved to the mgmt_interface variable in push_reset.yml.  This is the ifcfg-{{ name }} of the file under /etc/sysconfig/network-scripts.  This is so the server can still be accessed by SSH instead of having to directly access it through the console.

#### Reseting
Run the push_reset.yml playbook to push out the script to other servers.  You can pass args to the playbook by using --extra-vars:

     ansible-playbook push_reset.yml --extra-vars "reset_args=-i, remove_vgs=True, remove_parts=True"
     
###### All extra vars are optional but it won't do anything if you don't define any.

### Kerberos Setup
#### Before you Run the Playbook
* In ansible/group_vars/kdc_server change ports if you want.
* The KDC server is defined by the hosts file under [kdc_server].  Define the host you want to be the Kerberos server here.
    
Run playbook:
    
    ansible-playbook kdc.yml

Login to Kerberos server and Run:

    kdb5_util create -s
    Create your password
    
  The following will open the kerberos prompt, you neeed to add "principals"
  
    kadmin.local:
        
    addprinc host/{ host fqdn }
    Create a password for the Principal
        
  Create a Keytab for the Host or hosts from above:
  
    ktadd -k /etc/krb5.keytab host/{ host fqdn }
        
    exit

  To test that you can get a ticket run:
  
    kinit
    klist
        
Log back into the practice server and test Kerberos:

Run:

    kinit
  You should get a ticket
        
    klist
  Should list tickets
        
  Once you have a ticket try to ssh to the kdc using Kerberos:
  
    ssh -k kerberos_server_hostname

### LDAP Setup
#### Before you Run the Playbook
* Configure the LDAP server in the hosts file.  In the example we're using the KDC as the LDAP server.
* Set the ldap port in group_vars/ldap_server if you want it to be something else.
* An encrypted vault password needs to be set to add some of the ldap stuff.  Replace the vault value in
  group_vars/ldap_server or put it in there in plaintext if you don't care.
* Create users in roles/ldap_server/vars/main.yml in the same way the example ldapusers are set.
* Turns out OpenLDAP is picky about ldif files and white space hence the overly complicated file to add users.  This will compare the output of getent passwd to the list of users you want to add.  If the user already exists it will be skipped to stop LDAP errors.  If you can't use getent for some reason to pull a user list switch the command at the top of roles/ldap_server/main.yml to pull your user list.
* Groups are managed in the ldap_server/vars/main.yml file.  It will handle the same gid by ignoring it but group names aren't checked at the moment.

Run:

    slappasswd -h {SSHA} -s your password
  Save the output of this command and put it in the /templates/db.ldif.j2 file at the bottom where it says olcRootPw.

Run:

    ansible-playbook ldap.yml --ask-vault-pass
  *Note: You don't need the --ask-vault-pass if you chose to not encrypt your password*

To test Run:

    getent passwd # For users
    getent group # For Groups
