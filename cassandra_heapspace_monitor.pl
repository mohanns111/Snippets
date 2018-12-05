#!/usr/bin/perl
use strict;
use warnings;
use POSIX qw/strftime/;

my $hostname = "127.0.0.1";
my $nodetool;

#Check if host is reachable
if ( $hostname eq "" ) {
    die "Hostname must be defined, hostname: $hostname\n";
}

#check if the nodettol exists
if ( -e '/global/cassandra/bin/nodetool' ) {
    $nodetool = '/global/cassandra/bin/nodetool';
}
elsif ( -e '/usr/local/cassandra/bin/nodetool' ) {
    $nodetool = '/usr/local/cassandra/bin/nodetool';
}
else {
    die "nodetool not found\n";
}

get_cass_info();

#get heap space details from nodetools
sub get_cass_info {
    my $pfx  = "cassandra.info";
    my $info = `$nodetool info`;
    my $time = strftime( '%Y-%m-%d-%H-%M-%S', localtime );
    my $data_string;

    #open file to log heap status
    open( FH, '>',
        '/global/b2v/apps/conn/joynrds/cassandra/logs/cluster_heap_status.log' )
      or die "logfilecant be found\n";

    #start the file with time stamp
    print FH "$time checking cassandra status\n";

    for ( split /^/, $info ) {
        if ( $_ =~ m/Load\s+:\s(\d+\.\d+)/ ) {
            my $load = $1;

            #print "load is $load\n";
            $data_string .= "$time $pfx.load $load \n";
            next;
        }
        if ( $_ =~ m/Heap\sMemory\s\(MB\)\s+:\s(\d+\.\d+)\s\/\s(\d+\.\d+)/ ) {
            my $heap          = $1;
            my $heapallocated = $2;

            #print "heap allocated is $heapallocated\n";
            #print "heap is $heap\n";
            $data_string .= "$time $pfx.heapallocated $heapallocated \n";
            $data_string .= "$time $pfx.heapusage $heap \n";
            my $heap_usage = 100 * $heap / $heapallocated;
            my $heap_usage_disp = sprintf "%.2f" , $heap_usage;
            if ( $heap_usage < 75 ) {
                $data_string .=
                  "$time $pfx.\%heapusage $heap_usage_disp is normal\n";
            }
            elsif ( $heap_usage >= 95 ) {
                $data_string .=
                  "$time $pfx.\%heapusage $heap_usage_disp is critical\n";
            }
            else {
                $data_string .=
                  "$time $pfx.\%heapusage $heap_usage_disp is in warning\n";
            }
            #print $heap_usage_disp;
            next;
        }
    }
    print FH $data_string;
    close(FH);
    return ($data_string);
}
