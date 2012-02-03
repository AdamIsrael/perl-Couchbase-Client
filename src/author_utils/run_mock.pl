#!/usr/bin/perl
use strict;
use warnings;
use Dir::Self;
use blib;
use lib __DIR__;
use Couchbase::MockServer;

my $config = do 'PLCB_Config.pm';
my $mock = Couchbase::MockServer->new(
    dir => "/tmp/couchbase_mock",
    url => $config->{COUCHBASE_MOCK_JARURL},
    buckets => [
        { name => "membase0" }
    ],
    port => 8092
);
