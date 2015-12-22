#main.pl
#Thu 08 Oct 2015 06:00:04 AM UTC
##!/opt/VRTSperl/bin/perl
use strict;
use warnings;
use Getopt::Std;
use Switch;

use ConfigSetter;
use GlobalVar;
use DiskSpliter;
use Connector;

my $disk_size;
my $disk_num;
my $target_num = $default_target_num;
my $client_addr;
my $client_usr;
my $client_pwd;

my @targets;

sub init{
	parse();
}

sub getArgv{
	
	my %opts;
	getopts('s:n:t:c:u:p:',\%opts);
	foreach my $k ( keys %opts){
		switch($k){
			case "s"{
				print "get s ".$opts{$k}."\n";
				$disk_size = $opts{$k};	
			}	
			case "n"{
				print "get n ".$opts{$k}."\n";
				$disk_num = $opts{$k};	
			}
			case "t"{
				print "get t ".$opts{$k}."\n";
				$target_num = $opts{$k};	
			}
			case "c"{
				print "get c ".$opts{$k}."\n";
				$client_addr = $opts{$k};	
			}
			case "u"{
				print "get u ".$opts{$k}."\n";
				$client_usr = $opts{$k};	
			}
			case "p"{
				print "get pwd ".$opts{$k}."\n";
				$client_pwd = $opts{$k};	
			}
			else{
				print "invalid option $k\n";
				exit 1;
			}
		
		}
	}

	if(
		!defined($disk_size)|| !defined($disk_num) 
	){
		print "argument invalid!\n";
		exit 1;
	}

	return 1;

}


my @disks;
sub doSplit{
	my $timeid = time();	
	my ($sec,$min,$hour,$day,$mon,$year,$wday,$yday,$isdst) = localtime();   
	$year += 1900;   
	$mon++;
 	my $monthStr = "$year-$mon";   
	
	for(my $i = 0; $i<$disk_num; $i++){
		my $dname = $device_name_prefix.$timeid.$i;
		my $filename = $disk_name_prefix.$timeid.$i;
		my $dpath = $vdisk_root_path;
		addDevice($dname,$dpath.$filename);
		splitDisk($dpath,$filename,$disk_size);	
		push @disks,$dname;	
		print $dpath."\n";
	}

	for(my $i = 0; $i<$target_num; $i++){
		my $tname = "iqn.".$monthStr.'.'.$reserved_domain.':'
				.$target_name_prefix.$timeid.$i; 
		addTarget($tname,\@disks);	
		print "$tname\n";
		push @targets, $tname;
	}

}


sub deployClient{
	print " $client_addr\n";
	print " $client_usr\n";

	my @addrs = split(/,/,$client_addr);
	my @usrs = split(/,/,$client_usr);
	my @pwds = split(/,/,$client_pwd);

	if(scalar @addrs != scalar @usrs || scalar @addrs != scalar @pwds){
		print "invalid client content\n";
		exit 1;
	}

	for(my $i = 0; $i<scalar @addrs; $i++){
		doConnect($addrs[$i],$usrs[$i],$pwds[$i],\@targets);
	}
}

sub printTargets{

	print "\n=====================================\n";
	print "Targets:\n";
	for(my $i = 0; $i<scalar @targets; $i++){
		print @targets[$i],"\n";
	}
	print "Server IP:\n";
	print get_ip_address("eth0");
	print "\n=====================================\n";

}


sub main{
	getArgv();
	init();
	doSplit();
	generate();
	refreshDiskConfig(\@disks);

	printTargets();


	if(
		defined($client_addr)&& 
		defined($client_usr)&& defined($client_pwd))
	{
		deployClient();
	}
	
}


main();
