package DBIx::Admin::TableInfo;

use strict;
use warnings;
no warnings 'redefine';

use Hash::FieldHash ':all';

fieldhash my %catalog => 'catalog';
fieldhash my %dbh     => 'dbh';
fieldhash my %info    => 'info';
fieldhash my %schema  => 'schema';
fieldhash my %table   => 'table';
fieldhash my %type    => 'type';

our $VERSION = '2.08';

# -----------------------------------------------

sub columns
{
	my($self, $table, $by_position) = @_;
	my($info) = $self -> info;

	if ($by_position)
	{
		return [sort{$$info{$table}{columns}{$a}{ORDINAL_POSITION} <=> $$info{$table}{columns}{$b}{ORDINAL_POSITION} } keys %{$$info{$table}{columns} }];
	}
	else
	{
		return [sort{$a cmp $b} keys %{$$info{$table}{columns} }];
	}

}	# End of columns.

# -----------------------------------------------

sub _info
{
	my($self)      = @_;
	my($info)      = {};
	my($vendor)    = uc $self -> dbh -> get_info(17); # SQL_DBMS_NAME.
	my($table_sth) = $self -> dbh -> table_info($self -> catalog, $self -> schema, $self -> table, $self -> type);

	my($column_data, $column_name, $column_sth, $count);
	my($foreign_table);
	my($primary_key_info);
	my($table_data, $table_name, @table_name);

	while ($table_data = $table_sth -> fetchrow_hashref() )
	{
		$table_name = $$table_data{TABLE_NAME};

		next if ( ($vendor eq 'ORACLE')     && ($table_name =~ /^BIN\$.+\$./) );
		next if ( ($vendor eq 'POSTGRESQL') && ($table_name =~ /^(?:pg_|sql_)/) );
		next if ( ($vendor eq 'SQLITE')     && ($table_name eq 'sqlite_sequence') );

		$$info{$table_name} =
		{
			attributes   => {%$table_data},
			columns      => {},
			foreign_keys => {},
			primary_keys => {},
		};
		$column_sth       = $self -> dbh -> column_info($self -> catalog, $self -> schema, $table_name, '%');
		$primary_key_info = [];

		push @table_name, $table_name;

		while ($column_data = $column_sth -> fetchrow_hashref() )
		{
			$column_name                               = $$column_data{COLUMN_NAME};
			$$info{$table_name}{columns}{$column_name} = {%$column_data};

			push @$primary_key_info, $column_name if ( ($vendor eq 'MYSQL') && $$column_data{mysql_is_pri_key});
		}

		if ($vendor eq 'MYSQL')
		{
			$count = 0;

			for (@$primary_key_info)
			{
				$count++;

				$$info{$table_name}{primary_keys}{$_}              = {} if (! $$info{$table_name}{primary_keys}{$_});
				$$info{$table_name}{primary_keys}{$_}{COLUMN_NAME} = $_;
				$$info{$table_name}{primary_keys}{$_}{KEY_SEQ}     = $count;
			}
		}
		else
		{
			$column_sth = $self -> dbh -> primary_key_info($self -> catalog, $self -> schema, $table_name);

			if (defined $column_sth)
			{
				for $column_data (@{$column_sth -> fetchall_arrayref({})})
				{
					$$info{$table_name}{primary_keys}{$$column_data{COLUMN_NAME} } = {%$column_data};
				}
			}
		}
	}

	my(%referential_action) =
	(
		'CASCADE'     => 0,
		'RESTRICT'    => 1,
		'SET NULL'    => 2,
		'NO ACTION'   => 3,
		'SET DEFAULT' => 4,
	);

	for $table_name (@table_name)
	{
		for $foreign_table (grep{! /^$table_name$/} @table_name)
		{
			if ($vendor eq 'SQLITE')
			{
				for my $row (@{$self -> dbh -> selectall_arrayref("pragma foreign_key_list($foreign_table)")})
				{
					next if ($$row[2] ne $table_name);

					$$info{$table_name}{foreign_keys}{$foreign_table} =
					{
						DEFERABILITY      => undef,
						DELETE_RULE       => $referential_action{$$row[6]},
						FK_COLUMN_NAME    => $$row[3],
						FK_DATA_TYPE      => undef,
						FK_NAME           => undef,
						FK_TABLE_CAT      => undef,
						FK_TABLE_NAME     => $foreign_table,
						FK_TABLE_SCHEM    => undef,
						ORDINAL_POSITION  => $$row[1],
						UK_COLUMN_NAME    => $$row[4],
						UK_DATA_TYPE      => undef,
						UK_NAME           => undef,
						UK_TABLE_CAT      => undef,
						UK_TABLE_NAME     => $table_name,
						UK_TABLE_SCHEM    => undef,
						UNIQUE_OR_PRIMARY => undef,
						UPDATE_RULE       => $referential_action{$$row[5]},
					};
				}
			}
			else
			{
				$table_sth = $self -> dbh -> foreign_key_info($self -> catalog, $self -> schema, $table_name, $self -> catalog, $self -> schema, $foreign_table) || next;

				for $column_data (@{$table_sth -> fetchall_arrayref({})})
				{
					$$info{$table_name}{foreign_keys}{$foreign_table} = {%$column_data};
				}
			}
		}
	}

	$self -> info($info);

}	# End of _info.

