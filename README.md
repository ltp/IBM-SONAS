## NAME

IBM::SONAS - Perl API to IBM SONAS CLI

## SYNOPSIS

IBM::SONAS is a Perl API to IBM SONAS CLI.

	use IBM::SONAS;

	# Create an IBM::SONAS object

	my $ibm = IBM::SONAS->new(
				user     => 'admin',
				host     => 'my-sonas.company.com',
				key_path => '/path/to/my/.ssh/private_key'
		) or die "Couldn't create object! $!\n";

## METHODS

### new ( %ARGS )

	my $ibm = IBM::SONAS->new(      
				user     => 'admin',
				host     => 'my-sonas.company.com',
				key_path => '/path/to/my/.ssh/private_key'
		) or die "Couldn't create object! $!\n";

Constructor - creates a new IBM::SONAS object.  This method accepts three 
mandatory parameters and one optional parameter, the three mandatory 
parameters are:

- user

    The username of the user with which to connect to the device.

- host

    The hostname or IP address of the device to which we are connecting.

- key\_path

    Either a relative or fully qualified path to the private ssh key valid for the
    user name and device to which we are connecting.  Please note that the 
    executing user must have read permission to this key.

### disk ( $id ) 

        # Get the disk named "system_vol_00" as an 
	# IBM::StorageSystem::Disk object

        my $disk = $ibm->disk(system_vol_00);
        
        # Print the disk status

        print $disk->status;

        # Alternately

        print $ibm->disk(system_vol_00)->status;

