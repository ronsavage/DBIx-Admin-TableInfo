use strict;
use warnings;

use ExtUtils::MakeMaker;

# -----------------------------------------------

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

my(%params) =
(
	($] ge '5.005') ?
	(
		'AUTHOR'	=> 'Ron Savage (ron@savage.net.au)',
		'ABSTRACT'	=> 'A wrapper for all of table_info(), column_info(), *_key_info()',
    ) : (),
	clean			=>
	{
		FILES		=> 'blib/* Makefile MANIFEST DBIx-Admin-TableInfo-*'
	},
	dist			=>
	{
		COMPRESS	=> 'gzip',
		SUFFIX		=> 'gz'
	},
	DISTNAME		=> 'DBIx-Admin-TableInfo',
	NAME			=> 'DBIx::Admin::TableInfo',
	LICENSE   => 'artistic_2',
	PL_FILES		=> {},
	PREREQ_PM		=>
	{
		'Data::Dumper::Concise'        => 2.022,
		'DBI'                          => 0,
		'DBIx::Admin::CreateTable'     => 2.10,
		'DBIx::Admin::DSNManager'      => 2.01,
		'Lingua::EN::PluralToSingular' => 0.14,
		'Moo'                          => 1.004002,
		'strict'                       => 0,
		'Test::More'       	           => 0,
#		'Test::Pod'	                   => 1.45, # Make it optional. See t/pod.t
		'Test::Version'                => 1.002003,
		'Text::TabularDisplay'         => 1.38,
		'warnings'                     => 0,
	},
	VERSION_FROM	=> 'lib/DBIx/Admin/TableInfo.pm',
);

if ( ($ExtUtils::MakeMaker::VERSION =~ /^\d\.\d\d$/) && ($ExtUtils::MakeMaker::VERSION > 6.30) )
{
	$params{LICENSE} = 'artistic_2';
}

if ($ExtUtils::MakeMaker::VERSION ge '6.46')
{
	$params{META_MERGE} =
	{
		'meta-spec' =>
		{
			version => 2,
		},
		resources   =>
		{
			bugtracker => 'https://rt.cpan.org/Public/Dist/Display.html?Name=DBIx-Admin-TableInfo',
			license    => 'http://opensource.org/licenses/Artistic-2.0',
			repository =>
			{
				type => 'git',
				url  => 'https://github.com/ronsavage/DBIx-Admin-TableInfo.git',
				web  => 'https://github.com/ronsavage/DBIx-Admin-TableInfo',
			},
		},
	};
}

WriteMakefile(%params);
