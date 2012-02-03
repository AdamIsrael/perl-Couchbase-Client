package CouchDebug;
use strict;
use warnings;
use blib;
use base qw(Couchbase::Client);
use Data::Dumper;

use Log::Fu { level => "debug" };

sub runloop {
    my $o = shift;
    my @klist = qw(Foo Bar Baz Blargh Bleh Meh Grr Gah);
    my $params = [ map { [$_, uc("$_")] } @klist ];
    
    my $res = $o->set_multi($params);
    
    log_infof("Have missing results: %d",
              scalar grep {!exists $res->{$_} } @klist);
    
    log_infof("Have failed results: %s",
              join(",", grep { !$res->{$_}->is_ok } @klist) || "NONE");
    
    $res = $o->get_multi(@klist);
    log_infof("Unexpected results: %s",
              join(",", grep { $res->{$_}->value ne uc($_) } @klist) || "NONE");
    
    
    my $old_res = $res;
    
    $res = $o->cas_multi(map {
        [$_, uc($_), $res->{$_}->cas ]
    } @klist);
    
    log_infof("Have failed: %d",
              scalar grep {!$res->{$_}->is_ok} @klist);
}

if(!caller) {
    my $o = __PACKAGE__->new({
        server => '10.0.0.99:8091',
        username => 'Administrator',
        password => '123456',
        bucket => 'membase0',
        compress_threshold => 100,
    });
    bless $o, __PACKAGE__;
    $o->connect();
    my $LOOPS = shift @ARGV;
    if($LOOPS) {
        $Log::Fu::SHUSH = 1;
        $o->runloop() for (0..$LOOPS);
    } else {
        $o->runloop();
    }
    #my $stats = $o->stats([""]);
    #print Dumper($stats);    
}
