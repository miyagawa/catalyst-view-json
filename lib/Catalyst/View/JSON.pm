package Catalyst::View::JSON;

use strict;
our $VERSION = '0.05';

use base qw( Catalyst::View );
use Encode ();
use NEXT;
use JSON ();
use Catalyst::Exception;

__PACKAGE__->mk_accessors(qw( allow_callback callback_param expose_stash encoding __json ));

sub new {
    my($class, $c, $arguments) = @_;
    my $self = $class->NEXT::new($c);

    for my $field (keys %$arguments) {
        if ($self->can($field)) {
            $self->$field($arguments->{$field});
        } else {
            $c->log->debug("Unkown config parameter '$field'")
#                if $c->debug;
        }
    }

    $self->__json( JSON::Converter->new );
    $self;
}

sub process {
    my($self, $c) = @_;

    # get the response data from stash
    my $cond = sub { 1 };

    my $single_key;
    if (my $expose = $self->expose_stash) {
        if (ref($expose) eq 'Regexp') {
            $cond = sub { $_[0] =~ $expose };
        } elsif (ref($expose) eq 'ARRAY') {
            my %match = map { $_ => 1 } @$expose;
            $cond = sub { $match{$_[0]} };
        } elsif (!ref($expose)) {
            $single_key = $expose;
        } else {
            $c->log->warn("expose_stash should be an array referernce or Regexp object.");
        }
    }

    my $data;
    if ($single_key) {
        $data = $c->stash->{$single_key};
    } else {
        $data = { map { $cond->($_) ? ($_ => $c->stash->{$_}) : () }
                  keys %{$c->stash} };
    }

    my $cb_param = $self->allow_callback
        ? ($self->callback_param || 'callback') : undef;
    my $cb = $cb_param ? $c->req->param($cb_param) : undef;
    $self->validate_callback_param($cb) if $cb;

    my $json = $self->_jsonize($data);

    # When you set encoding option in View::JSON, this plugin DWIMs
    my $encoding = $self->encoding || 'utf-8';

    # if you pass a valid Unicode flagged string in the stash,
    # this view automatically transcodes to the encoding you set.
    # Otherwise it just by passed the stash data in JSON format
    if ( Encode::is_utf8($json) ) {
        $json = Encode::encode($json, $encoding);
    }

    $c->res->content_type("text/javascript; charset=$encoding");

    my $output;
    $output .= "$cb(" if $cb;
    $output .= $json;
    $output .= ");"   if $cb;

    $c->res->output($output);
}

sub _jsonize {
    my($self, $data) = @_;
    ref $data ? $self->__json->objToJson($data) : $self->__json->valueToJson($data);
}

sub validate_callback_param {
    my($self, $param) = @_;
    $param =~ /^[a-zA-Z0-9\.\_\[\]]+$/
        or Catalyst::Exception->throw("Invalid callback parameter $param");
}

1;
__END__

=head1 NAME

Catalyst::View::JSON - JSON view for your data

=head1 SYNOPSIS

  # lib/MyApp/View/JSON.pm
  package MyApp::View::JSON;
  use base qw( Catalyst::View::JSON );
  1;

  # configure in lib/MyApp.pm
  MyApp->config({
      ...
      'V::JSON' => {
          allow_callback  => 1,    # defaults to 0
          callback_param  => 'cb', # defaults to 'callback'
          expose_stash    => [ qw(foo bar) ], # defaults to everything
      },
  });

  sub hello : Local {
      my($self, $c) = @_;
      $c->stash->{message} = 'Hello World!';
      $c->forward('MyApp::View::JSON');
  }

=head1 DESCRIPTION

Catalyst::View::JSON is a Catalyst View handler that returns stash
data in JSON format.

=head1 CONFIG VARIABLES

=over 4

=item allow_callback

Flag to allow callbacks by adding C<callback=function>. Defaults to 0
(doesn't allow callbacks). See L</CALLBACKS> for details.

=item callback_param

Name of URI parameter to specify JSON callback function name. Defaults
to C<callback>. Only effective when C<allow_callback> is turned on.

=item expose_stash

Scalar, List or regular expression object, to specify which stash keys are
exposed as a JSON response. Defaults to everything. Examples configuration:

  # use 'json_data' value as a data to return
  expose_stash => 'json_data',

  # only exposes keys 'foo' and 'bar'
  expose_stash => [ qw( foo bar ) ],

  # only exposes keys that matches with /^json_/
  expose_stash => qr/^json_/,

Suppose you have data structure of the following.

  $c->stash->{foo} = [ 1, 2 ];
  $c->stash->{bar} = [ 3, 4 ];

By default, this view will return:

  {"foo":[1,2],"bar":2}

When you set C<< expose_stash => [ 'foo' ] >>, it'll return

  {"foo":[1,2]}

and in the case of C<< expose_stash => 'foo' >>, it'll just return

  [1,2]

instead of the whole object (hashref in perl). This option will be
useful when you share the method with different views (e.g. TT) and
don't want to expose non-irrelevant stash variables as in JSON.

=back

=head2 ENCODINGS

Due to the browser gotchas like those of Safari and Opera, sometimes
you have to specify a valid charset value in the response's
Content-Type header, e.g. C<text/javascript; charset=utf-8>.

Catalyst::View::JSON comes with the configuration variable C<encoding>
which defaults to utf-8. You can change it via C<< YourApp->config >>
or even runtime, using C<component>.

  $c->component('View::JSON')->encoding('euc-jp');

This assumes you set your stash data in raw euc-jp bytes, or Unicode
flagged variable. In case of Unicode flagged variable,
Catalyst::View::JSON automatically encodes the data into your
C<encoding> value (euc-jp in this case) before emitting the data to
the browser.

=head2 CALLBACKS

By default it returns raw JSON data so your JavaScript app can deal
with using XMLHttpRequest calls. Adding callbacks to the API gives
more flexibility to the end users of the API: overcome the
cross-domain restrictions of XMLHttpRequest. It can be done by
appending I<script> node with dynamic DOM manipulation, and associate
callback handler to the returned data.

For example, suppose you have the following code.

  sub end : Private {
      my($self, $c) = @_;
      if ($c->req->param('output') eq 'json') {
          $c->forward('MyApp::View::JSON');
      } else {
          ...
      }
  }

C</foo/bar?output=json> will just return the data set in
C<< $c->stash >> as JSON format, like:

  { result: "foo", message: "Hello" }

but C</foo/bar?output=json&callback=handle_result> will give you:

  handle_result({ result: "foo", message: "Hello" });

and you can write a custom C<handle_result> function to handle the
returned data asynchronously.

The valid characters you can use in the callback function are

  [a-zA-Z0-9\.\_\[\]]

but you can customize the behaviour by overriding the
C<validate_callback_param> method in your View::JSON class.

See Yahoo's nice explanation on
L<http://developer.yahoo.net/common/json.html>

=head1 AUTHOR

Tatsuhiko Miyagawa E<lt>miyagawa@bulknews.netE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Catalyst>, L<JSON>

=cut
