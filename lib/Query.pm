# -*- Mode: perl; indent-tabs-mode: nil -*-
#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
#
# Copyright (C) 2013 Jolla Ltd.
# Contact: Pami Ketolainen <pami.ketolainen@jollamobile.com>


=head1 NAME

Bugzilla::Extension::ChangeLog::Query

=head1 SYNOPSIS

    use Bugzilla::Extension::ChangeLog:Query;

    my $category = Bugzilla::Extension::JollaPlan::Category->create({
        name => 'Resolved',
        sql => "SELECT act.bug_id, p.login_name FROM bugs_activity AS act
                LEFT JOIN profiles AS p ON act.who = p.userid
                LEFT JOIN fielddefs AS field ON act.fieldid = field.id
            WHERE field.name = 'bug_status' AND
                act.added = 'RESOLVED' AND
                TIMESTAMP(act.bug_when) >= TIMESTAMP(<from-date>)"
    });

=head1 DESCRIPTION

Database object for storing ChangeLog queries

Query is inherited from L<Bugzilla::Object>.

=head1 FIELDS

=over

=item C<name> (mutable) - Query name
=item C<statement> (mutable) - Query SQL statement

=back

=cut

use strict;
use warnings;

package Bugzilla::Extension::ChangeLog::Query;

use Bugzilla::Error;
use Bugzilla::Util qw(detaint_natural trick_taint trim);

use DateTime;
use Scalar::Util qw(blessed);

use base qw(Bugzilla::Object);


use constant DB_TABLE => 'changelog_queries';

use constant DB_COLUMNS => qw(
    id
    name
    statement
    is_active
    sort_order
);

use constant LIST_ORDER => 'sort_order, name';

use constant UPDATE_COLUMNS => qw(
    name
    statement
    is_active
    sort_order
);

use constant VALIDATORS => {
    name => \&_check_name,
    statement => \&_check_sql,
    is_active => \&Bugzilla::Object::check_boolean,
    sort_order => \&_check_sort_order,
};


# Accessors
sub name            { return $_[0]->{name} }
sub statement       { return $_[0]->{statement} }
sub is_active       { return $_[0]->{is_active} }
sub sort_order      { return $_[0]->{sort_order} }

# Mutators
sub set_name        { $_[0]->set('name', $_[1]); }
sub set_statement   { $_[0]->set('statement', $_[1]); }
sub set_is_active   { $_[0]->set('is_active', $_[1]); }
sub set_sort_order  { $_[0]->set('sort_order', $_[1]); }

# Validators
sub _check_name {
    my ($invocant, $value) = @_;
    my $name = trim($value);
    ThrowUserError('invalid_parameter', {
            name => 'name',
            err => 'Name must not be empty'})
        unless $name;
    if (!blessed($invocant) || lc($invocant->name) ne lc($name)) {
        ThrowUserError('invalid_parameter', {
            name => 'name',
            err => "Query with name '$name' already exists"})
            if defined Bugzilla::Extension::ChangeLog::Query->new(
                {name => $name});
    }
    return $name;
}

sub _check_sort_order {
    my ($invocant, $value) = @_;
    ThrowUserError('invalid_parameter', {
            name => 'sort order',
            err => 'Must be numeric value',
        }) unless detaint_natural($value);
    return $value;
}

sub _check_sql {
    my ($invocant, $value) = @_;
    $value = trim($value);
    if ($value =~ m/(CREATE |INSERT |REPLACE |UPDATE |DELETE )/i) {
        ThrowUserError('invalid_parameter', {
            name => 'statement',
            err => "Only 'SELECT' allowed.  Found '$1' in query: $value"
        });
    }
    my $query = _prepare_sql($value, {});
    my $dbh = Bugzilla->dbh;
    my $sth;
    eval {
        $sth = $dbh->prepare($query);
        $sth->execute();
    };
    ThrowUserError('invalid_parameter', {
        name => 'statement',
        err => $dbh->errstr || $@,
    }) if ($@ || $dbh->err);

    ThrowUserError('invalid_parameter', {
        name => 'statement',
        err => "Query '$query' doesn't act like a SELECT query"
    }) if ($sth->{NUM_OF_FIELDS} <= 0);

    return $value;
}

sub _prepare_sql {
    my ($query, $params) = @_;
    my $from_date = $params->{from_date};
    $from_date ||= DateTime->now();
    my $date_string = $from_date->ymd . ' ' . $from_date->hms;
    $query =~ s/(['"]*)<from-date>(['"]*)/'$date_string'/;

    my $user_id = Bugzilla->user->id;
    $query =~ s/(['"]*)<user-id>(['"]*)/'$user_id'/;
    trick_taint($query);
    return $query;
}

=head1 METHODS

=head2 execute

Executes the query and returns the rows

=cut

sub execute {
    my ($self, $params) = @_;
    my $query = _prepare_sql($self->statement, $params);

    Bugzilla->switch_to_shadow_db();
    my $sth = Bugzilla->dbh->prepare($query);
    $sth->execute();
    my $data = {
        columns => $sth->{NAME} || [],
        data => $sth->fetchall_arrayref,
    };
    Bugzilla->switch_to_main_db();
    return $data;
}

1;
