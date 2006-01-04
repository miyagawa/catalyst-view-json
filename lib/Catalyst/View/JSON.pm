package Catalyst::View::JSON;

use strict;
our $VERSION = '0.01';

use base qw( Catalyst::View );
use NEXT;
use JSON ();

__PACKAGE__->mk_accessors(qw( allow_callback callback_param expose_stash ));

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

    $self;
}

sub process {
    my($self, $c) = @_;

    # get the response data from stash
    my $cond = sub { 1 };

    if (my $expose = $self->expose_stash) {
        if (ref($expose) eq 'Regexp') {
            $cond = sub { $_[0] =~ $expose };
        } elsif (ref($expose) eq 'ARRAY') {
            my %match = map { $_ => 1 } @$expose;
            $cond = sub { $match{$_[0]} };
        } else {
            $c->log->warn("expose_stash shold be an array referernce or Regexp object.");
        }
    }

    my %data = map { $cond->($_) ? ($_ => $c->stash->{$_}) : () }
                keys %{$c->stash};

    my $cb_param = $self->allow_callback
        ? ($self->callback_param || 'callback') : undef;
    my $cb = $cb_param ? $c->req->param($cb_param) : undef;

    $c->res->content_type('text/javascript+json'); # xxx

    my $output;
    $output .= "$cb(" if $cb;
    $output .= JSON::objToJson(\%data);
    $output .= ");"   if $cb;

    $c->res->output($output);
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

List or regular expression object, to specify which stash keys are
exposed as a JSON response. Defaults to everything. Examples:

  # only exposes keys 'foo' and 'bar'
  expose_stash => [ qw( foo bar ) ],

  # only exposes keys that matches with /^json_/
  expose_stash => qr/^json_/,

=back

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

See Yahoo's nice explanation on
L<http://developer.yahoo.net/common/json.html>

=head1 AUTHOR

Tatsuhiko Miyagawa E<lt>miyagawa@bulknews.netE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Catalyst>, L<JSON>

=cut
