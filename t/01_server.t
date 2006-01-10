use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/lib";

use Encode;
use Test::More tests => 28;
use Catalyst::Test 'TestApp';
use JSON ();

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
    ok( $response->is_success, 'Response Successful 2xx' );
    is( $response->code, 200, 'Response Code' );
    is_deeply( [ $response->content_type ], [ 'text/javascript', 'charset=utf-8' ] );

    my $data = JSON::jsonToObj($response->content);
    is $data->{json_foo}, "bar";
    is_deeply $data->{json_baz}, [ 1, 2, 3 ];
    ok ! $data->{foo}, "doesn't return stash that doesn't match json_";
}

{
    my $request = HTTP::Request->new( GET => "http://localhost/foo2" );

    ok( my $response = request($request), 'Request' );
    ok( $response->is_success, 'Response Successful 2xx' );
    is( $response->code, 200, 'Response Code' );
    is_deeply( [ $response->content_type ], [ 'text/javascript', 'charset=utf-8' ] );

    my $data = JSON::jsonToObj($response->content);
    is $data, "bar";
}

{
    my $request = HTTP::Request->new( GET => $entrypoint . "?cb=foobar" );

    ok( my $response = request($request), 'Request' );
    ok( $response->is_success, 'Response Successful 2xx' );
    is( $response->code, 200, 'Response Code' );
    is_deeply( [ $response->content_type ], [ 'text/javascript', 'charset=utf-8' ] );

    my $body = $response->content;
    ok $body =~ s/^foobar\((.*?)\);$/$1/sg, "wrapped in a callback";

    my $data = JSON::jsonToObj($body);
    is $data->{json_foo}, "bar";
    is_deeply $data->{json_baz}, [ 1, 2, 3 ];
    ok ! $data->{foo}, "doesn't return stash that doesn't match json_";
}

{
    my $request = HTTP::Request->new( GET => $entrypoint . "?cb=foobar%28" );

    ok( my $response = request($request), 'Request' );
    like $response->header('X-Error'), qr/Invalid callback parameter/;
}

{
    my $request = HTTP::Request->new( GET => "http://localhost/foo3" );

    ok( my $response = request($request), 'Request' );
    is_deeply( [ $response->content_type ], [ 'text/javascript', 'charset=utf-8' ] );
    ok decode('utf-8', $response->content);
}

{
    my $request = HTTP::Request->new( GET => "http://localhost/foo4" );

    ok( my $response = request($request), 'Request' );
    is_deeply( [ $response->content_type ], [ 'text/javascript', 'charset=euc-jp' ] );
    ok decode('euc-jp', $response->content);
}
