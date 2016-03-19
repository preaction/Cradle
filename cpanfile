requires "Beam::Wire" => "1.019";
requires "Capture::Tiny" => "0";
requires "Email::Sender" => "0";
requires "Email::Simple" => "0";
requires "Git::Repository" => "0";
requires "Import::Base" => "0.012";
requires "Minion" => "4";
requires "Minion::Backend::SQLite" => "0";
requires "Mojolicious" => "6";
requires "Moo" => "2";
requires "Path::Tiny" => "0.072";
requires "Sys::Hostname" => "0";
requires "Time::Piece" => "0";
requires "Types::Path::Tiny" => "0";
requires "Types::Standard" => "0";
requires "perl" => "5.010";

on 'test' => sub {
  requires "ExtUtils::MakeMaker" => "0";
  requires "File::Spec" => "0";
  requires "IO::Handle" => "0";
  requires "IPC::Open3" => "0";
  requires "Test::Deep" => "0";
  requires "Test::Fatal" => "0";
  requires "Test::More" => "1.001005";
  requires "YAML" => "0";
};

on 'test' => sub {
  recommends "CPAN::Meta" => "2.120900";
};

on 'configure' => sub {
  requires "ExtUtils::MakeMaker" => "0";
};
