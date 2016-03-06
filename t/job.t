
use Cradle::Base 'Test';
use Cradle::Job;
use YAML;

subtest 'basic job' => sub {
    my $tmp = tempdir;
    my $job = Cradle::Job->new(
        job_dir => $tmp->child( 'job' ),
        steps => [
            Cradle::Step::Command->new(
                command => 'echo Hello',
            ),
        ],
    );

    my $result = $job->build;

    ok $tmp->child( 'job' )->is_dir, 'job dir is created';
    ok $tmp->child( 'job', 'build' )->is_dir, 'job build dir is created';
    ok $tmp->child( 'job', 'build', '1' )->is_dir, 'job has one build';
    is $tmp->child( qw( job build 1 build.log ) )->slurp, "Hello\n",
        'build 1 log has command output';

    is $result->{status}, 'success', 'status is success';
};

subtest 'job failure' => sub {
    my $tmp = tempdir;
    my $job = Cradle::Job->new(
        job_dir => $tmp->child( 'job' ),
        steps => [
            Cradle::Step::Command->new(
                command => 'echo Hello && exit 1',
            ),
        ],
    );

    my $result = $job->build;

    ok $tmp->child( 'job' )->is_dir, 'job dir is created';
    ok $tmp->child( 'job', 'build' )->is_dir, 'job build dir is created';
    ok $tmp->child( 'job', 'build', '1' )->is_dir, 'job has one build';
    is $tmp->child( qw( job build 1 build.log ) )->slurp, "Hello\n",
        'build 1 log has command output';

    is $result->{status}, 'failure', 'status is failure';
    is $result->{step}, 1, 'failed on step 1';
    is $result->{error}, qq{Command "echo Hello && exit 1" exited non-zero "1"\n},
        'error from step object is correct';
};

subtest 'load config' => sub {
    my $config = {
        source => 'https://github.com/preaction/Cradle.git',
        steps => [
            'perl Makefile.PL',
            'make',
            'make test',
        ],
    };

    my $tmp = tempdir;
    my $job_dir = $tmp->child( 'job_name' );
    $job_dir->child( 'config.yml' )->touchpath->spew_utf8( YAML::Dump( $config ) );

    my $job = Cradle::Job->new(
        job_dir => $job_dir,
    );

    is $job->name, 'job_name', 'job name is name of job directory';
    isa_ok $job->source, 'Cradle::Source::Git', 'source is created from string';
    my @steps = @{ $job->steps };
    is scalar @steps, 3, 'three steps created';
    isa_ok $steps[0], 'Cradle::Step::Command';
    is $steps[0]->command, 'perl Makefile.PL', 'step 1 command is correct';
    isa_ok $steps[1], 'Cradle::Step::Command';
    is $steps[1]->command, 'make', 'step 2 command is correct';
    isa_ok $steps[2], 'Cradle::Step::Command';
    is $steps[2]->command, 'make test', 'step 3 command is correct';
};

done_testing;