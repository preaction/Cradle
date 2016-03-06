package Cradle::Source::Git;
# ABSTRACT: Get the project source through Git

=head1 SYNOPSIS

=head1 DESCRIPTION

This module tracks a project using Git.

=cut

use Cradle::Base 'Class';
use Git::Repository;
use Path::Tiny qw( cwd );

=attr remote_url

The URL of the git repository.

=cut

has url => (
    is => 'ro',
    isa => Str,
    required => 1,
);

=attr work_dir

The directory to use for the cloned repository. Set by Cradle.

=cut

has work_dir => (
    is => 'rw',
    isa => Path,
    coerce => Path->coercion,
);

=attr branch

The branch to build. Defaults to C<master>.

=cut

has branch => (
    is => 'ro',
    isa => Str,
    default => sub { 'master' },
);

=method update

Update the L<working directory|/work_dir> from the remote. Create the
C<work_dir> if necessary.

=cut

sub update {
    my ( $self ) = @_;

    if ( !$self->work_dir->exists ) {
        $self->work_dir->mkpath;
        my $cwd = cwd;
        chdir $self->work_dir;
        _run_git( 'Git::Repository', 'init' );
        chdir $cwd;

        my $repo = Git::Repository->new( work_tree => $self->work_dir );
        _run_git( $repo, remote => 'add', 'origin', $self->url );
    }
    my $repo = Git::Repository->new( work_tree => $self->work_dir );
    _run_git( $repo, pull => origin => $self->branch );
}

=method has_update

Returns true if the remote repository has an update for us.

=cut

sub has_update {
    my ( $self ) = @_;
    my $repo = Git::Repository->new( work_tree => $self->work_dir );

    my %remote;
    my $cmd = $repo->command( 'ls-remote', 'origin' );
    for my $line ( readline $cmd->stdout ) {
        my ( $commit, $ref ) = split /\s+/, $line, 2;
        chomp $ref;
        $remote{ $ref } = $commit;
    }

    my %local;
    $cmd = $repo->command( 'show-ref' );
    for my $line ( readline $cmd->stdout ) {
        my ( $commit, $ref ) = split /\s+/, $line, 2;
        chomp $ref;
        $local{ $ref } = $commit;
    }

    return 1 if $local{'refs/heads/' . $self->branch} ne $remote{'refs/heads/' . $self->branch};
}

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

sub _git_version {
    my $output = `git --version`;
    my ( $git_version ) = $output =~ /git version (\d+[.]\d+[.]\d+)/;
    return unless $git_version;
    my $v = sprintf '%i.%03i%03i', split /[.]/, $git_version;
    return $v;
}

1;

