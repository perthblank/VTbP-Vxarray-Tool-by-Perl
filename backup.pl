#restore.pl
#Fri 09 Oct 2015 06:37:12 AM UTC
use strict;
use warnings;
use GlobalVar;

my @cmds = (
	"cp scst.conf.backup /etc/scst.conf.backup",
	"perl restore.pl"
);

for(my $i = 0; $i<scalar @cmds; $i++){
	system($cmds[$i]);
}
