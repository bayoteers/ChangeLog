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

package Bugzilla::Extension::BOW::Config;
use strict;
use warnings;

use Bugzilla::Config::Common;

sub get_param_list {
    my ($class) = @_;

    my @param_list = (
                      {
                         name    => 'bow_queries',
                         desc    => 'Name and SQL query',
                         type    => 'l',
                         default => '',
                      },
                      {
                         name    => 'bow_access_groups',
                         desc    => 'Flags hidden from users other than the Grant or Request group.',
                         type    => 'm',
                         choices => \&_get_all_group_names,
                         #choices => ['foo', 'bar', 'Admins'],
                         default => [],
                      },
                     );

    return @param_list;
}

sub _get_all_group_names {
    my @group_list = [];
    for my $group (Bugzilla::Group->get_all) {
       push(@group_list, $group->name); 
    }
    shift @group_list;
    return @group_list;
}

1;
