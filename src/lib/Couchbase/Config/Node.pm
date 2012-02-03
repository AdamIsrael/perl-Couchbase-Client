package Couchbase::Config::Node;
use strict;
use warnings;
use Class::XSAccessor {
    constructor => 'new',
    accessors => [qw(
        hostname
        status
        port_direct
        port_proxy
        version
    )]
};

{
    no warnings 'once';
    *direct = *port_direct;
    *proxy = *port_proxy;
}

sub is_ok {
    my $self = shift;
    $self->status eq 'healthy';
}

package Couchbase::Config::Pool;
use strict;
use warnings;
use Class::XSAccessor {
    accessors => [qw(
        name uri streamingUri
        
        bucket_info_uri
        buckets
    )]
};

*uri_plain = *uri;
*uri_streaming = *uriStreaming;

package Couchbase::Config::Bucket;
use strict;
use warnings;
use Couchbase::VBucket;
use JSON::XS;
use Data::Dumper;
use Log::Fu;

use Class::XSAccessor {
    constructor => 'new',
    accessors => [qw(name nodes vbconf json)]
};

sub parse_json {
    my ($cls,$json) = @_;
    my $vb = Couchbase::VBucket->parse($json);
    my $hash = decode_json($json);
    my $nodes_array = [];
    
    if(ref $hash eq 'ARRAY') {
        $hash = $hash->[0];
        if(!$vb) {
            log_warn("libvbucket did not like our json");
            $vb = Couchbase::VBucket->parse(encode_json($hash));
        }
    }
    
    foreach my $node (@{$hash->{nodes} }) {
        my $nodeobj = { %$node };
        
        @{$nodeobj}{qw(port_direct port_proxy)}
            = @{$node->{ports}}{qw(direct proxy)};
        delete $nodeobj->{ports};
        
        bless $nodeobj, 'Couchbase::Config::Node';
        push @$nodes_array, $nodeobj;
    }
    my $o = $cls->new(name => $hash->{name},
                      nodes => $nodes_array,
                      vbconf => $vb);
    return $o;
}



