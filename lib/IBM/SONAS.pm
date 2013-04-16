package IBM::SONAS;

use strict;
use warnings;

use IBM::StorageSystem;
use Carp qw(croak);

our $VERSION = '0.021';

our @METHODS=qw(health disk export filesystem interface mount node quota replication service snapshot task);
# TO DO: lssnspshot lsrepl lsrepltask

foreach my $method ( @METHODS ) {
	{
		no strict 'refs';
		my $get_method	= "get_$method";
		my $get_methods	= "get_${method}s";
	
		*{ __PACKAGE__ ."::$method" } = sub {
			my $self = shift;
			$self->{ss}->$method(@_)
		};

		*{ __PACKAGE__ ."::$get_method" } = sub {
			my $self = shift;
			$self->{ss}->$get_method(@_)
		};

		*{ __PACKAGE__ ."::$get_methods" } = sub {
			my $self = shift;
			$self->{ss}->$get_methods(@_)
		}
	}
}

sub new {
        my ($class, %args) = @_;
        my $self = bless {} , $class;
        $self->{ss} = IBM::StorageSystem->new( %args, no_stats => 1 );
        return $self
}

=head1 NAME

IBM::SONAS - Perl API to IBM SONAS CLI

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

IBM::SONAS is a Perl API to IBM SONAS CLI.

	use IBM::SONAS;

	# Create an IBM::SONAS object

	my $ibm = IBM::SONAS->new(      
				user     => 'admin',
				host     => 'my-sonas.company.com',
				key_path => '/path/to/my/.ssh/private_key'
		) or die "Couldn't create object! $!\n";

=head1 METHODS

=head3 new ( %ARGS )

	my $ibm = IBM::SONAS->new(      
				user     => 'admin',
				host     => 'my-sonas.company.com',
				key_path => '/path/to/my/.ssh/private_key'
		) or die "Couldn't create object! $!\n";

Constructor - creates a new IBM::SONAS object.  This method accepts three mandatory parameters
and one optional parameter, the three mandatory parameters are:

=over 3

=item user

The username of the user with which to connect to the device.

=item host

The hostname or IP address of the device to which we are connecting.

=item key_path

Either a relative or fully qualified path to the private ssh key valid for the
user name and device to which we are connecting.  Please note that the executing user
must have read permission to this key.

=back

=head3 disk ( $id ) 

        # Get the disk named "system_vol_00" as an IBM::StorageSystem::Disk object

        my $disk = $ibm->disk(system_vol_00);
        
        # Print the disk status

        print $disk->status;

        # Alternately

        print $ibm->disk(system_vol_00)->status;

Returns a L<IBM::StorageSystem::Disk> object representing the disk specified by the value of the id parameter, 
which should be a valid disk name in the target system.

B<Note> that this is a caching method and that a previously retrieved L<IBM::StorageSystem::Array> object will
be returned if one has been cached from previous invocations.

=head3 get_disk( $id )

This is a functionally equivalent non-caching implementation of the B<disk> method.

=head3 get_disks

        # Print a listing of all disks in the target system including their name, the assigned pool and status

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

Returns an array of L<IBM::StorageSystem::Disk> objects representing all disks in the target system.

=head3 get_exports

        # Print a listing of all configured exports containing the export name, the export path,
        # the export protocol and the export status.

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

Returns all configured exports on the target system as an array of L<IBM::StorageSystem::Export> objects.

=head3 filesystem( $filesystem_name )

        # Print the block size of file system 'fs1'

        print $ibm->filesystem(fs1)->block_size;
        
        # Get the file system 'fs2' as a IBM::StorageSystem::FileSystem object

        my $fs = $ibm->filesystem(fs2);

        # Print the mount point of this file system

        print "fs2 mount point: " . $fs->mount_point . "\n";

        # Call a function if inode usage on file system 'fs2' exceeds 90% of maximum allocation.
        monitoring_alert( 
		'Inode allocation > 90% on '.$filesystem->device_name 
	) 
        if ( ( ( $fs->inodes / $fs->max_inodes ) * 100 ) > 90 );

