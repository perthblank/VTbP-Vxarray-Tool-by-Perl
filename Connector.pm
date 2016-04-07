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

$Expect::Log_Stdout = 1;
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
	
	my $cmd1 = 'svcadm enable network/iscsi/initiator';
	$exp->send("$cmd1\n") if ($exp->expect(undef,'#'));

	for(my $i = 0; $i < scalar @{ $targets }; $i++){
		my $cmd2 = 'iscsiadm add static-config '.$$targets[$i].','.$thisIP;
		$exp->send("$cmd2\n")if ($exp->expect(undef,'#'));
	}

	$cmd1 = 'iscsiadm modify discovery --static enable';
	$exp->send("$cmd1\n") if ($exp->expect(undef,'#'));
	
	$cmd1 = 'devfsadm -i iscsi';
	$exp->send("$cmd1\n") if ($exp->expect(undef,'#'));

}

sub rmSunOS{
	my $cmd = 'for i in `vxdisk list|grep -v DEVICE|awk \'{print $1}\'`; do vxdisk rm $i;done';
	$exp->send("$cmd\n") if ($exp->expect(undef,'#'));
	
	$cmd = 'for i in `iscsiadm list static-config| grep Target:  |awk \'{print $4}\'`; do iscsiadm remove static-config $i;done';
	$exp->send("$cmd\n") if ($exp->expect(undef,'#'));
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
	}

}

sub rmLinux{
	my $thisIP = get_ip_address("eth0");
	my $cmd = 'for i in `iscsiadm -m session -P 3 | grep Target:  |awk \'{print $2}\'`; do iscsiadm -m node -T $i -p '.$thisIP.':3260 --logout;done';
	$exp->send("$cmd\n") if ($exp->expect(undef,'#'));
}

sub doConnect{
	my ($host, $usr, $pwd, $targets) = @_;

	$exp->log_file("output_log","w");

	$exp = Expect->spawn("ssh -l $usr $host");

	$exp->expect(undef,
				[
					qr/password:/i,
					sub{
						my $self = shift;
						$self->send("$pwd\n");
					}
				]
				,[
					qr/yes\/no/i,
					sub{
						my $self = shift;
						$self->send("yes\n");
						$self->expect(undef,
								[
									qr/password:/i,
									sub{
										my $self = shift;
										$self->send("$pwd\n");
									}
								],
						);
						
					}
				],
	);

	if ($exp->expect(undef,'#')){
		$exp->send("uname\n");
	}

	$exp->expect(undef,
				[
					'Linux',
					sub{
						if($targets){
							setLinux($targets);
						}
						else{
							rmLinux();	
						}
					}
				]
				,[
					'SunOS',
					sub{
						if($targets){
							setSunOS($targets);
						}
						else{
							rmSunOS();
						}

					}
				],
	);

	$exp->send("exit\n") if ($exp->expect(undef,'#')); 
	$exp->log_file(undef);

	print "\n Work finished\n";

}


1;
