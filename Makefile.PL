# This file was automatically generated by Dist::Zilla::Plugin::MakeMaker v5.036.
use strict;
use warnings;

use 5.010;

use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
  "ABSTRACT" => "Simple continuous integration system",
  "AUTHOR" => "Doug Bell <preaction\@cpan.org>",
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => 0
  },
  "DISTNAME" => "Cradle",
  "EXE_FILES" => [
    "bin/cradle"
  ],
  "LICENSE" => "perl",
  "MIN_PERL_VERSION" => "5.010",
  "NAME" => "Cradle",
  "PREREQ_PM" => {
    "Beam::Wire" => "1.019",
    "Capture::Tiny" => 0,
    "Email::Sender" => 0,
    "Email::Simple" => 0,
    "Git::Repository" => 0,
    "Import::Base" => "0.012",
    "Minion" => 4,
    "Minion::Backend::SQLite" => 0,
    "Mojolicious" => 6,
    "Moo" => 2,
    "Path::Tiny" => "0.072",
    "Sys::Hostname" => 0,
    "Time::Piece" => 0,
    "Types::Path::Tiny" => 0,
    "Types::Standard" => 0
  },
  "TEST_REQUIRES" => {
    "ExtUtils::MakeMaker" => 0,
    "File::Spec" => 0,
    "IO::Handle" => 0,
    "IPC::Open3" => 0,
    "Test::Deep" => 0,
    "Test::Fatal" => 0,
    "Test::More" => "1.001005",
    "YAML" => 0
  },
  "VERSION" => "0.001",
  "test" => {
    "TESTS" => "t/*.t t/notify/*.t t/source/*.t t/step/*.t"
  }
);


my %FallbackPrereqs = (
  "Beam::Wire" => "1.019",
  "Capture::Tiny" => 0,
  "Email::Sender" => 0,
  "Email::Simple" => 0,
  "ExtUtils::MakeMaker" => 0,
  "File::Spec" => 0,
  "Git::Repository" => 0,
  "IO::Handle" => 0,
  "IPC::Open3" => 0,
  "Import::Base" => "0.012",
  "Minion" => 4,
  "Minion::Backend::SQLite" => 0,
  "Mojolicious" => 6,
  "Moo" => 2,
  "Path::Tiny" => "0.072",
  "Sys::Hostname" => 0,
  "Test::Deep" => 0,
  "Test::Fatal" => 0,
  "Test::More" => "1.001005",
  "Time::Piece" => 0,
  "Types::Path::Tiny" => 0,
  "Types::Standard" => 0,
  "YAML" => 0
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.63_03) } ) {
  delete $WriteMakefileArgs{TEST_REQUIRES};
  delete $WriteMakefileArgs{BUILD_REQUIRES};
  $WriteMakefileArgs{PREREQ_PM} = \%FallbackPrereqs;
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);
