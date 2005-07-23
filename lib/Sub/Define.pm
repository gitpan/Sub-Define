package Sub::Define;
use 5.006001;

$VERSION = 0.01;

use base 'Exporter';
@EXPORT_OK = qw/ define_sub /;
$EXPORT_TAGS{ALL} = \@EXPORT_OK;

use strict;
use Carp;
use Symbol qw/ qualify_to_ref /;
require warnings;

sub define_sub {
    my $code = pop;

    my ($pkg, $name)
        = @_ == 1
        ? (scalar caller, @_)
        : @_;

    my $globref = qualify_to_ref($name => $pkg);

    $pkg  = *$globref{PACKAGE};
    $name = *$globref{NAME};

    if ($pkg->isa('Sub::Define::Interface')) {
        my $definer = $pkg->can('SUB_DEFINE_define_sub')
            or croak("$pkg doesn't define &define_sub");

        return $definer->($pkg, $name, $code);
    }

    my $old;
    $old = \&$globref if defined &$globref;

    my @warnings;
    eval {
        local $SIG{__WARN__} = sub { push @warnings, @_ };

        *$globref = $code;
    };

    if (@warnings) {
        my $currfile = quotemeta __FILE__;
        for my $w (@warnings) {
            $w =~ s/ at $currfile (?:line|chunk) \d+\.\n\z//
                or die "Internal error: '$currfile', '$w'";

            if ($w =~ /^Subroutine .*? redefined\z/) {
                warnings::warnif(redefine => $w)
                    unless defined wantarray;
            }
            elsif ($w =~ /^Prototype mismatch: sub /) {
                warnings::warnif(prototype => $w);
            }
            elsif ($w =~ /^Constant subroutine .*? redefined\z/) {
                warnings::warnif(severe => $w);
            }
            else {
                warn $w;
            }
        }
    }

    return $old;
}

sub Sub::Define::Interface::_dummy { return }

1;

__END__

=head1 NAME

Sub::Define - Easily define and redefine variably named subroutines


=head1 SYNOPSIS

    use Sub::Define qw/ define_sub /;

    define_sub(foo => sub { print "I'm &foo!" });

    my $old = define_sub('Bar::baz' => sub { print "I'm &Bar::baz!" });

    my $pkg = 'Zap';
    my $subname = 'zoop';
    my $code = sub { print "I'm &$pkg\::$subname!" };
    define_sub($pkg, $subname, $code);

    foo();
    Bar::baz();
    Zap::zoop();

    __END__
    I'm &foo!
    I'm &Bar::baz!
    I'm &Zap::zoop!


=head1 DESCRIPTION

This module makes it easier for you to define and redefine subroutines with variable names and in variable packages.

In order to support alternative package/class definitions any class can override the default behaviour.


=head1 FUNCTIONS

=over

=item my $old_code = define_sub($subname, $code);

The first argument is the name of the subroutine to define and is the subroutine reference which will become it's definition. If the subroutine name is unqualified the the current package will be used.

    package Foo;
    define_sub(foo => sub { ... };         # &Foo::foo
    define_sub('Bar::foo' => sub { ... }); # &Bar::foo

This is just like doing

    package Foo;
    *foo = sub { ... };
    *Bar::foo = sub { ... };

except you can use variables easily.

If C<&define_sub> is called in scalar or list context then a reference to any subroutine already used for C<$subname> is returned; otherwise a false value is returned. Calling C<&define_sub> in scalar or list context has the additional effect of silencing any "Subroutine %s redefined" warning.

(Note that just as

    package Foo;
    *ARGV = sub { ... };

puts the C<&ARGV> subroutine in the C<main> package instead of in C<Foo>, so does

    package Foo;
    define_sub(ARGV => sub { ... });

This applies to all symbols that resolve to the C<main> package when used unqualified. Fully qualified names aren't effected by this, just as they aren't in subroutine definitions.)

Note that if the default behaviour is overridden by the target package it's completely up to the author of that package to decide what it should do and warn about.

=item my $old_code = define_sub($pkg, $subname, $code);

If a package name is supplied at the beginning of the argument list, C<&define_sub> will treat it as if it was the current package.

    package Foo;
    define_sub('Zap', foo => sub { ... };         # &Zap::foo

The behaviour of

    define_sub('Zap', 'Bar::foo' => sub { ... }); # &Bar::foo

i.e. when you have a package name B<and> a fully qualified name is somewhat experimental.

=back


=head1 OVERRIDING C<&define_sub>

A package can override C<&define_sub> by providing a C<&SUB_DEFINE_define_sub> method and inheriting from C<Sub::Define::Interface>. C<Sub::Define::Interface> doesn't provide any functionality but is used to signal that C<&SUB_DEFINE_define_sub> in the package indeed is intended to override the default behaviour C<&define_sub>.

=head3 Example of overriding C<&define_sub>

Let's say we have a class where all subroutines are stored in a hash called C<%subs>. Thus, if you want to install a subroutine, you want to manipulate C<&subs> instead of the symbol table.

    package HashSubs;
    use Sub::Define; # create Sub::Define::Interface
    use base 'Sub::Define::Interface';

    my %subs = (
        foo => sub { "I'm foo!" };
        bar => sub { "I'm bar!" };
    );

    sub SUB_DEFINE_define_sub {
        my ($pkg, $name, $code) = @_;

        my $old = $subs{$name};
        $subs{$name} = $code;

        return $old;
    }

We can now, in any package, do

    use Sub::Define qw/ define_sub /;

    define_sub('HashSubs::baz' => sub { "I'm baz!" });

and the baz subroutine is correctly added.


=head1 EXAMPLES

All examples assume

    use Sub::Define qw/ define_sub /;

=head3 Generating subroutines

    for my $name (qw/ foo bar baz /) {
        define_sub(
            $name => sub {
                print "I'm $name!\n";
            }
        );
    }

    foo();
    bar();
    baz();

    __END__
    I'm foo!
    I'm bar!
    I'm baz!

=head3 Wrapping subroutines

    sub foo { print "old foo\n" }

    my $old;
    $old = define_sub(
        foo => sub {
            $old->();
            print "new foo\n";
        }
    );

    foo();

    __END__
    old foo
    new foo


=head1 AUTHOR

Johan Lodin <lodin@cpan.org>


=head1 COPYRIGHT

Copyright 2005 Johan Lodin. All rights reserved.

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.


=head1 SEE ALSO

L<Sub::Name|Sub::Name> - give internal name to anonymous subroutines (useful for getting informative error messages).

=cut
