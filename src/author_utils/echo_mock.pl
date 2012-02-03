#!/usr/bin/perl
use strict;
use warnings;
use blib;
use Couchbase::Client;
my $cli = Couchbase::Client->new({
    server => '10.0.0.99:8092',
    bucket => 'protected',
    username => 'protected',
    password => 'secret'
});

$cli->set("Test", 42);
print $cli->get("Test")->value . "\n";

