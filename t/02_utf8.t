use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/lib";

use Encode;
use Test::More;
use Catalyst::Test 'TestAppUnicode';

eval "use JSON 2.04; use Catalyst::Plugin::Unicode";
if ($@) {
    plan skip_all => "JSON 2.04 and Catalyst::Plugin::Unicode are needed for testing";
}

plan tests => 4;

BEGIN {
    no warnings 'redefine';

    *Catalyst::Test::local_request = sub {
        my ( $class, $request ) = @_;

        require HTTP::Request::AsCGI;
        my $cgi = HTTP::Request::AsCGI->new( $request, %ENV )->setup;

        $class->handle_request;

        return $cgi->restore->response;
    };
}

my $entrypoint = "http://localhost/foo";

{
    my $request = HTTP::Request->new( GET => $entrypoint );
    ok( my $response = request($request), 'Request' );

    my $data = JSON::from_json($response->content);
    is $data->{foo}, "テスト";
}

{
    my $request = HTTP::Request->new( GET => $entrypoint . "?cb=foo" );
    ok( my $response = request($request), 'Request' );

    my($json) = $response->content =~ /^foo\((.*)\);$/;
    my $data = JSON::from_json($json);
    is $data->{foo}, "テスト";
}

