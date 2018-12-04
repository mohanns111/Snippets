#!/usr/bin/perl
use strict;
use autodie;

my $hostname = `127.0.0.1`;
my $nodetool;


#Check if host is reachable
if ($hostname eq "") {
  die "*** Hostname must be defined, hostname: $hostname\n";
}

#check if the nodettol exists
if (-e '/global/b2v/conn/joynr/cassandra/cassandra/bin/nodetool' ) {
  $nodetool = '/etc/cassandra/bin/nodetool';
}
elsif ( -e '/usr/local/cassandra/bin/nodetool') {
  $nodetool = '/usr/local/cassandra/bin/nodetool';
}
else {
  $nodetool = 0
}
sleep 120;

#get heap space details from nodetools
sub get_cass_info {
  my $pfx = set_pfx("cassandra.info");
  my $info=`$nodetool -h \$HOSTNAME info`;
  my $time=time;
  my $data_string;

  for (split /^/,$info) {
    if ($_ =~ m/Load\s+:\s(\d+\.\d+)/) {
      my $load = $1;
      $data_string .= "$pfx.load $load $time\n";
      next;
    }
    if ($_ =~ m/Heap\sMemory\s\(MB\)\s:\s(\d+\.\d+)\s\/\s\d+\.\d+/) {
      my $heap = $1;
      $data_string .= "$pfx.heap $heap $time\n";
      next;
    }
  }
  return  ($data_string);
}

#get cassandra stat
sub get_cass_rpc {
  my $pfx = set_pfx("cassandra.rpc");
  my @ATTRIBS = ("CompletedTasks","PendingTasks","CurrentlyBlockedTasks","ActiveCount","TotalBlockedTasks");
  my $data_string;
  my $time=time;

  unless (-e $check_jmx) {
    print "check_jmx not found at $check_jmx\n";
    return;
  }
  foreach $a (@ATTRIBS) {
   my $cmd = `$check_jmx -U "service:jmx:rmi:///jndi/rmi://localhost:7199/jmxrmi" -O org.apache.cassandra.RPC-THREAD-POOL:type=RPC-Thread -A $a -K Value`;
   $cmd =~ /=(\d+(?:\.\d+)?)/;;
   my $v = $1;
   if (defined($v)) {
     $data_string .= "$pfx.$a $v $time\n";
   }
 }
 return  ($data_string);
}