#!/usr/bin/perl
use Dir::Self;
use lib __DIR__ . "../";
use blib;
use Couchbase::MockServer;
use Couchbase::Config::UA;
use JSON;
use Data::Dumper::Concise;
use Log::Fu { level => "debug" };
use Getopt::Long;

GetOptions(
    'j|java' => \my $UseJava,
    'u|username=s' => \my $Username,
    'p|password=s' => \my $Password,
    's|server|H=s' => \my $Hostname
);


my $config = do 'PLCB_Config.pm';
my $mock;

if($UseJava) {
    my $mock = Couchbase::MockServer->new(
        dir => "/home/mordy/src/Couchbase-Client/t/tmp",
        url => $config->{COUCHBASE_MOCK_JARURL},
        port => 8092,
        nodes => 20,
    );
    $Hostname = "localhost:8092";
    $Username = "";
    $Password = "";
}


my $o = Couchbase::Config::UA->new(
    $Hostname,
    username => $Username,
    password => $Password);

my $resp;

$resp = $o->list_pools();
$resp = $o->pool_info($resp);
$resp = $o->list_buckets($resp);

foreach my $bucket (@$resp) {
    foreach my $node (@{$bucket->nodes}) {
        log_warnf("Found node %s:%d, version=%s, status=%s",
                  $node->hostname,
                  $node->port_direct,
                  $node->version,
                  $node->status);
    }
    #print Dumper($bucket);
    
    foreach my $key qw(foo bar baz) {
        my $server = $bucket->vbconf->map($key);
        log_debugf("Key %s maps to %s", $key, $server);
    }
}
#print Dumper($resp);
