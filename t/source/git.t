
use Cradle::Base 'Test';
use Cradle::Source::Git;
use Git::Repository;

sub _run_git {
    my ( $git, @args ) = @_;
    my $cmd = $git->command( @args );
    my @stdout = readline $cmd->stdout;
    $cmd->close;
}

my $repo_root = tempdir;
Git::Repository->run( init => $repo_root );
my $repo = Git::Repository->new( work_tree => $repo_root );
$repo_root->child( 'README' )->spew( 'Hello, World' );
_run_git( $repo, add => 'README' );
_run_git( $repo, commit => '-m', 'add README' );

my $work_root = tempdir;
my $work_dir = $work_root->child( 'git' );

my $src = Cradle::Source::Git->new(
    url => 'file://' . $repo_root,
    work_dir => $work_dir,
    branch => 'master',
);

subtest 'initial clone' => sub {
    $src->update;
    ok $work_dir->child( 'README' )->is_file, 'expected file exists';
    is $work_dir->child( 'README' )->slurp, 'Hello, World', 'content is correct';
};

subtest 'check for updates' => sub {
    ok !$src->has_update, 'no updates yet';

    $repo_root->child( 'README' )->spew( 'Hello, Cleveland' );
    _run_git( $repo, add => 'README' );
    _run_git( $repo, commit => '-m', 'update README' );

    ok $src->has_update, 'updates can be fetched';
};

subtest 'fetch updates' => sub {
    $work_dir->child( 'build-artifact' )->spew( 'do not remove' );

    $src->update;

    ok $work_dir->child( 'build-artifact' )->exists, 'build artifact not cleaned';
    ok $work_dir->child( 'README' )->is_file, 'expected file exists';
    is $work_dir->child( 'README' )->slurp, 'Hello, Cleveland', 'content is correct';
};

done_testing;
