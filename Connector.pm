#connector.pm
#Thu 08 Oct 2015 09:49:47 AM UTC
#use strict;  for socket ussage

package Connector;

use warnings;
use Net::SSH::Expect;
use Socket; # used to get ip addr
use GlobalVar;
require 'sys/ioctl.ph';


require Exporter;
use vars qw(@ISA @EXPORT @EXPORT_OK);
@ISA = qw(Exporter);


@EXPORT = qw(
	doConnect
	get_ip_address
);

	my $host = '10.200.110.174';
	my $pwd = 'root';
	my $usr = 'root';

$Expect::LogStdout = 1;
my $exp = Expect->new;



sub get_ip_address($) {
     my $pack = pack("a*", shift);
     my $socket;
	 socket($socket, AF_INET, SOCK_DGRAM, 0);
     ioctl($socket, SIOCGIFADDR(), $pack);
     return inet_ntoa(substr($pack,20,4));
};


sub setSunOS{
	my $targets = shift; #ref to targets name array
	print "SunOS system\n";
	my $thisIP = get_ip_address("eth0");
	
	$exp->send('svcadm enable network/iscsi/initiator');

	for(my $i = 0; $i < scalar @{ $targets }; $i++){
		my $cmd2 = 'iscsiadm add static-config '.$$targets[$i].','.$thisIP;
	}
	$exp->send('iscsiadm modify discovery --static enable');
	$exp->send('devfsadm -i iscsi');

}


sub setLinux{
	my $targets = shift; #ref to targets name array
	
	print "Linux Server\n";

	my $thisIP = get_ip_address("eth0");
	my $cmd1 = 'iscsiadm -m discovery -t sendtargets -p '.$thisIP.':'.$iscsi_port;
	$exp->send("$cmd1\n") if ($exp->expect(undef,'#'));

	for(my $i = 0; $i < scalar @{ $targets }; $i++){
		my $cmd2 = 'iscsiadm -m node -T '.$$targets[$i].
				' -p '.$thisIP.':'.$iscsi_port.' --login';

		$exp->send("$cmd2\n")if ($exp->expect(undef,'#'));
#print("$cmd2\n");

	}

}

sub doConnect{
	my ($host, $usr, $pwd, $targets) = @_;

	$exp = Expect->spawn("ssh -l root $host");
	$exp->log_file("output_log","w");
	$exp->expect(undef,
				[
					qr/password:/i,
					sub{
						my $self = shift;
						$self->send("$pwd\n");
					}
				]
				,[
					'connecting (yes/no)',
					sub{
						my $self = shift;
						$self->send("yes\n");
					}
				],
					
	);

	$exp->send("uptime\n") if ($exp->expect(undef,'#')); 
	$exp->send("uname\n") if ($exp->expect(undef,'#')); 

#setLinux($targets) if $exp->expect(1,'Linux');
	while(1){
		if($exp->expect(1,'Linux')){
			setLinux($targets);
			last;
		}
		if($exp->expect(1,'SunOS')){
			setSunOS($targets);
			last;
		}
	
	}

	$exp->send("exit\n") if ($exp->expect(undef,'#')); 
	$exp->log_file(undef);
	

}


1;
