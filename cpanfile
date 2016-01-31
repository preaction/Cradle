requires "Capture::Tiny" => "0";
requires "Minion" => "4";
requires "Minion::Backend::SQLite" => "0";
requires "Mojolicious" => "6";
requires "Path::Tiny" => "0.072";
requires "perl" => "5.010";

on 'test' => sub {
  requires "ExtUtils::MakeMaker" => "0";
  requires "File::Spec" => "0";
  requires "IO::Handle" => "0";
  requires "IPC::Open3" => "0";
  requires "Test::More" => "1.001005";
};

on 'test' => sub {
  recommends "CPAN::Meta" => "2.120900";
};

on 'configure' => sub {
  requires "ExtUtils::MakeMaker" => "0";
};