# -----------------------------------------------

sub _init
{
	my($self, $arg) = @_;
	$$arg{catalog}  ||= undef;   # Caller can set.
	$$arg{dbh}      ||= '';      # Caller can set.
	$$arg{info}     = {};
	$$arg{schema}   ||= undef;   # Caller can set.
	$$arg{table}    ||= '%';     # Caller can set.
	$$arg{type}     ||= 'TABLE'; # Caller can set.
	$self           = from_hash($self, $arg);

	die "The 'dbh' parameter to new() is mandatory\n" if (! $self -> dbh);

	return $self;

} # End of _init.

# -----------------------------------------------

sub new
{
	my($class, %arg) = @_;
	my($self)        = bless {}, $class;
	$self            = $self -> _init(\%arg);

	$self -> _info;

	return $self;

}	# End of new.

# -----------------------------------------------

sub refresh
{
	my($self) = @_;

	$self -> _info();

	return $self -> info;

}	# End of refresh.

# -----------------------------------------------

sub tables
{
	my($self) = @_;

	return [sort keys %{$self -> info}];

}	# End of tables.

# -----------------------------------------------

1;

__END__

=head1 NAME

DBIx::Admin::TableInfo - A wrapper for all of table_info(), column_info(), *_key_info()

=head1 Synopsis

This program is shipped as examples/table.info.pl.

	#!/usr/bin/env perl

	use strict;
	use warnings;

	use Data::Dumper::Concise;
	use DBI;
	use DBIx::Admin::TableInfo 2.08;

	# ---------------------

	my($attr)              = {};
	$$attr{sqlite_unicode} = 1 if ($ENV{DBI_DSN} =~ /SQLite/i);
	my($dbh)               = DBI -> connect($ENV{DBI_DSN}, $ENV{DBI_USER}, $ENV{DBI_PASS}, $attr);

	$dbh -> do('PRAGMA foreign_keys = ON') if ($ENV{DBI_DSN} =~ /SQLite/i);

	my($schema) = $ENV{DBI_DSN} =~ /^dbi:Oracle/i
		? uc $ENV{DBI_USER}
		: $ENV{DBI_DSN} =~ /^dbi:Pg/i
		? 'public'
		: undef;

	print Data::Dumper -> Dump
	([
		DBIx::Admin::TableInfo -> new(dbh => $dbh, schema => $schema) -> info()
	]);

See docs/contacts.*.log for sample output. The input to these runs is the database created by the module
L<App::Office::Contacts>, with its config file first set for Postgres and then for SQLite.

