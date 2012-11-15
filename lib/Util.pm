# -*- Mode: perl; indent-tabs-mode: nil -*-
#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
#
# The Original Code is the Bugzilla Objective Watchdog Bugzilla Extension.
#
# The Initial Developer of the Original Code is Nokia
# Portions created by the Initial Developer are Copyright (C) 2011 the
# Initial Developer. All Rights Reserved.
#
# Contributor(s):
#   Eero Hein <eero.heino@nokia.com>
#   Pami Ketolainen <pami.ketolainen@jollamobile.com>

package Bugzilla::Extension::ChangeLog::Util;
use strict;

use Bugzilla::Error;

use base qw(Exporter);

our @EXPORT = qw(
    get_queries
);

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
            ThrowUserError('invalid_parameter', {
                name => 'changelog_queries',
                err => 'Every line must have format: "name-of-query" '.
                    '"the-sql-query-with-optional-<from-date>-somewhere'.
                    '-without-ending-semicolon"'
            });
        }

        if ($line =~ m/CREATE |INSERT |REPLACE |UPDATE |DELETE /i) {
            ThrowUserError('invalid_parameter', {
                    name => 'changelog_queries',
                    err => "Only 'SELECT' allowed for query: $line"
            });
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
1;
