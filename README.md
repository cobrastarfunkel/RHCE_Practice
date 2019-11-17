RHCE TEST PREP
======
This is meant to study for the RHCE by setting up some of the requirments to practice exam objectives.

The reset.sh script will reset your server.  It will remove network connections, reset firewalld, and clear out kerberos configs.  Run ./reset.sh -h to view options.  If you run it aginst the kerberos server or you have kerberos running on the same server you're using to practice it will break it.  Running the Ansible playbook again should fix it but for that reason it may be hard to practice setting up a kerberos client if the kerberos server is on the server you're practicing on.

Kerberos Setup
------
#### Before you Run the Playbook
* The Kerberos services aren't started by ansible beacuse passwords and principals need to be setup on the server.\
* Hostnames and fqdn's are set by ansible.  Configure group_vars/all domain for the domain and the ansible_hostname in the inventory file for the hostname.\
* In ansible/group_vars/kdc_server change ports if you want.\
* The KDC server is defined by the hosts file under [kdc_server].  Define the host you want to be the Kerberos server here.
    
#### Run playbook:
    
    ansible-playbook rhce_prep.yml

Login to Kerberos server and Run:

    kdb5_util create -s
    Create your password
        
    systemctl start {krb5kdc, kadmin}
    systemctl enable {krb5kdc, kadmin}
    
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
    ssh -k {kdc hostname }
