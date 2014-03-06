use strict;
use warnings;

use Module::Build;

my $class = Module::Build->subclass(code => <<'EOF');

sub ACTION_authortest
{
	my($self) = @_;

	$self->depends_on('build');
	$self->depends_on('manifest');
	$self->depends_on('distmeta');

	$self->test_files( qw< t xt/author > );
	$self->recursive_test_files(1);

	$self->depends_on('test');

	return;
}
EOF

$class -> new
(
	module_name    => 'DBIx::Admin::TableInfo',
	license        => 'artistic_2',
	dist_abstract  => 'A wrapper for all of table_info(), column_info(), *_key_info()',
	dist_author    => 'Ron Savage <ron@savage.net.au>',
	build_requires =>
	{
		'Test::More' => 0,
#		'Test::Pod'  => 1.45, # Make it optional. See t/pod.t
	},
	configure_requires =>
	{
		'Module::Build' => 0.3800,
	},
	requires =>
	{
		'Data::Dumper::Concise' => 2.021,
		'DBI'                   => 0,
		'Moo'                   => 1.004002,
		'strict'                => 0,
		'warnings'              => 0,
	},
	author_test_requires =>
	{
		'DBIx::Admin::CreateTable' => 2.09,
		'DBIx::Admin::DSNManager'  => 2.00,
	}
) -> create_build_script();
