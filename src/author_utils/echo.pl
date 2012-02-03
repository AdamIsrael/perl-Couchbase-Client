#!/usr/bin/perl
use strict;
use warnings;
use blib;
use Couchbase::Client;
use Data::Dumper;

my $client = Couchbase::Client->new({
        server => '10.0.0.99:8091',
        username => 'Administrator',
        password => '123456',
        bucket => 'membase0',
    });

my $key = $ARGV[0];
my $value = reverse($key);

my $status;

$status = $client->set($key, $value);
printf("Set: %s\n", Dumper($status));
print Dumper($client->get_errors);

$status = $client->get($key);
printf("Get: %s\n", Dumper($status));
print Dumper($client->get_errors);
