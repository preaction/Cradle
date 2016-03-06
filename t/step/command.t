
use Cradle::Base 'Test';
use Cradle::Step::Command;

subtest 'simple command' => sub {
    my $tmp = tempdir;

    my $step = Cradle::Step::Command->new(
        command => 'echo Hello',
    );
    my $log_path = $tmp->child( 'build.log' );
    my $work_dir = $tmp->child( 'work' );
    $work_dir->mkpath;

    $step->run( log_path => $log_path, work_dir => $work_dir );
    is $log_path->slurp, "Hello\n", 'command is run and log path has stdout';
};

subtest 'command with stderr' => sub {
    my $tmp = tempdir;

    my $step = Cradle::Step::Command->new(
        command => 'echo Hello >&2',
    );
    my $log_path = $tmp->child( 'build.log' );
    my $work_dir = $tmp->child( 'work' );
    $work_dir->mkpath;

    $step->run( log_path => $log_path, work_dir => $work_dir );
    is $log_path->slurp, "Hello\n", 'command is run and log path has stderr';
};

subtest 'command with nonzero exit' => sub {
    my $tmp = tempdir;

    my $step = Cradle::Step::Command->new(
        command => 'echo Hello && exit 1',
    );
    my $log_path = $tmp->child( 'build.log' );
    my $work_dir = $tmp->child( 'work' );
    $work_dir->mkpath;

    is exception {
        $step->run( log_path => $log_path, work_dir => $work_dir )
    }, qq{Command "echo Hello && exit 1" exited non-zero "1"\n},
        'step fails and throws exception';

    is $log_path->slurp, "Hello\n", 'command is run and log path has stdout';
};

done_testing;
