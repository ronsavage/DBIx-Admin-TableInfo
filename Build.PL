use Module::Build;

Module::Build -> new
(
	module_name    => 'DBIx::Admin::TableInfo',
	license        => 'artistic_2',
	dist_abstract  => 'A wrapper for all of table_info(), column_info(), *_key_info()',
	dist_author    => 'Ron Savage <ron@savage.net.au>',
	build_requires =>
	{
		Test::More=> 0,
#		Test::Pod  => 1.45, # Make it optional. See t/pod.t
	},
	configure_requires =>
	{
		Module::Build => 0.3800,
	},
	requires =>
	{
		Data::Dumper::Concise => 2.020,
		DBI                   => 0,
		Hash::FieldHash       => 0.12,
		strict                => 0,
		warnings              => 0,
	},
) -> create_build_script();
