package Cradle::Job;

# ABSTRACT: A single job to build

=head1 SYNOPSIS

=head1 DESCRIPTION

This class contains a single, configured job.

=cut

use Cradle::Base 'Class';
use Beam::Wire;
use Cradle::Source::Git;
use Cradle::Step::Command;
use Time::Piece;
use YAML;

=attr job_dir

The directory for this job.

=cut

has job_dir => (
    is => 'ro',
    isa => Path,
    coerce => Path->coercion,
    required => 1,
);

=attr name

The name of this job. Defaults to the last part of L<the job dir|/job_dir>.

=cut

has name => (
    is => 'ro',
    isa => Str,
    lazy => 1,
    default => sub { $_[0]->job_dir->basename },
);

=attr config_file

The path to the config file for this job.

=cut

has config_file => (
    is => 'ro',
    isa => Path,
    coerce => Path->coercion,
    lazy => 1,
    default => sub {
        my ( $self ) = @_;
        return $self->job_dir->child( 'config.yml' );
    },
);

=attr container

The L<Beam::Wire container|Beam::Wire> to get this job's details.

=cut

has container => (
    is => 'ro',
    isa => InstanceOf['Beam::Wire'],
    lazy => 1,
    default => sub {
        my ( $self ) = @_;
        return Beam::Wire->new( file => $self->config_file );
    },
);

=attr source

    # config.yml
    source: https://github.com/preaction/Cradle.git

    source:
        $class: Cradle::Source::Git
        url: https://github.com/preaction/Cradle.git

L<The Cradle::Source object|Cradle::Source> for this job. By default
found in the C<source> key of the configuration file.

=cut

has source => (
    is => 'ro',
    isa => Object,
    lazy => 1,
    builder => '_build_source',
);

sub _build_source {
    my ( $self ) = @_;
    my $source = $self->container->get( 'source' );
    if ( !ref $source ) {
        $source = Cradle::Source::Git->new(
            url => $source,
        );
    }
    $source->work_dir( $self->job_dir->child( 'work' ) );
    return $source;
}

=attr steps

    # config.yml
    steps:
        - perl Makefile.PL
        - make
        - make test

=cut

has steps => (
    is => 'ro',
    isa => ArrayRef,
    lazy => 1,
    builder => '_build_steps',
);

sub _build_steps {
    my ( $self ) = @_;
    my @in_steps = @{ $self->container->get( 'steps' ) };
    my @out_steps;
    for my $in_step ( @in_steps ) {
        if ( !ref $in_step ) {
            push @out_steps, Cradle::Step::Command->new(
                command => $in_step,
            );
        }
        else {
            push @out_steps, $in_step;
        }
    }
    return \@out_steps;
}

=attr log

The L<Mojo::Log object|Mojo::Log> to use for logging.

=cut

has log => (
    is => 'rw',
    isa => InstanceOf['Mojo::Log'],
    default => sub {
        require Mojo::Log;
        Mojo::Log->new;
    },
);

=method build

Update the source, if necessary, and run the job steps, sending out the
appropriate notifications.

=cut

sub build {
    my ( $self ) = @_;

    my $start = Time::Piece->new->datetime;
    my $job_dir = $self->job_dir;

    $job_dir->child( 'build' )->mkpath;
    my $build_num = scalar $job_dir->child( 'build' )->children + 1;
    my $build_dir = $job_dir->child( 'build', $build_num );
    $build_dir->mkpath;
    my $build_log = $build_dir->child( 'build.log' );

    $self->log->info( sprintf q{Starting job "%s" build %i}, $self->name, $build_num );

    my %step_args = (
        log_path => $build_log,
        work_dir => $build_dir,
    );

    my @steps = @{ $self->steps };
    for my $i ( 0..$#steps ) {
        my $step_num = $i + 1;
        $self->log->info( "Running step $step_num" );
        my $step = $steps[$i];
        eval { $step->run( %step_args ) };
        if ( my $error = $@ ) {
            $self->log->info( "Step $step_num failed! Stopping! Error: $error" );
            my $result = {
                start => $start,
                end => Time::Piece->new->datetime,
                build_number => $build_num,
                status => 'failure',
                step => $step_num,
                error => $error,
            };
            $self->_write_result( $build_dir, $result );
            return $result;
        }
    }

    $self->log->info( 'Job successful!' );
    my $result = {
        start => $start,
        end => Time::Piece->new->datetime,
        build_number => $build_num,
        status => 'success',
    };
    $self->_write_result( $build_dir, $result );
    return $result;
}

sub _write_result {
    my ( $self, $build_dir, $result ) = @_;
    my $yaml = YAML::Dump( $result );
    $build_dir->child( 'build.yml' )->spew_utf8( $yaml );
    my $job_dir = $build_dir->parent( 2 );
    $job_dir->child( 'last_build.yml' )->spew_utf8( $yaml );
    if ( $result->{status} eq 'success' ) {
        $job_dir->child( 'last_success.yml' )->spew_utf8( $yaml );
    }
    else {
        $job_dir->child( 'last_failure.yml' )->spew_utf8( $yaml );
    }
}

1;
