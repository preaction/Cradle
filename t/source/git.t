
use Cradle::Base 'Test';
use Cradle::Source::Git;
use Git::Repository;
use Path::Tiny qw( cwd );

BEGIN {
    my $git_version = Cradle::Source::Git->_git_version;
    plan skip_all => 'Git not installed' unless $git_version;
    diag "Git version: $git_version";
    plan skip_all => 'Git 1.7.2 or higher required' unless $git_version >= 1.007002;
};

sub _run_git {
    my ( $git, @args ) = @_;
    my $cmdline = join " ", 'git', @args;
    my $cmd = $git->command( @args );
    my $stdout = join( "\n", readline( $cmd->stdout ) ) // '';
    my $stderr = join( "\n", readline( $cmd->stderr ) ) // '';
    $cmd->close;
    my $exit = $cmd->exit;

    if ( $exit ) {
        die "git $args[0] exited with $exit\n\n-- CMD --\n$cmdline\n\n-- STDOUT --\n$stdout\n\n-- STDERR --\n$stderr\n";
    }

    return $cmd->exit;
}

my $repo_root = tempdir;
my $cwd = cwd;
chdir $repo_root;
Git::Repository->run( 'init' );
chdir $cwd;
my $repo = Git::Repository->new( work_tree => $repo_root );

# Set some config so Git knows who we are (and doesn't complain)
_run_git( $repo, config => 'user.name' => 'Cradle Test User' );
_run_git( $repo, config => 'user.email' => 'cradle@example.com' );

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
