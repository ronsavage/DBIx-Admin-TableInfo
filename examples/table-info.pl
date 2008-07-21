#!/usr/bin/perl

use strict;
use warnings;

use Data::Dumper;
use DBI;
use DBIx::Admin::TableInfo 2.0;

# ---------------------

my($dbh)	= DBI -> connect($ENV{'DBI_DSN'}, $ENV{'DBI_USER'}, $ENV{'DBI_PASS'});
my($schema)	= $ENV{'DBI_DSN'} =~ /^dbi:Oracle/i ? uc $ENV{'DBI_USER'} : undef;

print Data::Dumper -> Dump([DBIx::Admin::TableInfo -> new(dbh => $dbh, schema => $schema) -> info()]);
