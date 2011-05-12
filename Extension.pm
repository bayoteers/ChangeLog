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
# The Initial Developer of the Original Code is YOUR NAME
# Portions created by the Initial Developer are Copyright (C) 2011 the
# Initial Developer. All Rights Reserved.
#
# Contributor(s):
#   Eero Heino <eero.heino@nokia.com>

package Bugzilla::Extension::BlameThisGuy;
use strict;
use base qw(Bugzilla::Extension);

# This code for this is in ./extensions/BlameThisGuy/lib/Util.pm
use Bugzilla::Extension::BlameThisGuy::Util;

our $VERSION = '0.01';

# See the documentation of Bugzilla::Hook ("perldoc Bugzilla::Hook" 
# in the bugzilla directory) for a list of all available hooks.
sub install_update_db {
    my ($self, $args) = @_;

}

sub page_before_template {
    my ($self, $args) = @_;

    my ($vars, $page) = @$args{qw(vars page_id)};
    my $cgi             = Bugzilla->cgi;

    if ($page eq 'bow.html') {
        use Bugzilla::DB;
        my $dbh = Bugzilla->dbh;
        $vars->{'data'} = [];

    }

    if ($page eq 'bow_file.html') {
        print $cgi->header(-type                => 'text/csv',
                           -content_disposition => 'attachment; filename=bow-'.$cgi->param('from_date').'_'.$cgi->param('to_date').'.csv');
        $vars->{'data'} = $cgi->param('data');
    }

    if ($page eq 'bow_ajax.html') {
        use Bugzilla::DB;
        my $dbh = Bugzilla->dbh;


        my $cgi             = Bugzilla->cgi;
        my $field_name         = $cgi->param('field');
        my $from_date = $cgi->param('from_date');

        if ($from_date =~ /^([1-2][0-9][0-9][0-9])-([0-1][0-9])-([0-1][0-9])$/) {
           $from_date = "$1-$2-$3"; # untainted
        }


        my $limit = $cgi->param('limit');
        if (not $limit) {
            $limit = 10;
        }
        if ($limit =~ /^(\d+)$/) {
           $limit = $1; # untainted
        }

        my $sth = 0;

        if ($field_name eq 'flags')
        {
            $sth = $dbh->prepare("select bugs.bug_id,bugs_activity.bug_when,products.name as component,bugs_activity.removed as changed_from, bugs_activity.added as changed_to,profiles.login_name as user from bugs_activity left join profiles on bugs_activity.who = profiles.userid left join bugs on bugs.bug_id = bugs_activity.bug_id left join products on products.id = bugs.product_id where products.classification_id=2 and fieldid=42 and timestamp(bugs_activity.bug_when) >= TIMESTAMP('".$from_date."')");
        }

        if ($field_name eq 'severity')
        {
            $sth = $dbh->prepare("select bugs.bug_id,bugs_activity.bug_when,products.name as component,bugs_activity.removed as removed,bugs_activity.added as added,profiles.login_name as user from bugs_activity left join profiles on bugs_activity.who = profiles.userid left join bugs on bugs.bug_id = bugs_activity.bug_id left join products on products.id = bugs.product_id where products.classification_id=2 and fieldid=12 and timestamp(bugs_activity.bug_when) >= TIMESTAMP('".$from_date."') order by bugs_activity.bug_when asc");
        }

        if ($field_name eq 'reopened')
        {
            $sth = $dbh->prepare("select bugs.bug_id,bugs_activity.bug_when,products.name as component,bugs_activity.removed as removed,bugs_activity.added as added,profiles.login_name as user from bugs_activity left join profiles on bugs_activity.who = profiles.userid left join bugs on bugs.bug_id = bugs_activity.bug_id left join products on products.id = bugs.product_id where products.classification_id=2 and fieldid=8 and bugs_activity.added='reopened' and timestamp(bugs_activity.bug_when) >= TIMESTAMP('".$from_date."')");
        }

        if ($field_name eq 'target_milestone')
        {
            $sth = $dbh->prepare("select bugs.bug_id,bugs_activity.bug_when,products.name as component,bugs_activity.removed as removed,bugs_activity.added as added,profiles.login_name as user from bugs_activity left join profiles on bugs_activity.who = profiles.userid left join bugs on bugs.bug_id = bugs_activity.bug_id left join products on products.id = bugs.product_id where products.classification_id=2 and fieldid=28 and timestamp(bugs_activity.bug_when) >= TIMESTAMP('".$from_date."')");
        }



        if ($sth)
        {
            # Execute the query
            $sth->execute;

            use JSON;
            $vars->{'data'} = to_json({ 'rows' =>  $sth->fetchall_arrayref, 'name' => $field_name });

        } else
        {

            $vars->{'data'} = to_json({ 'rows' =>  to_json([]), 'name' => $field_name });
        }
    }
}

__PACKAGE__->NAME;
