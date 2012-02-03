#!/usr/bin/perl
use strict;
use warnings;
use blib;

use Benchmark qw(:all);
use Cache::Memcached::Fast;
use Couchbase::Client;

my $memd = Cache::Memcached::Fast->new({
        servers => [qw(10.0.0.99:11212)]});
my $couch = Couchbase::Client->new({
    server => "10.0.0.99:8091",
    username => "Administrator",
    password => "123456",
    bucket => "membase0"
});

timethese(50000,{
    "Cache::Memcached::Fast" => sub {
        $memd->set("Bar", "BarValue");
        die unless "BarValue" eq $memd->get("Bar");
    },
    "Couchbase::Client" => sub {
        $couch->set("Bar", "BarValue");
        die "eh?" unless "BarValue" eq $couch->get("Bar")->value;
    }
});
printf("Exiting..\n"); 
