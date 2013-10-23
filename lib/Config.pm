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

sub get_param_list {
    my ($class) = @_;

    my @group_names = sort { lc $a cmp lc $b } @{Bugzilla->dbh->selectcol_arrayref(
            "SELECT name FROM groups")};

    my @param_list = (
        {
           name => 'changelog_queries',
           type => 't',
           checker => \&_check_queries,
           default => 'OBSOLETE',
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
    if ($value ne 'OBSOLETE') {
        return "This parameter is obsolete and should not be changed";
    }
    return "";
}

1;
