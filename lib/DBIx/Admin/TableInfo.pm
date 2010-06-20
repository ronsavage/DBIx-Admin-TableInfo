package DBIx::Admin::TableInfo;

# Name:
#	DBIx::Admin::TableInfo.
#
# Documentation:
#	POD-style documentation is at the end. Extract it with pod2html.*.
#
# Reference:
#	Object Oriented Perl
#	Damian Conway
#	Manning
#	1-884777-79-1
#	P 114
#
# Note:
#	o Tab = 4 spaces || die.
#
# Author:
#	Ron Savage <ron@savage.net.au>
#	Home page: http://savage.net.au/index.html
#
# Licence:
#	Australian copyright (c) 2004 Ron Savage.
#
#	All Programs of mine are 'OSI Certified Open Source Software';
#	you can redistribute them and/or modify them under the terms of
#	The Artistic License, a copy of which is available at:
#	http://www.opensource.org/licenses/index.html

use strict;
use warnings;
no warnings 'redefine';

require 5.005_62;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use DBIx::Admin::TableInfo ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(

) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(

);
our $VERSION = '2.04';

# -----------------------------------------------

# Preloaded methods go here.

# -----------------------------------------------

# Encapsulated class data.

{
	my(%_attr_data) =
	(	# Alphabetical order.
		_dbh		=> '',
		_catalog	=> undef,
		_schema		=> undef,
		_table		=> '%',
		_type		=> 'TABLE',
	);

	sub _default_for
	{
		my($self, $attr_name) = @_;

		return $_attr_data{$attr_name};
	}

	sub _info
	{
		my($self)		= @_;
		$$self{'_info'}	= {};
		my($vendor)		= uc $$self{'_dbh'} -> get_info(17); # SQL_DBMS_NAME.
		my($table_sth)	= $$self{'_dbh'} -> table_info($$self{'_catalog'}, $$self{'_schema'}, $$self{'_table'}, $$self{'_type'});

		my($column_data, $column_name, $column_sth, $count);
		my($foreign_table);
		my($info);
		my($primary_key_info);
		my($table_data, $table_name, @table_name);

		while ($table_data = $table_sth -> fetchrow_hashref() )
		{
			$table_name = $$table_data{'TABLE_NAME'};

			next if ( ($vendor eq 'ORACLE') && ($table_name =~ /^BIN\$.+\$./) );
			next if ( ($vendor eq 'SQLITE') && ($table_name eq 'sqlite_sequence') );

			$$self{'_info'}{$table_name}	=
			{
				attributes		=> {%$table_data},
				columns			=> {},
				foreign_keys	=> {},
				primary_keys	=> {},
			};
			$column_sth			= $$self{'_dbh'} -> column_info($$self{'_catalog'}, $$self{'_schema'}, $table_name, '%');
			$primary_key_info	= [];

			push @table_name, $table_name;

			while ($column_data = $column_sth -> fetchrow_hashref() )
			{
				$column_name											= $$column_data{'COLUMN_NAME'};
				$$self{'_info'}{$table_name}{'columns'}{$column_name}	= {%$column_data};

				push @$primary_key_info, $column_name if ( ($vendor eq 'MYSQL') && $$column_data{'mysql_is_pri_key'});
			}

 			if ($vendor eq 'MYSQL')
 			{
 				$count = 0;

 				for (@$primary_key_info)
 				{
 					$count++;

 					$$self{'_info'}{$table_name}{'primary_keys'}{$_}				= {} if (! $$self{'_info'}{$table_name}{'primary_keys'}{$_});
 					$$self{'_info'}{$table_name}{'primary_keys'}{$_}{'COLUMN_NAME'}	= $_;
 					$$self{'_info'}{$table_name}{'primary_keys'}{$_}{'KEY_SEQ'}		= $count;
 				}
			}
			else
			{
				$column_sth = $$self{'_dbh'} -> primary_key_info($$self{'_catalog'}, $$self{'_schema'}, $table_name);

				if (defined $column_sth)
				{
					$info = $column_sth -> fetchall_arrayref({});

					for $column_data (@$info)
					{
						$$self{'_info'}{$table_name}{'primary_keys'}{$$column_data{'COLUMN_NAME'} } = {%$column_data};
					}
				}
			}
		}

		for $table_name (@table_name)
		{
			for $foreign_table (grep{! /^$table_name$/} @table_name)
			{
				$table_sth = $$self{'_dbh'} -> foreign_key_info($$self{'_catalog'}, $$self{'_schema'}, $table_name, $$self{'_catalog'}, $$self{'_schema'}, $foreign_table);

				if (defined $table_sth)
				{
					$info = $table_sth -> fetchall_arrayref({});

					for $column_data (@$info)
					{
						$$self{'_info'}{$table_name}{'foreign_keys'}{$foreign_table} = {%$column_data};
					}
				}
			}
		}

	}	# End of _info.

	sub _standard_keys
	{
		return keys %_attr_data;
	}

}	# End of encapsulated class data.

# -----------------------------------------------

