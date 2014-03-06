use strict;
use warnings;

use Data::Dumper::Concise; # For Dumper().

use DBI;

use DBIx::Admin::CreateTable;
use DBIx::Admin::DSNManager;
use DBIx::Admin::TableInfo;

use Moo;

has creator =>
(
	is       => 'rw',
	default  => sub{return '%'},
	required => 0,
);

has dsn_manager =>
(
	is       => 'rw',
	default  => sub{return '%'},
	required => 0,
);

# ---------------------------

my($dsn_manager) = DBIx::Admin::DSNManager -> new(file_name => 'xt/author/dsn.ini');
my($config)      = $dsn_manager -> config;
my(@table_name)  = (qw/one two/);

my($active, $attr);
my($creator);
my($dbh);
my($primary_key);
my($table_name, $table_manager, $table_info);
my($use_for_testing);

for my $db (keys %$config)
{
	$active = $$config{$db}{active} || 0;

	next if (! $active);

	$use_for_testing = $$config{$db}{use_for_testing} || 0;

	next if (! $use_for_testing);

	print "# Testing with $db\n";

	$attr    = $$config{$db}{attributes};
	$dbh     = DBI -> connect($$config{$db}{dsn}, $$config{$db}{username}, $$config{$db}{password}, $attr);
	$creator = DBIx::Admin::CreateTable -> new(dbh => $dbh);

	for $table_name (reverse @table_name)
	{
		print "# Dropping table '$table_name'. It may not exist\n";

		$creator -> drop_table($table_name);
	}

	for $table_name (@table_name)
	{
		$primary_key = $creator -> generate_primary_key_sql($table_name);

		print "# Creating table '$table_name'. It will not exist yet\n";
		print "# Primary key attributes: $primary_key\n";

		if ($table_name eq 'one')
		{
			$creator -> create_table(<<SQL);
create table $table_name
(
	id   $primary_key,
	data varchar(255)
)
SQL
		}
		else
		{
			$creator -> create_table(<<SQL);
create table $table_name
(
	id     $primary_key,
	one_id integer not null references one(id),
	data   varchar(255)
)
SQL
		}

		$table_manager = DBIx::Admin::TableInfo -> new(dbh => $dbh);
		$table_info    = $table_manager -> info;

		print Dumper($$table_info{$table_name});
	}

	for $table_name (reverse @table_name)
	{
		print "# Dropping table '$table_name'. It must exist now\n";

		$creator -> drop_table($table_name);
	}

	$dbh -> disconnect;

	print "#\n";
}
