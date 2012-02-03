package Couchbase::Config::UA;
use strict;
use warnings;
use LWP::UserAgent;
use Couchbase::Config;
use base qw(Couchbase::Config);
use JSON;
use Log::Fu;

use Class::XSAccessor {
    accessors => [qw(lwp bucket_config)]
};

sub new {
    my ($cls,@options) = @_;
    my $self = __PACKAGE__->SUPER::new(@options);
    bless $self, $cls;
    $self->lwp(LWP::UserAgent->new());
    return $self;
}


foreach my $methname qw(list_pools pool_info list_buckets) {
    no strict 'refs';
    *{$methname} = sub {
        my $self = shift;
        my $request = $self->${\"SUPER::$methname"}(@_);
        my $response = $self->lwp->request($request);
        $self->update_context($request, $response);
    };
}



sub get_bucket_config {
    my ($self,$bucket) = @_;
    $self->bucket_config(undef);
    $self->lwp->set_my_handler(response_data =>
        sub {
            my ($response,$ua,$header,$data) = @_;
            my $bucket_config = $self->parse_bucket_config($bucket, $data);
            if($bucket_config) {
                $self->bucket_config($bucket_config);
                die('not an error');
            }
            return 1;
        },
        m_patch_path =>qr,pools/streaming/bucketsStreaming,);
    
    my $resp = $self->lwp->request($self->SUPER::get_bucket_config($bucket));
    if($self->bucket_config) {
        return $self->bucket_config;
    } else {
        return $resp;
    }
}

1;