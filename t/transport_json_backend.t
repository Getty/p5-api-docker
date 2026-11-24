#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

# A body that is a bare JSON scalar decodes the same whichever JSON backend
# JSON::MaybeXS picked and whatever that backend's defaults are.
#
# The backends disagree on one default: whether a JSON text may be a scalar
# at all (allow_nonref). Cpanel::JSON::XS turned it on in 4.42, JSON::XS and
# JSON::PP in 4.0; before that their decode_json refuses `null`, `true` or
# `"text"` with "JSON text must be an object or array". The transport
# decoded with decode_json, so where such a version was installed a bare
# `null` from the engine came back as the four bytes 'null' -- the
# t/transport_shape.t and t/plugins.t failures of 0.006 on CPAN Testers.
#
# Whichever backend is installed here, the BEGIN block below gives it that
# older default -- for decode_json and for every decoder made with new --
# before API::Docker is loaded and takes its imports. A transport that left
# allow_nonref to the backend reads these bodies as bytes; one that sets it
# decodes them.

BEGIN {
  require JSON::MaybeXS;
  my $backend = JSON::MaybeXS::JSON();
  my $new     = $backend->can('new');

  no strict 'refs';
  no warnings qw( redefine prototype );
  *{ $backend . '::new' } = sub { $new->(@_)->allow_nonref(0) };
  *JSON::MaybeXS::decode_json = sub { $backend->new->utf8->decode($_[0]) };
}

use JSON::MaybeXS ();
use API::Docker;

package Test::TransportJSONBackend::FakeTransport;
use Moo;
extends 'API::Docker';

has canned => (is => 'rw', default => sub { [200, 'OK', {}, ''] });

sub _build__socket {
  my $sink = '';
  open my $fh, '>', \$sink or die "open: $!";
  return $fh;
}

sub _read_response { return $_[0]->canned }

package main;

sub fake_client {
  my ($body) = @_;
  return Test::TransportJSONBackend::FakeTransport->new(
    host        => 'unix:///nonexistent.sock',
    api_version => '1.41',
    canned      => [200, 'OK', {}, $body],
  );
}

subtest 'the simulated backend refuses a bare scalar' => sub {
  # Without this the file proves nothing: on a backend that still accepted
  # scalars the assertions below would pass against any transport.
  ok !eval { JSON::MaybeXS::decode_json('null'); 1 },
    'decode_json refuses null';
  ok !eval { JSON::MaybeXS->new(utf8 => 1)->decode('null'); 1 },
    'and so does a decoder made with new';
  is_deeply JSON::MaybeXS::decode_json('{"a":[1]}'), { a => [1] },
    'an object still decodes';
};

subtest 'a bare JSON scalar is decoded all the same' => sub {
  is fake_client('null')->get('/x'), undef,
    'null is undef, not the string "null"';

  my $true = fake_client('true')->get('/x');
  ok JSON::MaybeXS::is_bool($true), 'true is the JSON boolean';
  ok $true, 'and true';

  my $false = fake_client('false')->get('/x');
  ok JSON::MaybeXS::is_bool($false), 'false is the JSON boolean';
  ok !$false, 'and false';

  is fake_client('"hello"')->get('/x'), 'hello',
    'a quoted string comes back without its quotes';
  is fake_client(qq{  null\n})->get('/x'), undef,
    'leading whitespace and a trailing newline do not stop it';
};

subtest 'the endpoints that send a bare null' => sub {
  is fake_client('null')->get('/plugins/privileges', params => { remote => 'x' }),
    undef, 'GET /plugins/privileges';
  is fake_client('null')->get('/containers/deadbeef/changes'), undef,
    'GET /containers/{id}/changes';

  my $c = fake_client('null');
  is_deeply $c->plugins->privileges('vieux/sshfs'), [],
    'and privileges still turns it into the empty list it means';
};

subtest 'objects, arrays and plain text are unchanged' => sub {
  is_deeply fake_client('{"Id":"abc"}')->get('/x'), { Id => 'abc' },
    'an object';
  is_deeply fake_client('[1,2]')->get('/x'), [1, 2], 'an array';
  is fake_client('OK')->get('/_ping'), 'OK', 'a body that is not JSON';
  is fake_client('null pointer dereference')->get('/x'),
    'null pointer dereference', 'nor one that only starts like it';
};

subtest 'an ndjson stream decodes its lines with the same decoder' => sub {
  my $events = fake_client(qq{{"status":"a"}\n{"status":"b"}\n})
    ->get('/x', ndjson => 1);
  is_deeply $events, [{ status => 'a' }, { status => 'b' }],
    'one event per line';
};

done_testing;
