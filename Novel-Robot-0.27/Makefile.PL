
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "\x{5c0f}\x{8bf4}\x{4e0b}\x{8f7d}\x{5668}",
  "AUTHOR" => "abbypan <abbypan\@gmail.com>",
  "BUILD_REQUIRES" => {},
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Novel-Robot",
  "EXE_FILES" => [
    "bin/dzs_to_html.pl",
    "bin/dzs_to_wordpress.pl",
    "bin/get_novel.pl",
    "bin/novel_to_any.pl",
    "bin/novel_to_wordpress.pl",
    "bin/novel_txt_to_epub.pl"
  ],
  "LICENSE" => "perl",
  "NAME" => "Novel::Robot",
  "PREREQ_PM" => {
    "Encode::Locale" => 0,
    "JSON" => 0,
    "Moo" => 0,
    "Novel::Robot::Packer" => 0,
    "Novel::Robot::Parser" => 0,
    "Parallel::ForkManager" => 0,
    "Term::Menus" => 0
  },
  "TEST_REQUIRES" => {},
  "VERSION" => "0.27",
  "test" => {
    "TESTS" => ""
  }
);


my %FallbackPrereqs = (
  "Encode::Locale" => 0,
  "JSON" => 0,
  "Moo" => 0,
  "Novel::Robot::Packer" => 0,
  "Novel::Robot::Parser" => 0,
  "Parallel::ForkManager" => 0,
  "Term::Menus" => 0
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.63_03) } ) {
  delete $WriteMakefileArgs{TEST_REQUIRES};
  delete $WriteMakefileArgs{BUILD_REQUIRES};
  $WriteMakefileArgs{PREREQ_PM} = \%FallbackPrereqs;
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);



