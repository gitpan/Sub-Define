use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'Sub::Define',
    VERSION_FROM => 'lib/Sub/Define.pm',
    AUTHOR       => 'Johan Lodin <lodin@cpan.org>',
    ABSTRACT     => 'Sub::Define',
    PREREQ_PM    => {
        Test::More => 0.45,
    },
);
