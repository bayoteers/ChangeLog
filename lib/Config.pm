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

package Bugzilla::Extension::ChangeLog::Config;
use strict;
use warnings;

use Bugzilla::Config::Common;

sub get_param_list {
    my ($class) = @_;

    my @param_list = (
        {
           name => 'changelog_queries',
           desc => 'Name and SQL query',
           type => 'l',
           default =>
'"flags" "select bugs.bug_id,bugs.short_desc,bugs_activity.bug_when,bugs_activity.removed as changed_from, bugs_activity.added as changed_to,profiles.login_name as user from bugs_activity left join profiles on bugs_activity.who = profiles.userid left join bugs on bugs.bug_id = bugs_activity.bug_id where fieldid = 44 and timestamp(bugs_activity.bug_when) >= TIMESTAMP(\'<from-date>\')"',
        },
        {
           name    => 'changelog_access_groups',
           desc    => 'Flags hidden from users other than the Grant or Request group.',
           type    => 'm',
           choices => \&_get_all_group_names,
           default => ['admin'],
        },
    );

    return @param_list;
}

sub _get_all_group_names {
    my @group_names = map { $_->name } Bugzilla::Group->get_all;
    unshift(@group_names, '');

    my @sorted = sort { lc $a cmp lc $b } @group_names;

    return \@sorted;
}

1;
