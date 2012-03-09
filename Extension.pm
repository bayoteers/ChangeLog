# -*- Mode: perl; indent-tabs-mode: nil -*-
#
# The contents of this file are subject to the Mozilla Public
# License Version 1.1 (the "License"); you may not use this file
# except in compliance with the License. You may obtain a copy of
# the License at http://www.mozilla.org/MPL/
#
# Software distributed under the License is distributed on an "AS
# IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or
# implied. See the License for the specific language governing
# rights and limitations under the License.
#
# The Original Code is the Bugzilla Objective Watchdog Bugzilla Extension.
#
# The Initial Developer of the Original Code is "Nokia Corporation"
# Portions created by the Initial Developer are Copyright (C) 2011 the
# Initial Developer. All Rights Reserved.
#
# Contributor(s):
#   Eero Heino <eero.heino@nokia.com>

package Bugzilla::Extension::ChangeLog;
use strict;
use base qw(Bugzilla::Extension);

use Bugzilla::Constants;
use Bugzilla::Error;
use Bugzilla::Group;
use Bugzilla::User;
use Bugzilla::DB;

use JSON;

# This code for this is in ./extensions/ChangeLog/lib/Util.pm
use Bugzilla::Extension::ChangeLog::Util;

our $VERSION = '0.01';

sub config {
    my ($self, $args) = @_;

    my $config = $args->{config};
    $config->{ChangeLog} = "Bugzilla::Extension::ChangeLog::Config";
}

sub config_add_panels {
    my ($self, $args) = @_;

    my $modules = $args->{panel_modules};
    $modules->{ChangeLog} = "Bugzilla::Extension::ChangeLog::Config";
}

sub bb_common_links {
    my ($self, $args) = @_;

    $args->{links}->{ChangeLog} = [
        {
            text => 'ChangeLog',
            href => 'page.cgi?id=ChangeLog.html'
        }
    ];
}

sub get_queries {
    my ($value, $from_date) = @_;

    my $queries = {};
    my @names   = ();

    for my $line (split(/\n/, $value)) {
        # skip empty lines
        if ($line =~ /^$/) {
            next;
        }

        if (not $line =~ /"(.+)"(\s+)"(.+)[^;]"/) {
            ThrowUserError(
                           'invalid_parameter',
                           {
                              name => 'changelog_queries',
                              err => 'Every line must have format: "name-of-query" "the-sql-query-with-optional-<from-date>-somewhere-without-ending-semicolon"'
                           }
                          );
        }

        if ($line =~ m/CREATE |INSERT |REPLACE |UPDATE |DELETE /i) {
            ThrowUserError('invalid_parameter', { name => 'changelog_queries', err => "Only 'SELECT' allowed for query: $line" });
        }

        if (not defined $from_date) {
            $from_date = 'NOW()';
        }

        if ($line =~ /"(.+)"(\s+)"(.+)"/) {
            my $query = $3;
            my $name  = $1;
            $query =~ s/(['"]*)<from-date>(['"]*)/'$from_date'/;
            $queries->{$name} = $query;
            push(@names, $name);
        }
    }

    return { names => \@names, queries => $queries };
}

sub check_parameter {
    my ($self, $args) = @_;

    my $name = $args->{name};

    if ($name eq 'changelog_queries') {
        my $value = $args->{value};

        my $retval  = get_queries($value);
        my $queries = $retval->{'queries'};

        our $error = '';

        sub handle_error {
            $error = shift;
        }

        for (keys %$queries) {
            my $dbh = Bugzilla->dbh;

            $dbh->{RaiseError}  = 0;
            $dbh->{PrintError}  = 0;
            $dbh->{HandleError} = \&handle_error;

            my $query = $queries->{$_};
            $query =~ s/limit(\s+)(\d+)//;
            my $sth = $dbh->prepare($query . " limit 0");
            $sth->execute || ThrowUserError('invalid_parameter', { name => $name . "/" . $_, err => 'Server gave "' . $error . '"' });
        }
    }
}

# See the documentation of Bugzilla::Hook ("perldoc Bugzilla::Hook"
# in the bugzilla directory) for a list of all available hooks.
sub install_update_db {
    my ($self, $args) = @_;

}

sub page_before_template {
    my ($self, $args) = @_;

    my ($vars, $page) = @$args{qw(vars page_id)};
    my $cgi = Bugzilla->cgi;

    if ($page eq 'ChangeLog.html') {
        _has_access();

        my $dbh = Bugzilla->dbh;

        my $retval  = get_queries(Bugzilla->params->{"changelog_queries"});
        my $queries = $retval->{'queries'};

        $vars->{'tabs'} = $retval->{'names'};
        $vars->{'data'} = [];
    }

    if ($page eq 'ChangeLog_file.html') {
        _has_access();

        print $cgi->header(-type                => 'text/csv',
                           -content_disposition => 'attachment; filename=changelog-' . $cgi->param('from_date') . '_' . $cgi->param('to_date') . '.csv');
        $vars->{'data'} = $cgi->param('data');
    }

    if ($page eq 'ChangeLog_ajax.html') {
        _has_access();

        my $dbh = Bugzilla->dbh;

        my $cgi        = Bugzilla->cgi;
        my $field_name = $cgi->param('field');
        my $from_date  = $cgi->param('from_date');

        if ($from_date =~ /^([1-2][0-9][0-9][0-9])-([0-1][0-9])-([0-3][0-9])$/) {
            $from_date = "$1-$2-$3";    # untainted
        }

        my $limit = $cgi->param('limit');
        if (not $limit) {
            $limit = 10;
        }
        if ($limit =~ /^(\d+)$/) {
            $limit = $1;                # untainted
        }

        my $sth  = 0;
        my @cols = [];

        my $retval = get_queries(Bugzilla->params->{"changelog_queries"}, $from_date);
        my $queries = $retval->{'queries'};

        if (exists $queries->{$field_name}) {
            $sth = $dbh->prepare($queries->{$field_name});
        }

        if ($sth) {
            # Execute the query
            $sth->execute;

            my $retval = { 'rows' => $sth->fetchall_arrayref, 'name' => $field_name };

            my $column_query = $queries->{$field_name} . " limit 0";
            if ($column_query =~ /(.*)/) {
                $column_query = $1;
            }
            $dbh->prepare($column_query);
            $sth->execute;

            $retval->{'cols'} = $sth->{NAME};

            $vars->{'data'} = to_json($retval);
        }
        else {
            $vars->{'data'} = to_json(
                                      {
                                        'rows' => to_json([]),
                                        'name' => $field_name,
                                        'cols' => @cols
                                      }
                                     );
        }
    }
}

sub _has_access() {
    my $access = 0;

    my $names = Bugzilla->params->{"changelog_access_groups"};

    foreach my $name (@$names) {
        if (Bugzilla->user->in_group($name)) {
            $access = 1;
            last;
        }
    }

    if (not $access) {
        ThrowUserError('auth_failure', { group => "wanted", action => "show", object => "team" });
    }
}

__PACKAGE__->NAME;