=head1 Description

C<DBIx::Admin::TableInfo> is a pure Perl module.

It is a convenient wrapper around all of these DBI methods:

=over 4

=item o table_info()

=item o column_info()

=item o primary_key_info()

=item o foreign_key_info()

=back

Warnings:

=over 4

=item o MySQL

=over 4

=item o New Notes

I am testing V 2.04 of this module with MySql V 5.0.51a and DBD::mysql V 4.014.

To get foreign key information in the output, the create table statement has to:

=over 4

=item o Include an index clause

=item o Include a foreign key clause

=item o Include an engine clause

As an example, a column definition for Postgres and SQLite, which looks like:

	site_id integer not null references sites(id),

has to, for MySql, look like:

	site_id integer not null, index (site_id), foreign key (site_id) references sites(id),

Further, the create table statement, which for Postgres and SQLite looks like:

	create table designs (...)

has to, for MySql, look like:

	create table designs (...) engine=innodb

You have been warned.

=back

=item o Old Notes

The MySQL client C<DBD::mysql> V 3.0002 does not support C<primary_key_info()>,
so this module emulates it by stockpiling a list of columns which have the
attribute 'mysql_is_pri_key' set.

The problem with this is that if a primary key consists of more than 1 column,
C<DBD::mysql> does not indicate the order of these columns within the key, so
this module pretends that they are in the same order as the order of columns
returned by the call to C<column_info()>.

Likewise, C<DBD::mysql> does not support C<foreign_key_info()>, so in the case
of MySQL, nothing is reported for foreign keys.

For MySQL V 5.0.18, section 14.2.6.4 of the manual says that for InnoDB tables,
the SQL "show table status from 'db name' like 'table name'" will display the foreign
key info in the column called 'Comment', but this is simply not true. The 'Comment'
column contains a string such as 'InnoDB free: 4096 kB'.

Likewise, the SQL "show create table 'table name'" reveals than MySQL does not
preserve 'create table' clauses such as 'references other_table(other_column)'.

So, at the moment, I see no way of displaying foreign key information under MySQL.

=back

=item o Oracle

See the L</FAQ> for which tables are ignored under Oracle.

=item o Postgres

I am testing V 2.04 of this module with Postgres V 08.03.1100 and DBD::Pg V 2.17.1.

The latter now takes '%' as the value of the 'table' parameter to new(), whereas
older versions of DBD::Pg required 'table' to be set to 'table'.

See the L</FAQ> for which tables are ignored under Postgres.

=item o SQLite

I am testing V 2.04 of this module with SQLite V 3.6.22 and DBD::SQLite V 1.29.

See the L</FAQ> for which tables are ignored under SQLite.

=back

=head1 Distributions

This module is available both as a Unix-style distro (*.tgz) and an
ActiveState-style distro (*.ppd). The latter is shipped in a *.zip file.

See http://savage.net.au/Perl-modules.html for details.

See http://savage.net.au/Perl-modules/html/installing-a-module.html for
help on unpacking and installing each type of distro.

=head1 Constructor and initialization

new(...) returns a C<DBIx::Admin::TableInfo> object.

This is the class contructor.

Usage: DBIx::Admin::TableInfo -> new().

This method takes a set of parameters. Only the dbh parameter is mandatory.

For each parameter you wish to use, call new as new(param_1 => value_1, ...).

=over 4

=item o catalog

This is the value passed in as the catalog parameter to table_info() and column_info().

The default value is undef.

undef was chosen because it given the best results with MySQL.

Note: The MySQL driver DBD::mysql V 2.9002 has a bug in it, in that it aborts if an empty string is used here,
even though the DBI docs say an empty string can be used for the catalog parameter to C<table_info()>.

This parameter is optional.

=item o dbh

This is a database handle.

This parameter is mandatory.

=item o schema

This is the value passed in as the schema parameter to table_info() and column_info().

The default value is undef.

