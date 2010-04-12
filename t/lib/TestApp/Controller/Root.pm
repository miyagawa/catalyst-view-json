package TestApp::Controller::Root;

use strict;
use warnings;

use base 'Catalyst::Controller';

__PACKAGE__->config(namespace => '');

sub foo : Global {
    my ( $self, $c ) = @_;

    $c->component('View::JSON')->expose_stash(qr/^json_/);
    $c->stash->{json_foo} = "bar";
    $c->stash->{json_baz} = [ 1, 2, 3 ];
    $c->stash->{foo}      = "barbarbar";

    $c->forward('View::JSON');
}

sub foo2 : Global {
    my( $self, $c ) = @_;

    $c->component('View::JSON')->expose_stash('json_baz');
    $c->stash->{json_foo} = "bar";
    $c->stash->{json_baz} = [ 1, 2, 3 ];

    $c->forward('View::JSON');
}

sub foo3 : Global {
    my( $self, $c ) = @_;
    $c->stash->{json_foo} = "\x{5bae}\x{5ddd}";
    $c->component('View::JSON')->encoding('utf-8');
    $c->forward('View::JSON');
}

sub foo4 : Global {
    my( $self, $c ) = @_;
    $c->stash->{json_foo} = "\x{5bae}\x{5ddd}";
    $c->component('View::JSON')->encoding('euc-jp');
    $c->forward('View::JSON');
}

sub foo5 : Global {
    my( $self, $c ) = @_;
    $c->stash->{json_foo} = "\x{5bae}\x{5ddd}";
    $c->component('View::JSON')->no_x_json_header(1);
    $c->forward('View::JSON');
}

sub foo6 : Global {
    my( $self, $c ) = @_;
    $c->stash->{json_foo} = "\x{5bae}\x{5ddd}";
    $c->forward('View::JSON2');
}

1;
