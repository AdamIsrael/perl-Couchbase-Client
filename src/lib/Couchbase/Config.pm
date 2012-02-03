package Couchbase::Config::Request;
use strict;
use warnings;
use base qw(HTTP::Request Exporter);
BEGIN { $INC{'Couchbase/Config/Request.pm'} = 1; }
our @EXPORT;

use Constant::Generate [qw(
    LIST_ALL_POOLS
    POOL_INFO
    LIST_BUCKETS
    STAT_BUCKET
)], prefix => 'COUCHCONF_REQ_',
    export => 1,
    allsyms => 'couchconf_reqtypes';

use Class::XSAccessor {
    accessors => [qw(cbc_ctx cbc_data cbc_reqtype)]
};

package Couchbase::Config;
use strict;
use warnings;

use MIME::Base64 qw(encode_base64);
use JSON::XS;
use Data::Dumper;
use base qw(Exporter);
our @EXPORT;

use Couchbase::VBucket;
use Couchbase::Config::Node;
use Couchbase::Config::Request;

use Log::Fu;

use Class::XSAccessor {
    constructor => '_real_new',
    accessors => [qw(
        uri_base
        request_base
        username
        password
        host
        port
        parsers
        is_streaming
        pools
    )]
};

sub new {
    my ($cls,$server,%options) = @_;
    if(!$server) {
        die("Must have cluster server");
    }
    
    my ($host,$port) = split(/:/, $server);
    $port ||= 8091;
    
    
    my $self = $cls->_real_new(host => $host, port => $port, %options);
    
    my $base = Couchbase::Config::Request->new();
    
    if($self->username && $self->password) {
        my $authstring = join(":", $self->username, $self->password);
        $authstring = encode_base64($authstring);
        
        $base->header('Authorization', "Basic $authstring");
    }
    $base->header('Accept', 'application/json');
    $base->uri("http://$host:$port/");
    $self->uri_base("http://$host:$port");
    $base->header('Host', $host);
    $base->protocol('HTTP/1.1');
    
    $self->request_base($base);
    $self->pools({});
    
    $self->parsers({});
    return $self;
}

sub _new_get_request {
    my ($self,$path,$reqtype) = @_;
    my $req = $self->request_base->clone();
    if($path !~ m,^/,) {
        $path = "/$path";
    }
    log_info("Generating new request for $path");
    #$req->uri->path($path);
    $req->uri($self->uri_base . $path);
    $req->method("GET");
    $req->cbc_reqtype($reqtype);
    return $req;
}

sub update_context {
    my ($self,$request,$response) = @_;
    my $reqtype = $request->cbc_reqtype;
    #print Dumper($response);
    if(!$response->is_success) {
        log_err("Error: ", $response->decoded_content);
        print Dumper($response);
        return;
    }
    
    my $hash = decode_json($response->decoded_content);
    
    if($reqtype == COUCHCONF_REQ_LIST_ALL_POOLS) {
        my $obj;
        print Dumper($hash);
        if(ref $hash->{pools} eq 'HASH') {
            $obj = { %{$hash->{pools}} };
        } elsif (ref $hash->{pools } eq 'ARRAY') {
            $obj = { %{$hash->{pools}->[0]} };
        }
        bless $obj, 'Couchbase::Config::Pool';
        $self->pools->{$obj->name} = $obj;
        return $obj;
    } elsif ($reqtype == COUCHCONF_REQ_POOL_INFO) {
        print Dumper($hash);
        my $pool = $request->cbc_data;
        $pool->bucket_info_uri($hash->{buckets}->{uri});
        return $pool;
    } elsif ($reqtype == COUCHCONF_REQ_LIST_BUCKETS) {
        my $pool = $request->cbc_data;
        my $bucket = Couchbase::Config::Bucket->parse_json(
            $response->decoded_content);
        if(ref $hash eq 'ARRAY') {
            $hash = $hash->[0];
        }
        $hash->{vBucketServerMap}->{vBucketMap} = 'Deleted for brevity';
        return [ $bucket ];
    }
}

sub list_pools {
    my $self = shift;
    my $req = $self->_new_get_request("/pools", COUCHCONF_REQ_LIST_ALL_POOLS);
}

sub pool_info {
    my ($self,$pool) = @_;
    my $request = $self->_new_get_request(
        $pool->uri, COUCHCONF_REQ_POOL_INFO);
    $request->cbc_data($pool);
    return $request;
}

sub list_buckets {
    my ($self,$pool) = @_;
    my $request = $self->_new_get_request(
        $pool->bucket_info_uri, COUCHCONF_REQ_LIST_BUCKETS);
    $request->cbc_data($pool);
    return $request;
}

1;