Note: If you are using Oracle, call C<new()> with schema set to uc $user_name.

Note: If you are using Postgres, call C<new()> with schema set to 'public'.

This parameter is optional.

=item o table

This is the value passed in as the table parameter to table_info().

The default value is '%'.

Note: If you are using an 'old' version of DBD::Pg, call C<new()> with table set to 'table'.

Sorry - I cannot tell you exactly what 'old' means. As stated above, the default value (%)
works fine with DBD::Pg V 2.17.1.

This parameter is optional.

=item o type

This is the value passed in as the type parameter to table_info().

The default value is 'TABLE'.

This parameter is optional.

=back

=head1 Method: columns($table_name, $by_position)

Returns an array ref of column names.

By default they are sorted by name.

However, if you pass in a true value for $by_position, they are sorted by the column attribute ORDINAL_POSITION. This is Postgres-specific.

=head1 Method: info()

Returns a hash ref of all available data.

The structure of this hash is described next:

=over 4

=item o First level: The keys are the names of the tables

	my($info)       = $obj -> info();
	my(@table_name) = sort keys %$info;

I use singular names for my arrays, hence @table_name rather than @table_names.

=item o Second level: The keys are 'attributes', 'columns', 'foreign_keys' and 'primary_keys'

	my($table_attributes) = $$info{$table_name}{attributes};

This is a hash ref of the attributes of the table.
The keys of this hash ref are determined by the database server.

	my($columns) = $$info{$table_name}{columns};

This is a hash ref of the columns of the table. The keys of this hash ref are the names of the columns.

	my($foreign_keys) = $$info{$table_name}{foreign_keys};

This is a hash ref of the foreign keys of the table. The keys of this hash ref are the names of the tables
which contain foreign keys pointing to $table_name.

For MySQL, $foreign_keys will be the empty hash ref {}, as explained above.

	my($primary_keys) = $$info{$table_name}{primary_keys};

This is a hash ref of the primary keys of the table. The keys of this hash ref are the names of the columns
which make up the primary key of $table_name.

For any database server, if there is more than 1 column in the primary key, they will be numbered
(ordered) according to the hash key 'KEY_SEQ'.

For MySQL, if there is more than 1 column in the primary key, they will be artificially numbered
according to the order in which they are returned by C<column_info()>, as explained above.

=item o Third level, after 'attributes': Table attributes

	my($table_attributes) = $$info{$table_name}{attributes};

	while ( ($name, $value) = each(%$table_attributes) )
	{
		Use...
	}

For the attributes of the tables, there are no more levels in the hash ref.

=item o Third level, after 'columns': The keys are the names of the columns.

	my($columns) = $$info{$table_name}{columns};

	my(@column_name) = sort keys %$columns;

=over 4

=item o Fourth level: Column attributes

	for $column_name (@column_name)
	{
	    while ( ($name, $value) = each(%{$columns{$column_name} }) )
	    {
		    Use...
	    }
	}

=back

=item o Third level, after 'foreign_keys': The keys are the names of tables

These tables have foreign keys which point to the current table.

	my($foreign_keys) = $$info{$table_name}{foreign_keys};

	for $foreign_table (sort keys %$foreign_keys)
	{
		$foreign_key = $$foreign_keys{$foreign_table};

		for $attribute (sort keys %$foreign_key)
		{
			Use...
		}
	}

=item o Third level, after 'primary_keys': The keys are the names of columns

These columns make up the primary key of the current table.

	my($primary_keys) = $$info{$table_name}{primary_keys};

	for $primary_key (sort{$$a{KEY_SEQ} <=> $$b{KEY_SEQ} } keys %$primary_keys)
	{
		$primary = $$primary_keys{$primary_key};

		for $attribute (sort keys %$primary)
		{
			Use...
		}
	}

=back

=head1 Method: refresh()

Returns the same hash ref as info().

Use this after changing the database schema, when you want this module to re-interrogate
the database server.

=head1 Method: tables()

