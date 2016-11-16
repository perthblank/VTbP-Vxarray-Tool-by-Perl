# Vxarray Tool by Perl

### Description
These scripts are designed to automate the process of vxarray and give management of virtual disks spliting and deployment, base on iSCSI, vxarray and Perl
	

### Prepare
* A redhat 6.4 system as virtual disk server
* Install vxarray and start SCST
* Mount disk to vxdisk path (/vdisks default)
* Install Expect for perl: 
 run `cpan` and enter `install Net::SSH::Expect` in `sudo` mode
* Enter this folder and run `perl backup.pl`
	

### Usage
```bash
$ perl main.pl [options and args] #choose one mode from following
```
* MODE 1: split and deploy disk
```bash
	-s disk_size
	-n disk_num
	[-t target_num] (default is 2, should be greater than 0)
	[
	-c client_addr1,client_addr2...
	-u user1,user2...
	-p password1,password2... (use ',' to split and no space)
	] #clients to deploy these disks,if not specified, just do disk split
	
	#sample: this will split the disks and deploy them on two clients
	perl main.pl -s 2G -n 10 -c x1.x2.11.2,x1.x2.11.2 -u root,root -p xxx,xxx
```
* MODE 2: remove remote deployment
```bash
	-r
	-c client_addr1,client_addr2...
	-u user1,user2...
	-p password1,password2... (use ',' to split and no space)
```
* MODE 3: remove local disks
```bash
	-q target1,target2,...
```

### Kernel files
* GlobalVar.pm # global variables include path and names of disk devices and targets
* ConfigSetter.pm # get and alter the config file
* DiskSpliter.pm # command to split disk and do refresh jobs
* Connector # connect the client and deploy disks
* main.pl # the entrance of this program

### Default configs
* vxdisk folder path: /vdisks/
* scst configuration file: /etc/scst.conf


### Debug & Test
* All the path and name settings can be fount in GlobalVal.pm
* backup.pl # backup the original scst.conf file, for restore usage (to $scst_config_backup)
* restore.pl # used to restore the splited disk (with $vdisk_root_path prefix)
* check.sh # check current vxdisks
	
### FAQ
	1. Cannot mount disk?
		Check if the disk is in use, formatting it if there's still error
	2. fallocate: Operation not supported?
		Check if the disk format is ext4
	3. Error: cannot add target
		Check if target_driver is iscsi (in scst.conf)
	4. Cannot recognize multi-path
		Make sure the target is the same
	5. What's more
		Donnot include '_' (underline) in naming

#### Ref
1. [http://docs.oracle.com/cd/E37934_01/html/E36727/iscsi-4.html](http://docs.oracle.com/cd/E37934_01/html/E36727/iscsi-4.html)

