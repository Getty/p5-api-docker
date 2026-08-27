requires 'Moo';
requires 'Carp';
requires 'Errno';
requires 'IO::Handle';
requires 'JSON::MaybeXS';
requires 'MIME::Base64';
requires 'IO::Socket::UNIX';
requires 'IO::Socket::INET';
requires 'namespace::clean';
requires 'Path::Tiny';
requires 'overload';
requires 'Scalar::Util';
requires 'Socket';
requires 'Log::Any';

# Only the tcp:// transport with tls => 1 loads this, and it is loaded at the
# moment that connection is opened. It brings in Net::SSLeay, which is XS
# compiled against libssl; requiring it would make this client unbuildable
# where there are no OpenSSL headers, for the sake of a transport that the
# unix:// default -- local Docker, rootless Podman -- never uses.
recommends 'IO::Socket::SSL';

on test => sub {
    requires 'Test::More';
    requires 'Path::Tiny';
    requires 'Exporter';
};
