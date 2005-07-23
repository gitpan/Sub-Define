use Test::More tests => 5;
use strict;
BEGIN { $^W = 1 }

use Sub::Define qw/ define_sub /;
ok(! defined &foo);
ok(! define_sub(foo => sub { 1 }));
ok(  defined &foo);
ok(  define_sub(foo => sub { 1 }));
ok(  defined &foo);
