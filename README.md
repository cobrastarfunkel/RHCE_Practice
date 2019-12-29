RHCE TEST PREP
======
This is meant to study for the RHCE.
##### Hostnames and fqdn's are set by ansible.  Configure group_vars/all "long_domain" "short_domain" for the domain and the "ansible_hostname" in the inventory file for the hostname. 

##### The IPA server was setup using the guide from https://www.lisenet.com/rhce/.  If you follow this everything should work as long as you configure the ip's, domain, and other variables to match what you plan to use.  There is also a ton of information available on the site as well as a good practice exam.

#### Servers Used for Lab
   IPA Server: ipa.rhce.lab
   Has DNS convigured and is the mail server if you want.
   mgmt ip: 192.168.0.102
   internal ip: 10.0.0.102
	
   Web Server, Iscii Initiator: server1.rhce.lab
   Should have at least 3 interfaces and two hard disks
   2 Interfaces on the internal network and one management interface on the external network
   The management interfaces are optional I suppose but it's helpful to have seperation for 
   some of the firewall rules. The interfaces reflect my setup with proxmox.
  
   teamed interface(ens19 & ens20) ip: 10.0.0.103
   mgmt interface(eth0): 192.168.0.103
	
   Iscii Target: server2.rhce.lab
   Should have 3 interfaces and two hard disks
   teamed interfaces ip: 10.0.0.104
   mgmt interface: 192.168.0.104

