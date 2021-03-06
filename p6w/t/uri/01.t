use v6;
use Test;
plan 26;

use URI;
ok(1,'We use URI and we are still alive');

my $u = URI.new;
$u.init('http://example.com:80/about/us?foo#bar');

is($u.scheme, 'http', 'scheme'); 
is($u.host, 'example.com', 'host'); 
is($u.port, '80', 'port'); 
is($u.path, '/about/us', 'path'); 
is($u.query, 'foo', 'query'); 
is($u.frag, 'bar', 'frag'); 
is($u.chunks, 'about us', 'chunks'); 
is($u.chunks[0], 'about', 'first chunk'); 
is($u.chunks[1], 'us', 'second chunk'); 

is( ~$u, 'http://example.com:80/about/us?foo#bar',
    'Complete path stringification');

$u.init('https://eXAMplE.COM');

is($u.scheme, 'https', 'scheme'); 
is($u.host, 'example.com', 'host'); 
is( "$u", 'https://example.com',
    'https://eXAMplE.COM stringifies to https://her.com');

$u.init('/foo/bar/baz');

is($u.chunks, 'foo bar baz', 'chunks from absolute path'); 
ok($u.absolute, 'absolute path'); 
nok($u.relative, 'not relative path'); 

$u.init('foo/bar/baz');

is($u.chunks, 'foo bar baz', 'chunks from relative path'); 
ok( $u.relative, 'relative path'); 
nok($u.absolute, 'not absolute path'); 

is($u.chunks[0], 'foo', 'first chunk'); 
is($u.chunks[1], 'bar', 'second chunk'); 
is($u.chunks[-1], 'baz', 'last chunk'); 

$u.init('http://foo.com');

ok($u.chunks.list.perl eq '[""]', ".chunks return [''] for empty path");
ok($u.absolute, 'http://foo.com has an absolute path'); 
nok($u.relative, 'http://foo.com does not have a relative path'); 

# vim:ft=perl6
