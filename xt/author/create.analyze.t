use strict;
use warnings;

use Data::Dumper::Concise; # For Dumper().

use DBI;

use DBIx::Admin::CreateTable;
use DBIx::Admin::DSNManager;
use DBIx::Admin::TableInfo;

use Moo;

use Test::More;

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
my($test_count)  = 0;

my($active, $attr);
my($creator);
my($dsn, $dbh);
my($primary_key);
my($schema);
my($table_name, $table_manager, $table_info);
my($use_for_testing);

for my $db (keys %$config)
{
	$active = $$config{$db}{active} || 0;

	next if (! $active);

	$use_for_testing = $$config{$db}{use_for_testing} || 0;

	next if (! $use_for_testing);

	diag "Testing with $db\n";

	$dsn     = $$config{$db}{dsn};
	$attr    = $$config{$db}{attributes};
	$dbh     = DBI -> connect($dsn, $$config{$db}{username}, $$config{$db}{password}, $attr);
	$creator = DBIx::Admin::CreateTable -> new(dbh => $dbh);

	# Drop tables if they exist.

	for $table_name (reverse @table_name)
	{
		diag "Dropping table '$table_name'. It may not exist\n";

		$creator -> drop_table($table_name);

		ok(1, 'Deleted table which may not exist');

		$test_count++;
	}

	# Create tables.

	for $table_name (@table_name)
	{
		$primary_key = $creator -> generate_primary_key_sql($table_name);

		diag " Creating table '$table_name'. It will not exist yet\n";
		diag " Primary key attributes: $primary_key\n";

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
	}

	# Process tables.

	$schema = $dsn =~ /^dbi:Oracle/i
				? uc $ENV{DBI_USER}
				: $dsn =~ /^dbi:Pg/i
				? 'public'
				: undef; # MySQL, SQLite.
	$table_manager = DBIx::Admin::TableInfo -> new(dbh => $dbh, schema => $schema);
	$table_info    = $table_manager -> info;

	for $table_name (@table_name)
	{
		diag '-' x 50;
		diag "Dumping table info for table '$table_name'";
		diag Dumper($$table_info{$table_name});
		diag "Dumped table info for table '$table_name'";
	}

	diag '-' x 50;
	diag Dumper($table_info);
	diag '-' x 50;

	# Drop tables to clean up.

	for $table_name (reverse @table_name)
	{
		diag "# Dropping table '$table_name'. It must exist now\n";

		$creator -> drop_table($table_name);

		ok(1, 'Deleted table which must exist');

		$test_count++;
	}

	$dbh -> disconnect;

	diag;
}

done_testing($test_count);