Returns a [IBM::StorageSystem::Disk](https://metacpan.org/pod/IBM::StorageSystem::Disk) object representing the disk specified 
by the value of the id parameter, which should be a valid disk name in the 
target system.

__Note__ that this is a caching method and that a previously retrieved 
[IBM::StorageSystem::Array](https://metacpan.org/pod/IBM::StorageSystem::Array) object will be returned if one has been cached 
from previous invocations.

### get\_disk( $id )

This is a functionally equivalent non-caching implementation of the __disk__ 
method.

### get\_disks

        # Print a listing of all disks in the target system including their 
	# name, the assigned pool and status

        printf( "%-20s%-20s%-20s\n", 
		"Name", 
		"Pool", 
		"Status" 
	);
        printf( "%-20s%-20s%-20s\n", 
		"-----", 
		"------", 
		"-------" 
	);

        foreach my $disk ( $ibm->get_disks ) { 
		printf( "%-20s%-20s%-20s\n", 
			$disk->name, 
			$disk->pool, 
			$disk->status 
		) 
	}

        # Prints something like:
        #
        # Name                Pool                Status              
        # -----               ------              -------             
        # silver_vol_00       silver              ready               
        # silver_vol_01       silver              ready               
        # silver_vol_02       silver              ready    
        # ... etc.

Returns an array of [IBM::StorageSystem::Disk](https://metacpan.org/pod/IBM::StorageSystem::Disk) objects representing all disks 
in the target system.

### get\_exports

        # Print a listing of all configured exports containing the export name,
	# the export path, the export protocol and the export status.

        printf( "%-20s%-40s%-10s%-10s\n", 
		'Name', 
		'Path', 
		'Protocol', 
		'Active' 
	);

        foreach my $export ( $ibm->get_exports ) { 
                print '-'x55,"\n";
                printf( "%-20s%-20s%-10s%-10s\n", 
			$export->name, 
			$export->path, 
			$export->protocol, 
			$export->active 
		)
        }

        # Prints something like:
        #
        #Name                Path                Protocol  Active    
        # ------------------------------------------------------
        # homes_root          /ibm/fs1/homes      NFS       true      
        # ------------------------------------------------------
        # shares_root         /ibm/fs1/shares     NFS       true      
        # -------------------------------------------------------
        # test                /ibm/fs1/test       CIFS      true      
        # -------------------------------------------------------
        # ... etc.

Returns all configured exports on the target system as an array of 
[IBM::StorageSystem::Export](https://metacpan.org/pod/IBM::StorageSystem::Export) objects.

### filesystem( $filesystem\_name )

        # Print the block size of file system 'fs1'

        print $ibm->filesystem(fs1)->block_size;
        
        # Get the file system 'fs2' as a IBM::StorageSystem::FileSystem object

        my $fs = $ibm->filesystem(fs2);

        # Print the mount point of this file system

        print "fs2 mount point: " . $fs->mount_point . "\n";

        # Call a function if inode usage on file system 'fs2' exceeds 90% of 
	# maximum allocation.

        monitoring_alert( 
		'Inode allocation > 90% on '.$filesystem->device_name 
	) if ( ( ( $fs->inodes / $fs->max_inodes ) * 100 ) > 90 );

Returns the file system specified by the value of the named parameter as a 
[IBM::StorageSystem::FileSystem](https://metacpan.org/pod/IBM::StorageSystem::FileSystem) object.

Note that this is a caching method and a cached object will be retrieved if 
one exists,  If you require a non-cached object, then please use the 
__get\_filesystem__ method.

### get\_filesystem( $filesystem\_name )

This is a non-caching functionally equivalent implementation of the 
__filesystem__ method.  Use this method if you require the file system 
information to be retrieved directly from the target system rather than cache.

### get\_filesystems

        # Do the same for all file systems
        map { 
		monitoring_alert( 'Inode allocation > 90% on '.$_->device_name ) 
	} grep { 
		( ( ( $_->inodes / $_->max_inodes ) * 100 ) > 90 ) 
	} $ibm->get_filesystems;

Returns an array of [IBM::StorageSystem:FileSystem](https://metacpan.org/pod/IBM::StorageSystem:FileSystem) objects representing all 
configured file systems on the target system.

### get\_healths

        # Simple one-liner to print the sensor status and value for any error 
	# conditions.

        map { 
		print join ' -> ', ( $_->sensor, $_->value."\n" ) 
	} 
        grep { 
		$_->status =~ /ERROR/ 
	} $ibm->get_healths;

        # e.g.
        # CLUSTER -> Alert found in component cluster
        # MDISK -> Alert found in component mdisk
        # NODE -> Alert found in component node

Returns an array of [IBM::StorageSystem::Health](https://metacpan.org/pod/IBM::StorageSystem::Health) objects representative of 
all health sensors on the target system.

### interface ( $id )

        # Get interface ethX0 on management node mgmt001st001 as an 
	# IBM::StorageSystem::Interface object

	my $interface = $ibm->node('mgmt001st001')->interface('ethX0');

        # Print the interface status

        print $interface->up_or_down;

        # Print the interface status

        print $interface->speed;

        # Alternately;

        print $ibm->interface('mgmt001st001:ethX0')->speed;

Returns the interface identified by the value of the id parameter as an 
[IBM::StorageSystem::Interface](https://metacpan.org/pod/IBM::StorageSystem::Interface) object.

The value of the id parameter must be a valid node and interface name 
separated by a colon.

__Note__ that this method implements caching and a cached object will be 
returned shoudl one be present. If you require a non-cached object then please 
use the __get\_iogroup__ method.

### get\_interface( $id )

This is a functionally equivalent non-caching implementation of the 
__interface__ method.

### get\_interfaces

        # Print a list of all interfaces, their status, speed and role
        
        foreach my $interface ( $ibm->get_interfaces ) {
                print "Interface: " . $interface->interface . "\n";
                print "\tStatus: " . $interface->up_or_down . "\n";
                print "\tSpeed: " . $interface->speed . "\n";
                print "\tRole: " . $interface->isubordinate_or_master 
				 . "\n----------\n";
        }
        
	# Prints somethign like
	#
	# Interface: ethX0
	# 	Status: UP
	#	Speed: 2000
	#	Role: MASTER
	# ----------
	# Interface: ethXsl0_0
	# 	Status: UP
	#	Speed: 1000
	#	Role: SLAVE
	# ----------
	# etc.

Returns an array of [IBM::StorageSystem::Interface](https://metacpan.org/pod/IBM::StorageSystem::Interface) objects representing all 
interfaces on the target system.

### mount( $mount )

        # Print mount status of file system fs1

        print "Mount status: " . $ibm->mount(fs1) . "\n";

        # Print only those file system that are not mounted

        map { print $_->file_system . " is not mounted.\n" }
        grep { $_->mount_status ne 'mounted' }
        $ibm->get_mounts;

Returns the mount identified by the mount parameter as a 
[IBM::StorageSystem::Mount](https://metacpan.org/pod/IBM::StorageSystem::Mount) object.

__Note__ that this method implements caching and a cached object will be 
returned should one be present. If you require a non-cached object then please 
use the __get\_iogroup__ method.

### get\_mount( $mount )

This is a functionally equivalent non-caching implementation of the __mount__ 
method.

### get\_mounts

This method returns an array of [IBM::StorageSystem::Mount](https://metacpan.org/pod/IBM::StorageSystem::Mount) objects 
representing all mounts on the target system.

### node( $node )

        # Get node mgmt001st001 as an IBM::StorageSystem::Node object

        my $node = $ibm->node( mgmt001st001 );
        
        # Print the node description

        print "Description: " . $node->description . "\n";

        # Prints something like: "Description: active management node"
        # Or alternately;

        print "Description: " . $ibm->node( mgmt001st001 )->description . "\n";



Returns the node identified by the value of the node parameter as a 
[IBM::StorageSystem::Node](https://metacpan.org/pod/IBM::StorageSystem::Node) object.

__Note__ that this method implements caching and that a cached object will be 
returned if one is available. If you require a non-cached object, then please 
use the non-caching __get\_node__ method.

### get\_node( $node )

This is a functionally equivalent non-caching implementation of the __node__ 
method.

### get\_nodes

        # Print the GPFS and CTDB stati of all nodes

        foreach my $node ( $ibm->get_nodes ) {
                print "GPFS status: " . $node->GPFS_status 
		      . " - CTDB status: " . $node->CTDB_status . "\n"
        }

Returns an array of [IBM::StorageSystem::Node](https://metacpan.org/pod/IBM::StorageSystem::Node) objects representing all 
configured nodes on the target system.

### get\_quotas 

        # Call a function to send a quota warning email for any quotas where 
	# the current usage exceeds 85% of the quota usage hard limit.

        map  { send_quota_warning_email( $_ )           }
        grep { ( $_->used_usage / $_->HL_usage ) > 0.85 }
        grep { $_->name ne 'root'                       }
        grep { $_->type eq 'U'                          } $ibm->get_quotas;

Returns all quotas defined on the target system as an array of 
[IBM::StorageSystem::Quota](https://metacpan.org/pod/IBM::StorageSystem::Quota) objects.

### replication( $eventlog\_id )

Returns the replication event identified by the eventlog\_id parameter as an 
[IBM::StorageSystem::Replication](https://metacpan.org/pod/IBM::StorageSystem::Replication) object.

__Note__ that this method implements caching and that a cached object will be 
returned if one is available. If you require a non-cached object, then please 
use the non-caching __get\_node__ method.

### get\_replication( $eventlog\_id )

This is a functionally equivalent non-caching implementation of the 
__replication__ method.

### get\_replications

        use Date::Calc qw(date_to_Time Today_and_Now);

        # Generate an alert for any replication errors in the last six hours

        foreach my $task ( $ibm->get_replications ) {

                if ( $repl->status eq 'ERROR' 
			and ( Date_to_Time( Today_and_Now ) 
                     - ( Date_to_Time( 
					split /-| |\./, $repl->time 
				) ) ) > 21_600 
		) {
                        alert( "Replication failure for filesystem " 
				. $repl->filesystem 
				. " - log ID: " . $repl->log_id . 
			     )
                }

        }

Returns all asynchornous replication tasks as an array of 
[IBM::StorageSystem::Replication](https://metacpan.org/pod/IBM::StorageSystem::Replication) objects.

### service( $service )

        # Print the enabled status of the NFS service

        print $ibm->service(NFS)->enabled;

        # Print the configured and enabled status of all services

        printf( "%-20s%-20s%-20s\n", 'Service', 'Configured', 'Active' );

        map { 
		printf( "%-20s%-20s%-20s\n", 
			$_->name, 
			$_->configured, 
			$_->active ) 
	} $ibm->get_services;

Returns a [IBM::StorageSystem::Service](https://metacpan.org/pod/IBM::StorageSystem::Service) object representing the service 
identified by the value of the service parameter.

__Note__ that this method implements caching and that a cached object will be 
returned if one is available. If you require a non-cached object, then please 
use the non-caching __get\_node__ method.

### get\_service( $service )

This is a functionally equivalent non-caching implementation of the 
__service__ method.

### get\_services

Returns an array of [IBM::StorageSystem::Service](https://metacpan.org/pod/IBM::StorageSystem::Service) objects representing all 
configured services on the target system.

### task( $task )

        # Print the status of the SNAPSHOTS task

        my $snapshots = $ibm->task( SNAPSHOTS );
        print "Status: " . $snapshots->status . "\n";

        # Alternately

        print "Status: " . $ibm->task( SNAPSHOTS )->status . "\n";

Return the task identified by the value of the task parameter as an 
[IBM::StorageSystem::Task](https://metacpan.org/pod/IBM::StorageSystem::Task) object.

__Note__ that this method implements caching and that a cached object will be 
returned if one is available.  If you require a non-cached object, then please 
use the non-caching __get\_node__ method.

### get\_task( $task )

This is a functionally equivalent non-caching implementation of the __task__ 
method.

### get\_tasks

        # Call an alert function for any tasks that are not in an OK state

        map { alert( $_->name ) } grep { $_->status ne 'OK' } $ibm->get_tasks;

Returns an array of [IBM::StorageSystem::Task](https://metacpan.org/pod/IBM::StorageSystem::Task) objects representing all tasks 
on the target system.

## AUTHOR

Luke Poskitt, `<ltp at cpan.org>`

## BUGS

Please report any bugs or feature requests to `bug-ibm-sonas at rt.cpan.org`, 
or through the web interface at 
[http://rt.cpan.org/NoAuth/ReportBug.html?Queue=IBM-SONAS](http://rt.cpan.org/NoAuth/ReportBug.html?Queue=IBM-SONAS).  I will be 
notified, and then you'll automatically be notified of progress on your bug as 
I make changes.

## SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc IBM::SONAS



You can also look for information at:

- RT: CPAN's request tracker (report bugs here)

    [http://rt.cpan.org/NoAuth/Bugs.html?Dist=IBM-SONAS](http://rt.cpan.org/NoAuth/Bugs.html?Dist=IBM-SONAS)

- AnnoCPAN: Annotated CPAN documentation

    [http://annocpan.org/dist/IBM-SONAS](http://annocpan.org/dist/IBM-SONAS)

- CPAN Ratings

    [http://cpanratings.perl.org/d/IBM-SONAS](http://cpanratings.perl.org/d/IBM-SONAS)

- Search CPAN

    [http://search.cpan.org/dist/IBM-SONAS/](http://search.cpan.org/dist/IBM-SONAS/)


## LICENSE AND COPYRIGHT

Copyright 2013 Luke Poskitt.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


