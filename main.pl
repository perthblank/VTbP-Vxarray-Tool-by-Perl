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
my $targets_for_remove;


my $DO_SPLIT = 0;
my $RM_DEPLOY = 1;
my $RM_LOCAL = 2;

my $MODE = -1;

my @targets;

sub init{
	parse();
}

sub setMode{
	my $t = shift;
	if($MODE != -1 && $MODE != $t){
		print "Invalid options\n";
		exit 1;
	}
	$MODE = $t;
}

sub getArgv{
	
	my %opts;
	getopts('s:n:t:c:u:p:rq:',\%opts);
	foreach my $k ( keys %opts){
		switch($k){
			case "s"{
				setMode($DO_SPLIT);
				$disk_size = $opts{$k};	
			}	
			case "n"{
				$disk_num = $opts{$k};	
				setMode($DO_SPLIT);
			}
			case "t"{
				$target_num = $opts{$k};	
				setMode($DO_SPLIT);
			}
			case "c"{
				$client_addr = $opts{$k};	
			}
			case "u"{
				$client_usr = $opts{$k};	
			}
			case "p"{
				$client_pwd = $opts{$k};	
			}
			case "r"{
				print "remove deployment\n";
				setMode($RM_DEPLOY);
			}
			case "q"{
				print "remove local disks\n";	
				$targets_for_remove = $opts{$k};
				setMode($RM_LOCAL);
			}
			else{
				print "invalid option $k\n";
				exit 1;
			}
		
		}
	}

}


my @disks;
sub doSplit{
	my $timeid = time();	
	my ($sec,$min,$hour,$day,$mon,$year,$wday,$yday,$isdst) = localtime();   
	$year += 1900;   
	$mon++;
	my $monthStr;
	if($mon<10){
 		$monthStr= "$year-0$mon";   
	}
	else{
 		$monthStr= "$year-$mon";   
	}
	
	for(my $i = 0; $i<$disk_num; $i++){
		my $dname = $device_name_prefix.$timeid.$i;
		my $filename = $disk_name_prefix.$timeid.$i;
		my $dpath = $vdisk_root_path;
		addDevice($dname,$dpath.$filename);
		splitDisk($dpath,$filename,$disk_size);	
		push @disks,$dname;	
		print "new disk: $dname\n";
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

	my @addrs = split(/,/,$client_addr);
	my @usrs = split(/,/,$client_usr);
	my @pwds = split(/,/,$client_pwd);

	if(scalar @addrs != scalar @usrs || scalar @addrs != scalar @pwds){
		print "invalid client content\n";
		exit 1;
	}

	if($MODE == 1){
		for(my $i = 0; $i<scalar @addrs; $i++){
			print "removing vdisk of $addrs[$i],$usrs[$i],$pwds[$i]...\n";
			doConnect($addrs[$i],$usrs[$i],$pwds[$i]);
		}
	}
	else{
		for(my $i = 0; $i<scalar @addrs; $i++){
			print "deploying $addrs[$i],$usrs[$i],$pwds[$i]...\n";
			doConnect($addrs[$i],$usrs[$i],$pwds[$i],\@targets);
		}
	}
}


sub printTargets{

	print "\n=====================================\n";
	print "Targets:\n";
	for(my $i = 0; $i<scalar @targets; $i++){
		print $targets[$i],"\n";
	}
	print "Server IP:\n";
	print get_ip_address("eth0");
	print "\n=====================================\n";

}

sub splitNDeploy{

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

sub removeLocal{

	init();

	my @tnames = split(/,/,$targets_for_remove);
	for(my $i = 0; $i<scalar @tnames; $i++){
		removeTarget($tnames[$i]);
	}

	generate();

	refreshDiskConfig();
}

sub main{

	getArgv();
	
	switch($MODE){

		case 0{

			if(
				!defined($disk_size)|| !defined($disk_num) 
			){
				print "argument invalid!\n";
				exit 1;
			}

			splitNDeploy();

		}
		case 1{
			if(
				!defined($client_addr) || 
				!defined($client_usr) || !defined($client_pwd))
			{		
				print "not enough parameter for removing\n";	
				exit 1;
			}
			
			deployClient();
		}	
		case 2{
			if(!defined($targets_for_remove))
			{
				print "not enough parameter for removing\n";	
				exit 1;
			}
			removeLocal();	
		}
		else {
			print "argument invalid!\n";
			exit 1;
		}

	}

}


main();
