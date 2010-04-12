package TestAppUnicode;

use strict;
use warnings;

use Catalyst qw( Unicode );

__PACKAGE__->config({
    name => 'TestAppUnicode',
    disable_component_resolution_regex_fallback => 1,
    'View::JSON' => {
        allow_callback => 1,
        callback_param => 'cb',
    },
});

__PACKAGE__->setup;

sub foo : Global {
    my ( $self, $c ) = @_;
    $c->stash->{foo} = "\x{30c6}\x{30b9}\x{30c8}";
    $c->forward('View::JSON');
}

1;