sub columns
{
	my($self, $table, $by_position) = @_;

	if ($by_position)
	{
		return [sort{$$self{'_info'}{$table}{'columns'}{$a}{'ORDINAL_POSITION'} <=> $$self{'_info'}{$table}{'columns'}{$b}{'ORDINAL_POSITION'} } keys %{$$self{'_info'}{$table}{'columns'} }];
	}
	else
	{
		return [sort{$a cmp $b} keys %{$$self{'_info'}{$table}{'columns'} }];
	}

}	# End of columns.

# -----------------------------------------------

sub info
{
	my($self) = @_;

	return $$self{'_info'};

}	# End of info.

# -----------------------------------------------

sub new
{
	my($class, %arg)	= @_;
	my($self)			= bless({}, $class);

	for my $attr_name ($self -> _standard_keys() )
	{
		my($arg_name) = $attr_name =~ /^_(.*)/;

		if (exists($arg{$arg_name}) )
		{
			$$self{$attr_name} = $arg{$arg_name};
		}
		else
		{
			$$self{$attr_name} = $self -> _default_for($attr_name);
		}
	}

	croak(__PACKAGE__ . ". You must supply a value for the 'dbh' parameter") if (! $$self{'_dbh'});

	$self -> _info();

	return $self;

}	# End of new.

# -----------------------------------------------

sub refresh
{
	my($self) = @_;

	$self -> _info();

	return $$self{'_info'};

}	# End of refresh.

# -----------------------------------------------

sub tables
{
	my($self) = @_;

	return [sort keys %{$$self{'_info'} }];

}	# End of tables.

# -----------------------------------------------

1;

__END__

=head1 NAME

C<DBIx::Admin::TableInfo> - A wrapper for all of table_info(), column_info(), *_key_info()

=head1 Synopsis

This program is shipped as examples/table.info.pl.

	#!/usr/bin/perl

	use strict;
	use warnings;

	use Data::Dumper;
	use DBI;
	use DBIx::Admin::TableInfo;

	# ---------------------

	my($dbh) = DBI -> connect($ENV{'DBI_DSN'}, $ENV{'DBI_USER'}, $ENV{'DBI_PASS'});

	if ($ENV{'DBI_DSN'} =~ /SQLite/i)
	{
		$dbh -> do('PRAGMA foreign_keys = ON');
	}

	my($schema) = $ENV{'DBI_DSN'} =~ /^dbi:Oracle/i
		? uc $ENV{'DBI_USER'}
		: $ENV{'DBI_DSN'} =~ /^dbi:Pg/i
		? 'public'
		: undef;

	print Data::Dumper -> Dump
	([
		DBIx::Admin::TableInfo -> new(dbh => $dbh, schema => $schema) -> info()
	]);

=head1 Description

C<DBIx::Admin::TableInfo> is a pure Perl module.

It is a convenient wrapper around all of these DBI methods:

=over 4

=item table_info()

=item column_info()

=item primary_key_info()

=item foreign_key_info()

=back

Warnings:

=over 4

=item MySQL

=over 4

=item New Notes

I'm testing V 2.04 of this module with MySql V 5.0.51a and DBD::mysql V 4.014.

To get foreign key information in the output, the create table statement has to:

=over 4

=item Include an index clause

=item Include a foreign key clause

=item Include an engine clause

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

=item Old Notes

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

=item Oracle

Oracle table names matching /^BIN\$.+\$./ are ignored by this module.

=item Postgres

I'm testing V 2.04 of this module with Postgres V 08.03.1100 and DBD::Pg V 2.17.1.

The latter now takes '%' as the value of the 'table' parameter to new(), whereas
older versions of DBD::Pg required 'table' to be set to 'table'.

=item SQLite

I'm testing V 2.04 of this module with SQLite V 3.6.22 and DBD::SQLite V 1.29.

SQLite does not currently return foreign key information.

The SQLite table 'sqlite_sequence' is ignored by this module.

=back

=head1 Distributions

This module is available both as a Unix-style distro (*.tgz) and an
ActiveState-style distro (*.ppd). The latter is shipped in a *.zip file.

See http://savage.net.au/Perl-modules.html for details.

See http://savage.net.au/Perl-modules/html/installing-a-module.html for
help on unpacking and installing each type of distro.

=head1 Constructor and initialization

new(...) returns a C<DBIx::Admin::TableInfo> object.

This is the class's contructor.

Usage: DBIx::Admin::TableInfo -> new().

This method takes a set of parameters. Only the dbh parameter is mandatory.

For each parameter you wish to use, call new as new(param_1 => value_1, ...).

=over 4

=item catalog

This is the value passed in as the catalog parameter to table_info() and column_info().

The default value is undef.

undef was chosen because it given the best results with MySQL.

Note: The MySQL driver DBD::mysql V 2.9002 has a bug in it, in that it aborts if an empty string is used here,
even though the DBI docs say an empty string can be used for the catalog parameter to C<table_info()>.

This parameter is optional.

=item dbh

This is a database handle.

This parameter is mandatory.

=item schema

This is the value passed in as the schema parameter to table_info() and column_info().

The default value is undef.

Note: If you are using Oracle, call C<new()> with schema set to uc $user_name.

