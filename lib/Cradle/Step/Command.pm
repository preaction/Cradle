package Cradle::Step::Command;

# ABSTRACT: Run a command as a job step

use Cradle::Base 'Class';
use Capture::Tiny qw( capture );

=attr command

The command to run

=cut

has command => (
    is => 'ro',
    isa => Str,
    required => 1,
);

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

=method run

Execute the command. If the command exits with a non-zero status code, throws
an exception.

=cut

sub run {
    my ( $self, %args ) = @_;

    my $cmd = $self->command;
    $self->log->info( "Running command '$cmd'" );

    # Fork to ensure that the chdir doesn't affect everything
    # else running
    # XXX: Better fork error handling
    my $pid = fork;
    if ( $pid ) {
        # Parent process
        waitpid $pid, 0;
    }
    else {
        # Child process
        my $log_fh = $args{log_path}->openw;
        chdir $args{work_dir};

        capture { system $self->command } stdout => $log_fh, stderr => $log_fh;
        exit $? >> 8;
    }

    my $child_exit = $? >> 8;
    $self->log->info( "Done with '$cmd'. Exit code: $child_exit" );
    if ( $child_exit != 0 ) {
        die sprintf qq{Command "%s" exited non-zero "%s"\n},
            $self->command,
            $child_exit;
    }
    return;
}

1;
