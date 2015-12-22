#restore.pl
#Fri 09 Oct 2015 06:37:12 AM UTC
use strict;
use warnings;
use GlobalVar;

my @cmds = (
	'rm -f '.$vdisk_root_path.$disk_name_prefix.'*',
	'rm '.$scst_config_file,
	"cp $scst_config_backup $scst_config_file",
	'scstadmin --clear_config --force',
	'scstadmin -config '.$scst_config_file
);

for(my $i = 0; $i<scalar @cmds; $i++){
	system($cmds[$i]);
}
