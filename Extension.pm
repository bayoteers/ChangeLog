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

package Bugzilla::Extension::ChangeLog;
use strict;
use base qw(Bugzilla::Extension);

use Bugzilla::Config qw(SetParam write_params);
use Bugzilla::Error qw(ThrowCodeError ThrowUserError);
use Bugzilla::Util qw(datetime_from);

use Bugzilla::Extension::ChangeLog::Query;

use DateTime;

our $VERSION = '0.2';

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
    return unless _has_access();
    $args->{links}->{ChangeLog} = [
        {
            text => 'ChangeLog',
            href => 'page.cgi?id=ChangeLog.html'
        }
    ];
}

sub bb_group_params {
    my ($self, $args) = @_;
    push(@{$args->{group_params}}, 'changelog_access_groups');
}

sub db_schema_abstract_schema {
    my ($self, $args) = @_;
    my $schema = $args->{schema};

    # Table for storing the changelog queries
    $schema->{changelog_queries} = {
        FIELDS => [
            id => {TYPE => 'MEDIUMSERIAL', NOTNULL => 1, PRIMARYKEY => 1},
            name => {TYPE => 'TINYTEXT', NOTNULL => 1},
            statement => {TYPE => 'MEDIUMTEXT'},
        ],
        INDEXES => [],
    };
}

sub install_update_db {
    my $queries_param = Bugzilla->params->{changelog_queries};
    if ($queries_param ne 'OBSOLETE') {
        print "Migrating ChangeLog queries to DB...\n";
        for my $line (split(/\n/, $queries_param)) {
            # skip empty lines
            next if ($line =~ /^\s*$/);
            if ($line =~ /"(.+)"\s+"(.+)"/) {
                Bugzilla::Extension::ChangeLog::Query->create({
                    name => $1,
                    statement => $2,
                });
            } else {
                print "Skipping bad query line: $line\n";
            }
        }
        SetParam('changelog_queries', "OBSOLETE");
        write_params();
    }
}

sub object_end_of_update {
    my ($self, $args) = @_;
    my ($obj, $old_obj, $changes) = @$args{qw(object old_object changes)};

    # Update params if group names change
    if ($obj->isa("Bugzilla::Group") && defined $changes->{name}) {
        my @new_names;
        my $changed = 0;
        for my $old_name (@{Bugzilla->params->{"changelog_access_groups"}}) {
            if ($old_name && $old_name eq $old_obj->name) {
                push(@new_names, $obj->name);
                $changed = 1;
            } else {
                push(@new_names, $old_name);
            }
        }
        if ($changed) {
            SetParam('changelog_access_groups', \@new_names);
            write_params();
        }
    }
}

sub page_before_template {
    my ($self, $args) = @_;
    my ($vars, $page) = @$args{qw(vars page_id)};

    return unless ($page =~ /^ChangeLog/);
    _has_access(1);
    my $cgi = Bugzilla->cgi;
    my $from_date  = $cgi->param('from_date');
    $from_date = datetime_from($from_date) if defined $from_date;
    $from_date = defined $from_date ? $from_date->ymd
            : DateTime->now->subtract( days => 1 )->ymd;
    $vars->{from_date} = $from_date;

    my $qid = $cgi->param('qid');

    if ($page eq 'ChangeLog.html') {
        $vars->{'queries'} = Bugzilla::Extension::ChangeLog::Query->match();
    }

    if ($page eq 'ChangeLogTable.html' || $page eq 'ChangeLogTable.csv') {
        ThrowCodeError('param_required', { param => 'qid' }) unless $qid;
        my $query = Bugzilla::Extension::ChangeLog::Query->check({id => $qid});
        $vars->{query} = $query;

        my $result = $query->execute({from_date => $from_date});
        $vars->{headers} = $result->{columns};
        $vars->{table} = $result->{data};

        if ($page eq 'ChangeLogTable.csv') {
            $vars->{human} = $cgi->param('human');
            my $filename = "changelog-".$query->name;
            $filename .= "-$from_date" if defined $from_date;
            $filename .= ".csv";
            $filename = lc($filename);
            print $cgi->header(
                -content_type => "text/csv",
                -content_disposition => "attachment; filename=$filename"
            );
        }
    }

    if ($page eq 'ChangeLogQuery.html') {
        ThrowUserError('auth_failure', {
            group => 'admin', action => 'access',
            object => 'administrative_pages'
        }) unless Bugzilla->user->in_group('admin');;
        my $action = $cgi->param('action') || '';
        my $current;
        if (defined $qid) {
            $current = Bugzilla::Extension::ChangeLog::Query->check({id=>$qid});
        }
        if ($action) {
            my $values = {
                name => scalar $cgi->param('name'),
                statement => scalar $cgi->param('statement'),
            };
            if ($action eq 'create') {
                $current = Bugzilla::Extension::ChangeLog::Query->create($values);
                $vars->{message} = 'changelog_query_created';
            } elsif ($action eq 'save') {
                ThrowCodeError('param_required', {param => 'qid', function=>'save'})
                    unless defined $current;
                $current->set_all($values);
                $current->update();
                $vars->{message} = 'changelog_query_saved';
            } elsif ($action eq 'remove') {
                ThrowCodeError('param_required', {param => 'cid', function=>'remove'})
                    unless defined $current;
                $current->remove_from_db();
                $vars->{message} = 'changelog_query_removed';
                $vars->{name} = $current->name;
                $current = undef;
            } else {
                ThrowCodeError('param_invalid',
                    {param => $action, function=>'action'});
            }
        }
        $vars->{current} = $current;
        $vars->{queries} = Bugzilla::Extension::ChangeLog::Query->match();
    }
}

sub _has_access {
    my $throwerror = shift;
    my $names = Bugzilla->params->{"changelog_access_groups"};

    foreach my $name (@$names) {
        return 1 if Bugzilla->user->in_group($name);
    }

    if ($throwerror) {
        ThrowUserError('auth_failure', {
            action => 'access', reason => 'not_visible'
        });
    }
    return 1;
}

__PACKAGE__->NAME;
