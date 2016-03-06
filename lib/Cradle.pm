package Cradle;
# ABSTRACT: Simple continuous integration system

=head1 SYNOPSIS

    ### Configure a job to build
    mkdir jobs/<job_name>

    # jobs/<job_name>/config.yml
    source: <git_url>
    steps:
        - perl Makefile.PL
        - make
        - make test

    ### Start a worker
    cradle minion worker

    ### Run a build
    cradle minion job -e build -a '["<job_name>"]'

=head1 DESCRIPTION

Cradle is a simple continuous integration (CI) server. CI servers will
test your project every time it is updated to ensure that it builds
successfully.  If the build fails, it will send a notification out so
that it can be fixed.

=cut

use strict;
use warnings;
use Mojo::Base 'Mojolicious';
use Path::Tiny qw( path );

sub startup {
    my ( $app ) = @_;

    $app->plugin( 'Config' );
    $app->plugin( 'Minion' => { SQLite => 'sqlite:data.db' } );

    $app->helper( root_dir => sub { state $root_dir = path( $app->home, 'jobs' ) } );

    $app->minion->add_task( build => sub {
        my ( $job, $name, @args ) = @_;
        my $app = $job->minion->app;
        my $log = $app->log;
        my $job_dir = $app->root_dir->child( $name );

        my $jobj = Cradle::Job->new(
            job_dir => $job_dir,
            log => $log,
        );
        my $result = $jobj->build;
        $job->finish( $result );
    } );
}



1;
__END__