Returns an array ref of table names.

They are sorted by name.

See the L</FAQ> for which tables are ignored under which databases.

=head1 Example code

Here are tested parameter values for various database vendors:

=over 4

=item o MS Access

	my($admin) = DBIx::Admin::TableInfo -> new(dbh => $dbh);

	In other words, the default values for catalog, schema, table and type will Just Work.

=item o MySQL

	my($admin) = DBIx::Admin::TableInfo -> new(dbh => $dbh);

	In other words, the default values for catalog, schema, table and type will Just Work.

=item o Oracle

	my($dbh)   = DBI -> connect($dsn, $username, $password);
	my($admin) = DBIx::Admin::TableInfo -> new
	(
		dbh    => $dbh,
		schema => uc $username, # Yep, upper case.
	);

	See the FAQ for which tables are ignored under Oracle.

=item o PostgreSQL

	my($admin) = DBIx::Admin::TableInfo -> new
	(
		dbh    => $dbh,
		schema => 'public',
	);

	For PostgreSQL, you probably want to ignore table names matching /^(pg_|sql_)/.

	As stated above, for 'old' versions of DBD::Pg, use:

	my($admin) = DBIx::Admin::TableInfo -> new
	(
		dbh    => $dbh,
		schema => 'public',
		table  => 'table', # Yep, lower case.
	);

	See the FAQ for which tables are ignored under Postgres.

=item o SQLite

	my($admin) = DBIx::Admin::TableInfo -> new(dbh => $dbh);

	In other words, the default values for catalog, schema, table and type will Just Work.

	See the FAQ for which tables are ignored under SQLite.

=back

See the examples/ directory in the distro.

=head1 Tested Database Formats

The first set of tests was done with C<DBIx::Admin::TableInfo> up to V 2.03,
using examples/table.info.pl (as per the Synopsis):

=over 4

=item o MS Access V 2

Yes, some businesses were still running V 2 as of July, 2004.

=item o MS Access V 2002 and V 2003

=item o MySQL V 4 and V 5

=item o Oracle V 9.2.0

=item o PostgreSQL V 7.3, 8.1

=back

The second set of tests was done with C<DBIx::Admin::TableInfo> V 2.04, also using
examples/table.info.pl.

=over 4

=item o MySql V 5.0.51a and DBD::mysql V 4.014

=item o Postgres V 08.03.1100 and DBD::Pg V 2.17.1.

=item o SQLite V 3.6.22 and DBD::SQLite V 1.29.

=back

=head1 FAQ

=head2 Which tables are ignored for which databases?

Here is the code which skips some tables:

	next if ( ($vendor eq 'ORACLE')     && ($table_name =~ /^BIN\$.+\$./) );
	next if ( ($vendor eq 'POSTGRESQL') && ($table_name =~ /^(?:pg_|sql_)/) );
	next if ( ($vendor eq 'SQLITE')     && ($table_name eq 'sqlite_sequence') );

=head2 Does DBIx::Admin::TableInfo work with SQLite databases?

Yes. As of V 2.08, this module uses SQLite's "pragma foreign_key_list($table_name)" to emulate L<DBI>'s
$dbh -> foreign_key_info(...).

