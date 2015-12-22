#globalVar.pm
#Thu 08 Oct 2015 06:14:59 AM UTC

package GlobalVar;
use strict;
use warnings;
require Exporter;
use vars qw(@ISA @EXPORT @EXPORT_OK);
@ISA = qw(Exporter);


@EXPORT = qw(
	$vdisk_root_path 
	$scst_config_file
	$scst_config_backup
	$output_cache

	$device_name_prefix
	$disk_name_prefix

	$target_name_prefix 
	$reserved_domain

	$default_target_num 

	$iscsi_port 

	shownget
	);


#path (and prefex) of vxdisk file
our $vdisk_root_path="/vdisks/";
#path of config file
our $scst_config_file="/etc/scst.conf";
#path of original backup
our $scst_config_backup="/etc/scst.conf.backup";

our $output_cache="scst.conf";
our $device_name_prefix="disk";
our $disk_name_prefix="testvdisk";
our $target_name_prefix = "ptgt";
our $reserved_domain="com.veritas";

our $default_target_num = 2;

our $iscsi_port = 3260;


sub shownget{

	print ">> ",shift,"\n";
	chomp(my $op = <STDIN>);
	return $op;

}

1;
