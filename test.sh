# test.sh
#Fri 09 Oct 2015 06:09:55 AM UTC
#!/bin/bash

perl restore.pl
perl main.pl -s 2G -n 3 -c 10.200.110.174 -u root -p root
#perl main.pl -s 2G -n 3 