Note: If you are using Postgres, call C<new()> with schema set to 'public'.

This parameter is optional.

=item table

This is the value passed in as the table parameter to table_info().

The default value is '%'.

Note: If you are using an 'old' version of DBD::Pg, call C<new()> with table set to 'table'.

Sorry - I can't tell you exactly what 'old' means. As stated above, the default value (%)
works fine with DBD::Pg V 2.17.1.

This parameter is optional.

=item type

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

=item First level: The keys are the names of the tables

	my($info)       = $obj -> info();
	my(@table_name) = sort keys %$info;

I use singular names for my arrays, hence @table_name rather than @table_names.

=item Second level: The keys are 'attributes', 'columns', 'foreign_keys' and 'primary_keys'

	my($table_attributes) = $$info{$table_name}{'attributes'};

This is a hash ref of the table's attributes. The keys of this hash ref are determined by the database server.

	my($columns) = $$info{$table_name}{'columns'};

This is a hash ref of the table's columns. The keys of this hash ref are the names of the columns.

	my($foreign_keys) = $$info{$table_name}{'foreign_keys'};

This is a hash ref of the table's foreign keys. The keys of this hash ref are the names of the tables
which contain foreign keys pointing to $table_name.

For MySQL, $foreign_keys will be the empty hash ref {}, as explained above.

	my($primary_keys) = $$info{$table_name}{'primary_keys'};

This is a hash ref of the table's primary keys. The keys of this hash ref are the names of the columns
which make up the primary key of $table_name.

For any database server, if there is more than 1 column in the primary key, they will be numbered
(ordered) according to the hash key 'KEY_SEQ'.

For MySQL, if there is more than 1 column in the primary key, they will be artificially numbered
according to the order in which they are returned by C<column_info()>, as explained above.

=item Third level, after 'attributes': Table attributes

	my($table_attributes) = $$info{$table_name}{'attributes'};

	while ( ($name, $value) = each(%$table_attributes) )
	{
		Use...
	}

For the attributes of the tables, there are no more levels in the hash ref.

=item Third level, after 'columns': The keys are the names of the columns.

	my($columns) = $$info{$table_name}{'columns'};

	my(@column_name) = sort keys %$columns;

=over 4

=item Fourth level: Column attributes

	for $column_name (@column_name)
	{
	    while ( ($name, $value) = each(%{$columns{$column_name} }) )
	    {
		    Use...
	    }
	}

=back

=item Third level, after 'foreign_keys': The keys are the names of tables

These tables have foreign keys which point to the current table.

	my($foreign_keys) = $$info{$table_name}{'foreign_keys'};

	for $foreign_table (sort keys %$foreign_keys)
	{
		$foreign_key = $$foreign_keys{$foreign_table};

		for $attribute (sort keys %$foreign_key)
		{
			Use...
		}
	}

=item Third level, after 'primary_keys': The keys are the names of columns

These columns make up the primary key of the current table.

	my($primary_keys) = $$info{$table_name}{'primary_keys'};

	for $primary_key (sort{$$a{'KEY_SEQ'} <=> $$b{'KEY_SEQ'} } keys %$primary_keys)
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

Warning: Oracle table names matching /^BIN\$.+\$./ are ignored by this module.

=head1 Example code

Here are tested parameter values for various database vendors:

=over 4

=item MS Access

	my($admin) = DBIx::Admin::TableInfo -> new(dbh => $dbh);

	In other words, the default values for catalog, schema, table and type will Just Work.

=item MySQL

	my($admin) = DBIx::Admin::TableInfo -> new(dbh => $dbh);

	In other words, the default values for catalog, schema, table and type will Just Work.

=item Oracle

	my($dbh)   = DBI -> connect($dsn, $username, $password);
	my($admin) = DBIx::Admin::TableInfo -> new
	(
		dbh    => $dbh,
		schema => uc $username, # Yep, upper case.
	);

	For Oracle, you probably want to ignore table names matching /^BIN\$.+\$./.

=item PostgreSQL

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
		table  => 'table, # Yep, lower case.
	);

=item SQLite

	my($admin) = DBIx::Admin::TableInfo -> new(dbh => $dbh);

	In other words, the default values for catalog, schema, table and type will Just Work.

	For SQLite, you probably want to ignore the table 'sqlite_sequence'.

=back

See the examples/ directory in the distro.

=head1 Tested Database Formats

The first set of tests was done with C<DBIx::Admin::TableInfo> up to V 2.03, 
using examples/table.info.pl (as per the Synopsis):

=over 4

=item MS Access V 2

Yes, some businesses were still running V 2 as of July, 2004.

=item MS Access V 2002 and V 2003

=item MySQL V 4 and V 5

=item Oracle V 9.2.0

=item PostgreSQL V 7.3, 8.1

=back

The second set of tests was done with C<DBIx::Admin::TableInfo> V 2.04, also using
examples/table.info.pl.

=over 4

=item MySql V 5.0.51a and DBD::mysql V 4.014

=item Postgres V 08.03.1100 and DBD::Pg V 2.17.1.

=item SQLite V 3.6.22 and DBD::SQLite V 1.29.

=back

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
