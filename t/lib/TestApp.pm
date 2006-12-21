package TestApp;

use strict;
use warnings;

use Catalyst;

our $VERSION = '0.01';
__PACKAGE__->config({
    name => 'TestApp',
    'View::JSON' => {
        expose_stash => qr/^json_/,
        allow_callback => 1,
        callback_param => 'cb',
    },
});

__PACKAGE__->setup;

sub foo : Global {
    my ( $self, $c ) = @_;

    $c->component('View::JSON')->expose_stash(qr/^json_/);
    $c->stash->{json_foo} = "bar";
    $c->stash->{json_baz} = [ 1, 2, 3 ];
    $c->stash->{foo}      = "barbarbar";

    $c->forward('TestApp::View::JSON');
}

sub foo2 : Global {
    my( $self, $c ) = @_;

    $c->component('View::JSON')->expose_stash('json_foo');
    $c->stash->{json_foo} = "bar";
    $c->stash->{json_baz} = [ 1, 2, 3 ];

    $c->forward('TestApp::View::JSON');
}

sub foo3 : Global {
    my( $self, $c ) = @_;
    $c->stash->{json_foo} = "\x{5bae}\x{5ddd}";
    $c->component('View::JSON')->encoding('utf-8');
    $c->forward('TestApp::View::JSON');
}

sub foo4 : Global {
    my( $self, $c ) = @_;
    $c->stash->{json_foo} = "\x{5bae}\x{5ddd}";
    $c->component('View::JSON')->encoding('euc-jp');
    $c->forward('TestApp::View::JSON');
}

sub foo5 : Global {
    my( $self, $c ) = @_;
    $c->stash->{json_foo} = "\x{5bae}\x{5ddd}";
    $c->component('View::JSON')->no_x_json_header(1);
    $c->forward('TestApp::View::JSON');
}

sub finalize_error {
    my $c = shift;
    $c->res->header('X-Error' => $c->error->[0]);
    $c->NEXT::finalize_error;
}

1;
