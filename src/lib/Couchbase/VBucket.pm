package Couchbase::VBucket;
use strict;
use warnings;

BEGIN {
    require XSLoader;
    our $VERSION = '0.01_1';
    XSLoader::load("Couchbase::Client", $VERSION);
}



1;