=head2 What is returned by the SQLite "pragma foreign_key_list($table_name)" call?

	Fields returned are:
	0: COUNT   (0, 1, ...)
	1: KEY_SEQ (0, or column # (1, 2, ...) within multi-column key)
	2: FKTABLE_NAME
	3: PKCOLUMN_NAME
	4: FKCOLUMN_NAME
	5: UPDATE_RULE
	6: DELETE_RULE
	7: 'NONE' (Constant string)

As these are stored in an arrayref, I use $$row[$i] just below to refer to the elements of the array.

=head2 How are these values mapped into the output?

	my(%referential_action) =
	(
		'CASCADE'     => 0,
		'RESTRICT'    => 1,
		'SET NULL'    => 2,
		'NO ACTION'   => 3,
		'SET DEFAULT' => 4,
	);

The hashref returned for foreign keys contains these key-value pairs:

	{
		DEFERABILITY      => undef,
		DELETE_RULE       => $referential_action{$$row[6]},
		FK_COLUMN_NAME    => $$row[3],
		FK_DATA_TYPE      => undef,
		FK_NAME           => undef,
		FK_TABLE_CAT      => undef,
		FK_TABLE_NAME     => $foreign_table,
		FK_TABLE_SCHEM    => undef,
		ORDINAL_POSITION  => $$row[1],
		UK_COLUMN_NAME    => $$row[4],
		UK_DATA_TYPE      => undef,
		UK_NAME           => undef,
		UK_TABLE_CAT      => undef,
		UK_TABLE_NAME     => $table_name,
		UK_TABLE_SCHEM    => undef,
		UNIQUE_OR_PRIMARY => undef,
		UPDATE_RULE       => $referential_action{$$row[5]},
	}

This list of keys matches what is returned when processing a Postgres database.

=head2 Haven't you got FK and PK backwards?

No, I don't think so.

Here is a method from the module L<App::Office::Contacts::Util::Create>, part of L<App::Office::Contacts>.

	sub create_organizations_table
	{
		my($self)        = @_;
		my($table_name)  = 'organizations';
		my($primary_key) = $self -> creator -> generate_primary_key_sql($table_name);
		my($engine)      = $self -> engine;
		my($result)      = $self -> creator -> create_table(<<SQL);
create table $table_name
(
	id $primary_key,
	visibility_id integer not null references visibilities(id),
	communication_type_id integer not null references communication_types(id),
	creator_id integer not null,
	role_id integer not null references roles(id),
	deleted integer not null,
	facebook_tag varchar(255) not null,
	homepage varchar(255) not null,
	name varchar(255) not null,
	timestamp timestamp not null default localtimestamp,
	twitter_tag varchar(255) not null,
	upper_name varchar(255) not null
) $engine
SQL

		$self -> dbh -> do("create index ${table_name}_upper_name on $table_name (upper_name)");

		$self -> report($table_name, 'created', $result);

	}	# End of create_organizations_table.

Consider this line:

	visibility_id integer not null references visibilities(id),

That means, for the 'visibilities' table, the info() method in the current module will return a hashref like:

	{
		visibilities =>
		{
			...
			foreign_keys =>
			{
				...
				organizations =>
				{
					UK_COLUMN_NAME    => 'id',
					DEFERABILITY      => undef,
					ORDINAL_POSITION  => 0,
					FK_TABLE_CAT      => undef,
					UK_NAME           => undef,
					UK_DATA_TYPE      => undef,
					UNIQUE_OR_PRIMARY => undef,
					UK_TABLE_SCHEM    => undef,
					UK_TABLE_CAT      => undef,
					FK_COLUMN_NAME    => 'visibility_id',
					FK_TABLE_NAME     => 'organizations',
					FK_TABLE_SCHEM    => undef,
					FK_DATA_TYPE      => undef,
					UK_TABLE_NAME     => 'visibilities',
					DELETE_RULE       => 3,
					FK_NAME           => undef,
					UPDATE_RULE       => 3
				},
			},
	}

This is saying that for the table 'visibilities', there is a foreign key in the 'organizations' table.
That foreign key is called 'visibility_id', and it points to the key called 'id' in the 'visibilities'
table.

=head1 Author

C<DBIx::Admin::TableInfo> was written by Ron Savage I<E<lt>ron@savage.net.auE<gt>> in 2004.

Home page: http://savage.net.au/index.html

=head1 Copyright

Australian copyright (c) 2004, Ron Savage.
	All Programs of mine are 'OSI Certified Open Source Software';
	you can redistribute them and/or modify them under the terms of
	The Artistic License, a copy of which is available at:
	http://www.opensource.org/licenses/index.html

=cut
