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

1;
