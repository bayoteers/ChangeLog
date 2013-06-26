# -*- Mode: perl; indent-tabs-mode: nil -*-
#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
#
# The Original Code is the Bugzilla Objective Watchdog Bugzilla Extension.
#
# The Initial Developer of the Original Code is "Nokia Corporation"
# Portions created by the Initial Developer are Copyright (C) 2011 the
# Initial Developer. All Rights Reserved.
#
# Contributor(s):
#   Eero Heino <eero.heino@nokia.com>
#   Pami Ketolainen <pami.ketolainen@jollamobile.com>

package Bugzilla::Extension::ChangeLog::Config;
use strict;
use warnings;

use Bugzilla::Config::Common;
use Bugzilla::Extension::ChangeLog::Util;

sub get_param_list {
    my ($class) = @_;

    my @group_names = sort { lc $a cmp lc $b } @{Bugzilla->dbh->selectcol_arrayref(
            "SELECT name FROM groups")};

    my @param_list = (
        {
           name => 'changelog_queries',
           type => 'l',
           checker => \&_check_queries,
           default =>
'"flags" "select bugs.bug_id,bugs.short_desc,bugs_activity.bug_when,bugs_activity.removed as changed_from, bugs_activity.added as changed_to,profiles.login_name as user from bugs_activity left join profiles on bugs_activity.who = profiles.userid left join bugs on bugs.bug_id = bugs_activity.bug_id where fieldid = 44 and timestamp(bugs_activity.bug_when) >= TIMESTAMP(\'<from-date>\')"',
        },
        {
           name    => 'changelog_access_groups',
           type    => 'm',
           choices => \@group_names,
           default => ['admin'],
        },
    );

    return @param_list;
}

sub _check_queries {
    my $value = shift;

    my $retval  = get_queries($value);
    my $queries = $retval->{'queries'};

    our $error = '';

    sub handle_error {
        $error = shift;
    }

    my $result = "";
    for (keys %$queries) {
        my $dbh = Bugzilla->dbh;

        $dbh->{RaiseError}  = 0;
        $dbh->{PrintError}  = 0;
        $dbh->{HandleError} = \&handle_error;

        my $query = $queries->{$_};
        $query =~ s/limit(\s+)(\d+)//;
        my $sth = $dbh->prepare($query . " limit 0");
        if (!$sth->execute) {
            $result .= "Query '". $_ . "' has error: ". $error . '. '
        }
    }
    return $result;
}

1;
