#!/usr/bin/perl

use strict;
use warnings;

use Data::Dumper;
use DBI;
use DBIx::Admin::TableInfo 2.0;

# ---------------------

my($attr) = {};
my($dbh)  = DBI -> connect($ENV{'DBI_DSN'}, $ENV{'DBI_USER'}, $ENV{'DBI_PASS'}, $attr);

if ($ENV{'DBI_DSN'} =~ /SQLite/i)
{
	$dbh -> do('PRAGMA foreign_keys = ON');
}

my($schema) = $ENV{'DBI_DSN'} =~ /^dbi:Oracle/i
	? uc $ENV{'DBI_USER'}
	: $ENV{'DBI_DSN'} =~ /^dbi:Pg/i
	? 'public'
	: undef;

print Data::Dumper -> Dump([DBIx::Admin::TableInfo -> new(dbh => $dbh, schema => $schema) -> info()]);
