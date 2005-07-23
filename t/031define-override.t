use Test::More tests => 4;
use strict;
BEGIN { $^W = 1 }

our %subs;

{
    package HashSubs;
    use Sub::Define;
    use base Sub::Define::Interface::;

    %subs = (
        foo => sub { "I'm foo!" },
    );

    sub SUB_DEFINE_define_sub {
        my ($pkg, $name, $code) = @_;

        my $old = $subs{$name};
        $subs{$name} = $code;

        return $old;
    }
}

use Sub::Define qw/ define_sub /;

my $bar = sub { "I'm bar!" };

ok(  $subs{foo});
ok(! define_sub('HashSubs::bar' => $bar));
is($subs{bar}, $bar);
my $bar2 = define_sub('HashSubs::bar' => sub { 1 });
is($bar2, $bar);
