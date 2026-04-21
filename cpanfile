requires 'Moo';
requires 'JSON::MaybeXS';
requires 'IO::Socket::UNIX';
requires 'URI';
requires 'namespace::clean';
requires 'Log::Any';

on test => sub {
    requires 'Test::More';
    requires 'Path::Tiny';
};
