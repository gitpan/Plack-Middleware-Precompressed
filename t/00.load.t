use Test::More tests => 1;

BEGIN {
use_ok( 'Plack::Middleware::Precompressed' )
or BAIL_OUT( 'testing pointless if the module won\'t even load' );
}