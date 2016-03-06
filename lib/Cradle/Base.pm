package Cradle::Base;
# ABSTRACT: Base set of modules for Cradle

=head1 SYNOPSIS

    use Cradle::Base;

    # lib/Cradle/Class.pm
    use Cradle::Base 'Class';

    # t/my_test.t
    use Cradle::Base 'Test';

=head1 DESCRIPTION

This module provides a base set of imports for other Cradle modules,
including L<strict>, L<warnings>, L<feature>, and others.

=cut

use strict;
use warnings;
use base 'Import::Base';

our @IMPORT_MODULES = (
    qw( strict warnings ),
    feature => [qw( :5.10 )],
);

our %IMPORT_BUNDLES = (
    Test => [
        qw( Test::More Test::Deep Test::Fatal ),
        'Path::Tiny' => [qw( tempdir )],
    ],
    Class => [
        qw( Moo ),
        'Types::Standard' => [qw( :all )],
        'Types::Path::Tiny' => [qw( Path )],
    ],
);

1;
