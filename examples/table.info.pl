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

$dbh -> do('PRAGMA foreign_keys = ON')           if ($ENV{DBI_DSN} =~ /SQLite/i);
$dbh -> do("set search_path = $ENV{DBI_SCHEMA}") if ($ENV{DBI_SCHEMA});

my($schema) = $ENV{DBI_DSN} =~ /^dbi:Oracle/i
	? uc $ENV{DBI_USER}
	: $ENV{DBI_DSN} =~ /^dbi:Pg/i
	? $ENV{DBI_SCHEMA}
	? undef
	: 'public'
	: undef;

print Data::Dumper -> Dump([DBIx::Admin::TableInfo -> new(dbh => $dbh, schema => $schema) -> info()]);
