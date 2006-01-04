use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/lib";

use Test::More tests => 15;
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

my $entrypoint = 'http://localhost/foo';

run_tests();

sub run_tests {

    # test echo
    {
        my $request = HTTP::Request->new( GET => $entrypoint );

        ok( my $response = request($request), 'Request' );
        ok( $response->is_success, 'Response Successful 2xx' );
        is( $response->code, 200, 'Response Code' );
        ok( $response->content_type, 'text/javascript+json' );

        my $data = JSON::jsonToObj($response->content);
        is $data->{json_foo}, "bar";
        is_deeply $data->{json_baz}, [ 1, 2, 3 ];
        ok ! $data->{foo}, "doesn't return stash that doesn't match json_";
    }

    {
        my $request = HTTP::Request->new( GET => $entrypoint . "?cb=foobar" );

        ok( my $response = request($request), 'Request' );
        ok( $response->is_success, 'Response Successful 2xx' );
        is( $response->code, 200, 'Response Code' );
        ok( $response->content_type, 'text/javascript+json' );

        my $body = $response->content;
        ok $body =~ s/^foobar\((.*?)\);$/$1/sg, "wrapped in a callback";

        my $data = JSON::jsonToObj($body);
        is $data->{json_foo}, "bar";
        is_deeply $data->{json_baz}, [ 1, 2, 3 ];
        ok ! $data->{foo}, "doesn't return stash that doesn't match json_";
    }

}
