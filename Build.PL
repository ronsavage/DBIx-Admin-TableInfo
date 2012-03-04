use Module::Build;

Module::Build -> new
(
 module_name    => 'DBIx::Admin::TableInfo',
 license        => 'artistic',
 dist_abstract  => 'A wrapper for all of table_info(), column_info(), *_key_info()',
 dist_author    => 'Ron Savage <ron@savage.net.au>',
 build_requires =>
 {
	 Test::More => 0,
	 Test::Pod  => 0,
 },
 configure_requires =>
 {
	 Module::Build => 0.3800,
 },
 requires =>
 {
	 Carp => 0,
	 DBI  => 0,
 },
) -> create_build_script();