Returns the file system specified by the value of the named parameter as a L<IBM::StorageSystem::FileSystem> object.

Note that this is a caching method and a cached object will be retrieved if one exists,  If you require a
non-cached object, then please use the B<get_filesystem> method.

=head3 get_filesystem( $filesystem_name )

This is a non-caching functionally equivalent implementation of the B<filesystem> method.  Use this method if
you require the file system information to be retrieved directly from the target system rather than cache.

=head3 get_filesystems

        # Do the same for all file systems
        map { monitoring_alert( 'Inode allocation > 90% on '.$_->device_name ) }
	grep { ( ( ( $_->inodes / $_->max_inodes ) * 100 ) > 90 ) } $ibm->get_filesystems;

Returns an array of L<IBM::StorageSystem:FileSystem> objects representing all configured file systems on the
target system.

=head3 get_healths

        # Simple one-liner to print the sensor status and value for any error conditions.
        map { print join ' -> ', ( $_->sensor, $_->value."\n" ) } 
        grep { $_->status =~ /ERROR/ } $ibm->get_healths;

        # e.g.
        # CLUSTER -> Alert found in component cluster
        # MDISK -> Alert found in component mdisk
        # NODE -> Alert found in component node

Returns an array of L<IBM::StorageSystem::Health> objects representative of all health sensors on the target system.

=head3 interface ( $id )

        # Get interface ethX0 on management node mgmt001st001 as an IBM::StorageSystem::Interface object

	my $interface = $ibm->node('mgmt001st001')->interface('ethX0');

        # Print the interface status

        print $interface->up_or_down;

        # Print the interface status

        print $interface->speed;

        # Alternately;

        print $ibm->interface('mgmt001st001:ethX0')->speed;

Returns the interface identified by the value of the id parameter as an L<IBM::StorageSystem::Interface> object.

The value of the id parameter must be a valid node and interface name separated by a colon.

B<Note> that this method implements caching and a cached object will be returned shoudl one be present.
If you require a non-cached object then please use the B<get_iogroup> method.

=head3 get_interface( $id )

This is a functionally equivalent non-caching implementation of the B<interface> method.

=head3 get_interfaces

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

Returns an array of L<IBM::StorageSystem::Interface> objects representing all interfaces on the target system.

=head3 mount( $mount )

        # Print mount status of file system fs1

        print "Mount status: " . $ibm->mount(fs1) . "\n";

        # Print only those file system that aren’t mounted

        map { print $_->file_system . " is not mounted.\n" }
        grep { $_->mount_status ne ’mounted’ }
        $ibm->get_mounts;

Returns the mount identified by the mount parameter as a L<IBM::StorageSystem::Mount> object.

B<Note> that this method implements caching and a cached object will be returned shoudl one be present.
If you require a non-cached object then please use the B<get_iogroup> method.

=head3 get_mount( $mount )

This is a functionally equivalent non-caching implementation of the B<mount> method.

=head3 get_mounts

This method returns an array of L<IBM::StorageSystem::Mount> objects representing all mounts on the target system.

=head3 node( $node )

        # Get node mgmt001st001 as an IBM::StorageSystem::Node object

        my $node = $ibm->node( mgmt001st001 );
        
        # Print the node description

        print "Description: " . $node->description . "\n";

        # Prints something like: "Description: active management node"
        # Or alternately;

        print "Description: " . $ibm->node( mgmt001st001 )->description . "\n";


Returns the node identified by the value of the node parameter as a L<IBM::StorageSystem::Node> object.

B<Note> that this method implements caching and that a cached object will be returned if one is available.
If you require a non-cached object, then please use the non-caching B<get_node> method.

=head3 get_node( $node )

This is a functionally equivalent non-caching implementation of the B<node> method.

