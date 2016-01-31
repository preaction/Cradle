package Cradle;
# ABSTRACT: Simple continuous integration system

=head1 SYNOPSIS

    ### Configure a job to build
    # cradle.conf
    {
        jobs => {
            job_name => {
                source => '<git_url>',
                steps => [
                    'perl Makefile.PL',
                    'make',
                    'make test',
                ],
            },
        },
    }

    ### Start a worker
    cradle minion worker

    ### Run a build
    cradle minion job -e build -a '["job_name"]'

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
use Capture::Tiny qw( capture );

sub startup {
    my ( $app ) = @_;

    $app->plugin( 'Config' );
    $app->plugin( 'Minion' => { SQLite => 'sqlite:data.db' } );

    $app->helper( root_dir => sub { state $root_dir = path( $app->home, 'jobs' ) } );

    $app->minion->add_task( build => sub {
        my ( $job, $name, @args ) = @_;
        my $app = $job->minion->app;
        my $log = $app->log;
        my $conf = $app->config;
        my $job_conf = $conf->{jobs}{ $name };
        my $job_dir = $app->root_dir->child( $name );

        my $work_dir = $job_dir->child( 'work' );
        if ( !$work_dir->exists ) {
            my $source_dir = $job_conf->{source};
            system 'git', 'clone', $source_dir, $work_dir;
        }
        local $ENV{GIT_WORK_TREE} = $work_dir;
        local $ENV{GIT_DIR} = $work_dir->child( '.git' );
        system 'git', 'fetch', 'origin';
        system 'git', 'checkout', 'origin/master';

        $job_dir->child( 'build' )->mkpath;
        my $build_num = scalar $job_dir->child( 'build' )->children + 1;
        my $build_dir = $job_dir->child( 'build', $build_num );
        $build_dir->mkpath;
        my $build_log = $build_dir->child( 'build.log' );

        $log->info( "Starting '$name' build $build_num" );

        my @steps = @{ $job_conf->{steps} };
        for my $i ( 0..$#steps ) {
            my $step_num = $i + 1;
            my $step_cmd = $steps[$i];
            $log->info( "Running '$name' build $build_num step $step_num: $step_cmd" );
            my $pid = fork;
            if ( $pid ) {
                # Parent process
                waitpid $pid, 0;
            }
            else {
                # Child process
                delete $ENV{GIT_WORK_TREE};
                delete $ENV{GIT_DIR};

                my $build_fh = $build_log->openw;
                chdir $work_dir;

                capture { system $step_cmd } stdout => $build_fh, stderr => $build_fh;
                exit $? >> 8;
            }

            my $child_exit = $? >> 8;
            $log->info( "Done with '$name' step $step_num. Exit code: $child_exit" );
            if ( $child_exit ) {
                $log->info( "Step $step_num failed! Stopping!" );
                $job->finish( { status => 'failure', step => $step_num, exit => $child_exit } );
                return;
            }
        }

        $log->info( 'Job successful!' );
        $job->finish( { status => 'success' } );
    } );

}



1;
__END__

