RHCE TEST PREP
======
This is meant to study for the RHCE by setting up some of the requirments to practice exam objectives.

The reset.sh script will reset your server.  It will remove network connections, reset firewalld, and clear out kerberos configs.  Run ./reset.sh -h to view options.  If you run it aginst the kerberos server or you have kerberos running on the same server you're using to practice it will break it.  Running the Ansible playbook again should fix it but for that reason it may be hard to practice setting up a kerberos client if the kerberos server is on the server you're practicing on.

Kerberos Setup
------
#### Before you Run the Playbook
* The Kerberos services aren't started by ansible beacuse passwords and principals need to be setup on the server.
* Hostnames and fqdn's are set by ansible.  Configure group_vars/all domain for the domain and the ansible_hostname in the inventory file for the hostname.
* In ansible/group_vars/kdc_server change ports if you want.
* The KDC server is defined by the hosts file under [kdc_server].  Define the host you want to be the Kerberos server here.
    
Run playbook:
    
    ansible-playbook rhce_prep.yml

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

LDAP Setup
------
#### Before you Run the Playbook
* Configure the LDAP server in the hosts file.  In the example we're using the KDC is the LDAP server.
* Set the ldap port in group_vars/ldap_server if you want it to be something else.
* An encrypted vault password needs to be set to add some of the ldap stuff.  Replace the vault value in
  group_vars/ldap_server or put it in there in plaintext if you don't care.
* Create users in roles/ldap_server/vars/main.yml in the same way the example ldapusers are set.
* Turns out OpenLDAP is picky about ldif files and white space hence the overly complicated file to add users.  This will compare the output of getent passwd to the list of users you want to add.  If the user already exists it will be skipped to stop LDAP errors.  If you can't use getent for some reason to pull a user list switch the command at the top of roles/ldap_server/main.yml to pull your user list.
* TODO: Add templates for creating groups on ldap server

Run:

    slappasswd -h {SSHA} -s your password
    Save the output of this command and put it in the /templates/db.ldif.j2
    file at the bottom where it says olcRootPw

Run:

    ansible-playbook ldap.yml --ask-vault-pass
