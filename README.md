RHCE TEST PREP
======
This is meant to study for the RHCE.
##### Hostnames and fqdn's are set by ansible.  Configure group_vars/all "long_domain" "short_domain" for the domain and the "ansible_hostname" in the inventory file for the hostname. 

##### The IPA server was setup using the guide from https://www.lisenet.com/rhce/.  If you follow this everything should work as long as you configure the ip's, domain, and other variables to match what you plan to use.  There is also a ton of information available on the site as well as a good practice exam.  It doesn't go over configuring the ipa server to be a router.  If you don't want to access your servers from outside of the 10.0.0.0 network then don't worry about it.  If you do want to access it writing some firewalld rich rules to forward ssh traffic to the servers below is one way to set that up.

#### Servers Used for Lab
   IPA Server: ipa.rhce.lab
   Has DNS convigured and is the mail server if you want.
   mgmt ip: 192.168.0.102 (Setup forwarding to the 10.0.0.0 network)
   
   internal ip: 10.0.0.102
	
   
##### Web Server, Iscii Initiator: server1.rhce.lab
   Should have 2 interfaces and two hard disks
   2 Interfaces on the internal network and one management interface on the external network
   The management interfaces are optional I suppose but it's helpful to have seperation for 
   some of the firewall rules. The interfaces reflect my setup with proxmox.
   
   teamed interface(ens19 & ens20) ip: 10.0.0.103
   
	
##### Iscii Target: server2.rhce.lab
   Should have 2 interfaces and two hard disks
   teamed interfaces ip: 10.0.0.104

TOC
====
* [Reset Servers](#Reset-Servers)
* [RHCE Tasks](#RHCE-Tasks)


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


#### Make sure SELinux is in enforcing mode
Point both servers to the ipa server to use as a time server

Mount the Centos disc to use as a repo


##### Server1 Apache
Team the two available interfaces to use active backup with ip: 10.0.0.103/24 dns:10.0.0.102

Install httpd and create a Virtual Host that listens on 10.0.0.103 port 5555. alice is the admin the name is vhost2.rhce.lab and the alias vhost2 with a combined log file called alice.log and an error called alice_error.log.
The document root should be /srv/web/alice and should make alice login with a password.  No one else can access it. Put an index.html file in it with some stuff. 
Log the traffic with a prefix of HTTP_5555. Make sure the teamed interface uses the dmz also ensure any requests made to the server on port 80 from 10.0.0.103 are redirected to port 5555 and are routed through the dmz zone.

Create a secure Virtual Host that listens on port 9997 using the dns name dynamic.rhce.lab and only allows members of the apacheusers group to access it except for alice but put alice in the apacheusers group. Enforce passwords. Deploy a cgi script from this vhost from /srv/web/group/cgi-bin
/srv/web/group should be the document root. Forward traffic on port 443 to 9997 
Ensure SSL is used with a self signed cert. 

 


##### Server 2 SSH
Forward traffic for 10.0.0.104 on port 80 to 10.0.0.103:5555

Configure two interfaces to make a teamed interface for activebackup ip 10.0.0.104(Don't give it a gateway and manually configure its routes) on the private zone.

Configure SSH to run on port 2222 and log access to the server at 3 logs per minute.




##### LDAP
Join the two servers to the ipa server for user authentication



##### DNS
Configure server1 as a caching nameserver that listens on the teamed interface(10.0.0.103) and allows connections from the 10.0.0.0 subnet forward recursive queries to the ipa server(10.0.0.102). The rhce.lab zone is excluded from DNSSEC



##### Null Mail Server
Configure server1 to be a null client that forwards messages to the ipa server(10.0.0.102)



##### Iscsi
Server2 will be the target

On server1 change the intiator name to 2019-12.lab.rhce:init1


##### Server2
Create a block backstore named block1 using a volume group named vg_target and an lvm named lv_target(Make a partition and put it on that)
Create a fileio backstore named file1 of 100M in /root/iscsi_file with caching disabled

Create an IQN called server1
In this IQN create 2 LUN's using the block1 and file1 backstores
Add an acl for server1
Add a portal for the 10.0.0.103 ip
Use CHAP authentication userid=server1 password=server1

##### Server1
Log into the target created on server2
Mount file1 persistently at /mnt/iscsi_file
Create an lvm called lv_iscsi with 1G of space and xfs filesystem on block1(partiton and create a vg on block1) and mount persistently at /mnt/iscsi_block




##### Kerberos
Join both servers to the ipa server using Kerberos (The keytabs are in /var/ftp/pub/server{1,2} on the ipa server)
Use alice or paul from the ldap server and try to get a Kereberos ticket password is password
SSH using kerberos to one of the servers




##### NFS
###### Server2 will be the NFS server 
The kerberos nfs dir will be /srv/nfs/sec
The group nfs dir will be /srv/nfs/group

Create a group called nfsgroup and ensure all files in the /srv/nfs/group share are rw for the group and only file owners can delete files
Change ownership of the nfs/sec share to alice

##### Server1
Mount the nfs/sec share persistently at /mnt/nfs/sec
Mount nfs/group with autofs /mnt/nfs/group

##### SMB Shares
On Server2 create the directory /srv/smb/group
Create a group called smbgroup that can use the smb/group share and two samba users named john and nance. Put john in the smbgroup
Set the passwords to password
Configure a samaba share on smb/group called share that only allows 10.0.0.0/24 and localhost connections and is owned by the smbgroup.  Users should be able to collaborate but only file owners should be able to remove files. smbgroup can read and write nance can only read. Mount with nance as a multiuser share  
mount the group share persistently at /mnt/shares/group using a file (/root/smbnance.txt) and autofs

Test sharing home dirs, mount on server1 at /mnt/home




##### MariaDB On Server2
Install Maria DB and ensure it is secure.  Use password for the root password. Set Mariadb to listen on port 1111
Change the data directory for MariaDB to /mariadb
Create a database named rhce 

Create a table named users with values: ID(int) should auto increment, name(varchar), age (int) and set the ID as the primary key
Insert some data into the table for two users Paul and Alice.

Create a user john that has all permissions on the rhce database from any host
Create a user jeff that has Insert, Update, Delete, and Select on the users table

Backup the database to a gzipped file called rhce.sql.gz and a regular file called rhce.sql
Setup a firewall rule that allows server1 access to the rhce database on port 1111. No other servers should be allowed to connect.


Write a bash script that takes a directory name as an argument and finds files in the directory that are older than 30 days and tars them into a file named {the current date in mm/dd/yy format}.tar.
If no argument is passed print a usage string that explains how to use the script.

##### Other stuff
Install sysstat and mess around with it.
Delete the databse you made from above and import the backup.


