#splitCommand.pm
#Thu 08 Oct 2015 09:01:02 AM UTC

package DiskSpliter;

use strict;
use warnings;
require Exporter;
use GlobalVar;


use vars qw(@ISA @EXPORT @EXPORT_OK);
@ISA = qw(Exporter);

@EXPORT = qw{
	splitDisk
	refreshDiskConfig
};


sub splitDisk{
	my $path = shift;
	my $name = shift;
	my $size = shift;
	my $cmd = 'fallocate -l '.$size.' '.$path.$name;
	
	system($cmd);
}

sub refreshDiskConfig{
	my @cmd = (
		'scstadmin --clear_config --force',
		'rm -f '.$scst_config_file.'.old',
		'mv '.$scst_config_file.' '.$scst_config_file.'.old',
		'mv '.$output_cache.' '.$scst_config_file,
		'scstadmin -config '.$scst_config_file
	);

	for(my $i = 0; $i<scalar @cmd;$i++){
		system($cmd[$i]);	
	}

	my $disksref = shift;
	if(defined($disksref)){
		for(my $i = 0; $i < scalar @{ $disksref }; $i++){
			my $dname = $$disksref[$i];
			system("./emc.sh $dname");
		}
	}
}




