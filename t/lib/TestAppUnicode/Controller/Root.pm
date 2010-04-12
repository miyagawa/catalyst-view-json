package TestAppUnicode::Controller::Root;

use strict;
use warnings;

use base 'Catalyst::Controller';

__PACKAGE__->config(namespace => '');

sub foo : Global {
    my ( $self, $c ) = @_;
    $c->stash->{foo} = "\x{30c6}\x{30b9}\x{30c8}";
    $c->forward('View::JSON');
}

1;
