use Test::More tests => 3;
use strict;
BEGIN { $^W = 1 }

use Sub::Define ();

ok(! defined &define_sub);
use_ok(Sub::Define:: => qw/ define_sub /);
ok(defined &define_sub);
