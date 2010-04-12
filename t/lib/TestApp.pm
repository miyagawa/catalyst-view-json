package TestApp;

use strict;
use warnings;
use MRO::Compat;

use Catalyst;

our $VERSION = '0.01';
__PACKAGE__->config({
    name => 'TestApp',
    disable_component_resolution_regex_fallback => 1,
    'View::JSON' => {
        expose_stash => qr/^json_/,
        allow_callback => 1,
        callback_param => 'cb',
    },
});

__PACKAGE__->setup;

sub finalize_error {
    my $c = shift;
    $c->res->header('X-Error' => $c->error->[0]);
    $c->next::method;
}

1;
