#parsefile.pm
#Thu 08 Oct 2015 06:03:54 AM UTC

package ConfigSetter;

use strict;
use warnings;
use GlobalVar;
use Data::Dumper;

require Exporter;

use vars qw(@ISA @EXPORT @EXPORT_OK);
@ISA = qw(Exporter);

@EXPORT = qw(
		addDevice 
		addTarget
		removeTarget
		generate	
		parse
		);

my $line;
my $handler;
my %devices;
my $target_driver;
my %targets;

open (CONFIGFILE, $scst_config_file)||
	die("Could not open ",$scst_config_file," \n");

sub addDevice{
#(diskname, diskpath)

	my $dname = shift;
	my $dpath = shift;
	$devices{$dname} = $dpath;
	return 1;
}

sub addTarget{
#(targetname, target_disk_ref)
	my $tname = shift;
	my $tdisk_ref = shift;

	$targets{$tname} = $tdisk_ref;
	return 1;
}

sub writeline{
	print OUTFILE (shift @_) ."\n";
}

sub nextline{
	$line = <CONFIGFILE>;
}



sub generate{
	my $filename = "scst.conf";
	open(OUTFILE,">$filename") or die ("cannot write!\n");

	# write hander and devices
	writeline "HANDLER $handler {";
	foreach my $dname (sort keys %devices){
		writeline "\tDEVICE $dname {";
		writeline "\t\t filename ".$devices{$dname};
		writeline "\t}";
	}
	writeline "}";
	writeline "";
	writeline "";

	#write targes
	writeline "TARGET_DRIVER $target_driver {";
	writeline "\tenabled 1";
	foreach my $tname (keys %targets){
		writeline "\tTARGET $tname {";
		writeline "\t\tenabled 1";
		for(my $i=0; $i<scalar @{$targets{$tname}}; $i++){
			writeline "\t\tLUN $i ${$targets{$tname}}[$i]";	
		}
		writeline "\t}";
	}

	writeline "}";	

	close OUTFILE;

}

sub parseHANDLER{

	nextline(); #?
	
	while(1){
		if($line =~ m/DEVICE/){
			parseDEVICE();		
		}
		elsif($line =~ m/\}/){
			last;		
		}
		else{
			nextline();
		}
	}
}

sub parseDEVICE{
	while($line && $line !~ m/DEVICE\s+(\w+)/){
		nextline();
	}
	
	if(!$line){
		return;	
	}

	$line =~ m/DEVICE\s+(\w+)/;
	my $device = $1;

	my $count = 0;
	while($line && $line !~ m/filename\s+([\w\/]+)/){
		nextline();
	}

	$line =~ m/filename\s+([\w\/]+)/;
	my $path = $1;
 

	$devices{$device} = $path;	

	while($line !~ m/\}/){
		nextline();
	}
	nextline();

}

sub getPrefix{

	my $tname = shift;

	return substr $tname,0,length($tname)-1;
}

sub removeTarget{
	my $tname = shift;

	if(!defined($targets{$tname})){
		print "Cannot find target $tname\n";
		return;
	}

	for(my $i=0; $i<scalar @{$targets{$tname}}; $i++){
		delete $devices{${$targets{$tname}}[$i]};
	}

	#common prefix

	my $pre = getPrefix($tname);
	
	foreach my $tname2 (keys %targets){
		#delete multi-path
		if(getPrefix($tname2) eq $pre){
			delete $targets{$tname2};
		}
	}

	delete $targets{$tname};
	
}

sub parseTARGET_DRIVER{
	nextline();
		#print $line;
	while(1){
		if($line =~ m/TARGET\s+/){
			parseTARGET();	
		}	
		elsif($line =~ m/\}/){
			last;	
		}
		else{
			nextline();
		}
	}
}

sub parseTARGET{

	while($line && $line !~ m/TARGET\s+/){
		nextline();
	}

	if(!$line){
		return;	
	}
	
	$line =~ m/TARGET\s+([\w\.\-\:]+)/;
	#print $1,"\n"; #iqn. ...
	my $targetName = $1;

	my @LUNs;
	while(1){
		if($line =~ m/LUN\s+\w+\s+(\w+)/){
			push @LUNs, $1;	
	#		print $1,"\n"; #disk0 disk1 ...
		}
		if($line =~ m/\}/){
			nextline();
			last;	
		}
		nextline();
	}
	
	$targets{$1} = \@LUNs;
}



sub parse(){

	nextline();

	while($line){
	
		if($line =~ m/HANDLER\s+(\w+)/){
			#Get the handler
			$handler = $1;

			parseHANDLER();
		}
		
		if($line =~ m/TARGET_DRIVER\s+(\w+)/){
			$target_driver = $1;
		#	print "targetdriver: ",$target_driver,"\n";
			# print $line;

			parseTARGET_DRIVER();
		}
		
		nextline();
	}

}


