use strict;
use warnings;

use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

WriteMakefile
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
		'Data::Dumper::Concise'    => 2.021,
		'DBI'                      => 0,
		'DBIx::Admin::CreateTable' => 2.09,
		'DBIx::Admin::DSNManager'  => 2.00,
		'Moo'                      => 1.004002,
		'strict'                   => 0,
		'Test::More'   	           => 0,
#		'Test::Pod'	               => 1.45, # Make it optional. See t/pod.t
		'warnings'                 => 0,
	},
	VERSION_FROM	=> 'lib/DBIx/Admin/TableInfo.pm',
);
