# restore.sh
#Thu 08 Oct 2015 09:42:26 AM UTC
#!/bin/bash

rm -f /vdisks/test*
rm /etc/scst.conf
cp /etc/scst.conf.old2 /etc/scst.conf
scstadmin --clear_config --force 
scstadmin -config /etc/scst.conf