=head3 get_nodes

        # Print the GPFS and CTDB stati of all nodes

        foreach my $node ( $ibm->get_nodes ) {
                print "GPFS status: " . $node->GPFS_status 
		      . " - CTDB status: " . $node->CTDB_status . "\n"
        }

Returns an array of L<IBM::StorageSystem::Node> objects representing all configured nodes on the target system.

=head3 get_quotas 

        # Call a function to send a quota warning email for any quotas where the current
        # usage exceeds 85% of the quota usage hard limit.

        map  { send_quota_warning_email( $_ ) }
        grep { ( $_->used_usage / $_->HL_usage ) > 0.85 }
        grep { $_->name ne 'root' }
        grep { $_->type eq 'U' } $ibm->get_quotas;

Returns all quotas defined on the target system as an array of L<IBM::StorageSystem::Quota> objects.

=head3 replication( $eventlog_id )

Returns the replication event identified by the eventlog_id parameter as an L<IBM::StorageSystem::Replication> object.

B<Note> that this method implements caching and that a cached object will be returned if one is available.
If you require a non-cached object, then please use the non-caching B<get_node> method.

=head3 get_replication( $eventlog_id )

This is a functionally equivalent non-caching implementation of the B<replication> method.

=head3 get_replications

        use Date::Calc qw(date_to_Time Today_and_Now);

        # Generate an alert for any replication errors in the last six hours

        foreach my $task ( $ibm->get_replications ) {

                if ( $repl->status eq 'ERROR' and ( Date_to_Time( Today_and_Now ) 
                     - ( Date_to_Time( split /-| |\./, $repl->time ) ) ) > 21_600 ) {
                        alert( "Replication failure for filesystem " . $repl->filesystem 
				. " - log ID: " . $repl->log_id . 
			     )
                }

        }

Returns all asynchornous replication tasks as an array of L<IBM::StorageSystem::Replication> objects.

=head3 service( $service )

        # Print the enabled status of the NFS service

        print $ibm->service(NFS)->enabled;

        # Print the configured and enabled status of all services

        printf( "%-20s%-20s%-20s\n", 'Service', 'Configured', 'Active' );
        map { printf( "%-20s%-20s%-20s\n", $_->name, $_->configured, $_->active ) } $ibm->get_services;

Returns a L<IBM::StorageSystem::Service> object representing the service identified by the value of the
service parameter.

B<Note> that this method implements caching and that a cached object will be returned if one is available.
If you require a non-cached object, then please use the non-caching B<get_node> method.

=head3 get_service( $service )

This is a functionally equivalent non-caching implementation of the B<service> method.

=head3 get_services

Returns an array of L<IBM::StorageSystem::Service> objects representing all configured services on the target
system.

=head3 task( $task )

        # Print the status of the SNAPSHOTS task

        my $snapshots = $ibm->task(SNAPSHOTS);
        print "Status: " . $snapshots->status . "\n";

        # Alternately

        print "Status: " . $ibm->task(SNAPSHOTS)->status . "\n";

Return the task identified by the value of the task parameter as an L<IBM::StorageSystem::Task> object.

B<Note> that this method implements caching and that a cached object will be returned if one is available.
If you require a non-cached object, then please use the non-caching B<get_node> method.

=head3 get_task( $task )

This is a functionally equivalent non-caching implementation of the B<task> method.

=head3 get_tasks

        # Call an alert function for any tasks that are not in an OK state

        map { alert( $_->name ) } grep { $_->status ne 'OK' } $ibm->get_tasks;

Returns an array of L<IBM::StorageSystem::Task> objects representing all tasks on the target system.

=head1 AUTHOR

Luke Poskitt, C<< <ltp at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-ibm-sonas at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=IBM-SONAS>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc IBM::SONAS


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=IBM-SONAS>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/IBM-SONAS>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/IBM-SONAS>

=item * Search CPAN

L<http://search.cpan.org/dist/IBM-SONAS/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2013 Luke Poskitt.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of IBM::SONAS