TOC
====
* [Reset Servers](#Reset-Servers)
* [RHCE Tasks](#RHCE-Tasks)
* [Kerberos Server Setup](#Kerberos-setup)
* [LDAP Server Setup](#LDAP-setup)

TODO: Fix how hostname is set, ansible will assign the ip if you run the rhce_prep.yml playbook against an individual host using the -i flag.

###### NOTE: /etc/hosts is based off of the ansible inventory file.  Set the path in group_vars/all.  It greps out your uncommented ansible host assignments.  It only looks for hosts in this format "hostname ansible_host=192.168.1.2".

TODO: Cover the rest of the inventory formats for hosts file

### Reset Servers Script
The reset.sh script will reset your server.  The script has a jinja variable in it that need to be set.  After you run the push_reset.yml playbook the templated_reset.sh can be run manually if you want.

#### Volume Groups
##### NOTE: Entries in fstab are not removed by default with partitions. If you reset nfs it will reset fstab as well but for the partitions make sure you have the -t option passed in reset_args or the entries will still be there.  Follow the format in the script of '## LAB Stuff'.  All line below this will be removed from fstab.  Make sure the lab entries are there under that line or you could end up troubleshooting when your server fails to boot.
Volume groups can be removed with the reset script if you want it to.  Set the names of the volume groups in the push_reset.yml (Keep this as a list even if you only have one lvm, so keep the same ['vgname'] format) and pass an extra variable(Example Below) setting remove_vgs to True.

#### Partitions
Partitions can also be removed.  The default is sdb but change it to whatever device the partitions you want to remove were created on in the push_reset.yml file under device_to_remove and pass an extra variable(Example Below) setting remove_parts to True. **It will remove all partitions from that device. This also triggers the vg's to be removed so you don't need to pass remove_vgs=True if you pass remove_parts=True.**

#### Network Interfaces
Assign the name of the connection you want preserved to the mgmt_interface variable in push_reset.yml.  This is the ifcfg-{{ name }} of the file under /etc/sysconfig/network-scripts.  This is so the server can still be accessed by SSH instead of having to directly access it through the console.

#### Iscsi Initiator
Assign the location of the iscsi fileio you use in the push_reset.yml file.

#### Reseting
Run the push_reset.yml playbook to push out the script to other servers.  You can pass args to the playbook by using --extra-vars:

     ansible-playbook push_reset.yml --extra-vars "reset_args=-i, remove_vgs=True, remove_parts=True"
     
###### All extra vars are optional but it won't do anything if you don't define any.

### RHCE Tasks


##### Make sure SELinux is in enforcing mode
Point both servers to the ipa server to use as a time server

#### Server1 Partitioning
Create a GPT partition table and add 2 partitions:
1 swap partition of 3G
1 lvm partition of the remaining space

Give the swap partition the label of RHCE_SWAP and persistently mount it

Create a volume group name vg_rhce using the lvm partition
Create one lvm named lv_ext4 with 1Gb of space, ext4 filesystem and label it RHCE_EXT4.  Mount it persistently at /mnt/lv_ext4

Add the remaining space from vg_rhce to lv_ext4

Make a 1Gb swap lvm named lv_swap by removing space from lv_ext4 and mount it peristently

Reboot to verify config at some point


#### Server2 Partitioning
Create a MBR partition table, 3 100Mb Primary partitions, and one extended partition using the rest of the space.
Create a 1Gb swap partition and a 2G lvm partition on the extended partition
Create a vg named vg_iscsi and an lvm called lv_iscsi with 1G of space and xfs filesystem

#### Firewall Rules
###### Server1 Firewall Rich Rules
Team the two available interfaces to use active backup with ip: 10.0.0.103/24 dns:8.8.8.8

Install httpd and add a test file to the web server and make it listen on 10.0.0.103 port 5555. Configure SELinux accordingly

Configure a firewall rich rule in the dmz zone that allows traffic to http only from 10.0.0.104.  Log the traffic with a prefix of HTTP_5555. Make sure the teamed interface uses the dmz also ensure any requests made to the server on port 80 from 10.0.0.104 are redirected to port 5555 and are routed through the dmz zone. 


###### Server 2 Rich Rules
Configure two interfaces to make a teamed interface for activebackup ip 10.0.0.104(Everything else is the same as server1) on the private zone, configure the third interface to have the ip 192.168.0.104/24

Forward traffic for port 22 on the 10.0.0.104 interface to 2222 and configure ssh to work on 2222. It should only allow 10.0.0.103 to ssh on that port and should reject traffic from the ipa.  It should log both with a prefix of SSH_2222_SERVERNAME

#### LDAP
Join the two servers to the ipa server for user authentication

#### DNS
Configure server2 as a caching nameserver that listens on the teamed interface(10.0.0.104) and allows connections from the 10.0.0.0 subnet forward recursive queries to the ipa server(10.0.0.102). The rhce.lab zone is excluded from DNSSEC

#### Null Mail Server
Configure server2 to be a null client that forwards messages to the ipa server(10.0.0.104)

#### Iscsi
Server2 will be the target

On server1 change the intiator name to 2019-12.lab.rhce:init1

###### Server2
Resive the lv_iscsi and filesystem from before to have the rest of the space on vg_iscsi
Create a block backstore named block1 using lv_iscsi
Create a fileio backstore named file1 of 100M in /root/iscsi_file with caching disabled

Create an IQN called server1
In this IQN create 2 LUN's using the block1 and file1 backstores
Add an acl for server1
Add a portal for the 10.0.0.103 ip
Use CHAP authentication userid=server1 password=server1

###### Server1
Log into the target created on server2
Mount file1 persistently at /iscsi_file

#### Kerberos
Use the mgmt interfaces for kerberos / nfs stuff or change the /etc/hosts file to have the 10.0.0.0 ip's.  Otherwise kerberos won't work

Join both servers to the ipa server using Kerberos (The keytabs are in /var/ftp/pub/server{1,2}.keytab on the ipa server)
Use alice or paul from the ldap server and try to get a Kereberos ticket password is password


#### NFS
Use the mgmt interface for nfs / kerberos stuff

###### Server1 will be the NFS server
There will be 3 NFS shares 
Ensure selinux bools are secured(nfs_export_all_ro and rw)
The public nfs dir will be /srv/nfs_pub only the 10.0.0.0/24 subnet is allowed. Change the selinux context to public_content_rw_t
Set nfs_t for other nfs shares
The kerberos nfs dir will be /srv/nfs_sec
The group nfs dir will be /srv/nfs_group selinux context nfs_t

Create a group called nfsgroup and ensure all files in the /srv/nfs_group share are rw for the group and only file owners can delete files
Change ownership of the nfs_sec share to alice
Mount the nfs_sec share persistently on server2 at /mnt/nfs_sec
Test the other two on /mnt/nfs_pub nfs_group

#### SMB Shares
On Server2 create the directories /srv/smb_{group,multi}
Create a group called smbgroup that can use the smb_group share and two samba users named john and nance. Put john in the smbgroup
Set john's password to password
Configure a samaba share on smb_group that only allows 10.0.0.0/24 and localhost connections and is owned by the smbgroup.  Users should be able to collaborate but only file owners should be able to remove files. smbgroup can read and write nance can only read

Create a share called multi on /srv/smb_multi that allows alice to write and paul to read.  

On Server1 mount the group share persistently at /mnt/smb_group using a file (/root/smbjohn.txt) for the username and password of john
On Server1 Mount /srv/smb_multi persistently as a multiuser mount using johns credentials

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
