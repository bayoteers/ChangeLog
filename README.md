ChangeLog Bugzilla Extension
============================

ChangeLog shows you a table of the latest changes in Bugzilla, when those happened
and who was the originator.

ChangeLog's features:

*   Select date from where you want to show the result from (until today/now).
*   Show multiple results (tables) in tabs
*   All data updated when the date parameter is changed
*   CSV export per table


Installation
------------

This extension requires [BayotBase](https://github.com/bayoteers/BayotBase)
extension, so install it first.

1.  Put extension files in

        extensions/ChangeLog

2.  Run checksetup.pl

3.  Restart your webserver if needed (for exmple when running under mod_perl)

4.  Configure the queries as you like in Administration > Parameters > ChangeLog


Example queries
---------------

    "flags" "SELECT bugs.bug_id, bugs_activity.bug_when, products.name AS product, bugs_activity.removed AS changed_from, bugs_activity.added AS changed_to, profiles.login_name AS user FROM bugs_activity LEFT JOIN fielddefs ON bugs_activity.fieldid=fielddefs.id LEFT JOIN profiles ON bugs_activity.who = profiles.userid LEFT JOIN bugs ON bugs.bug_id = bugs_activity.bug_id LEFT JOIN products ON products.id = bugs.product_id WHERE fielddefs.name='flagtypes.name' AND TIMESTAMP(bugs_activity.bug_when) >= TIMESTAMP('<from-date>')"

    "severity" "SELECT bugs.bug_id, bugs_activity.bug_when, products.name AS product, bugs_activity.removed AS removed, bugs_activity.added AS added, profiles.login_name AS user FROM bugs_activity LEFT JOIN fielddefs ON bugs_activity.fieldid=fielddefs.id LEFT JOIN profiles ON bugs_activity.who = profiles.userid LEFT JOIN bugs ON bugs.bug_id = bugs_activity.bug_id LEFT JOIN products ON products.id = bugs.product_id WHERE fielddefs.name='bug_severity' AND TIMESTAMP(bugs_activity.bug_when) >= TIMESTAMP('<from-date>')"

    "reopened" "SELECT bugs.bug_id, bugs_activity.bug_when, products.name AS product, bugs_activity.removed AS removed, bugs_activity.added AS added, profiles.login_name AS user FROM bugs_activity LEFT JOIN fielddefs ON bugs_activity.fieldid=fielddefs.id LEFT JOIN profiles ON bugs_activity.who = profiles.userid LEFT JOIN bugs ON bugs.bug_id = bugs_activity.bug_id LEFT JOIN products ON products.id = bugs.product_id WHERE fielddefs.name='bug_status' AND bugs_activity.added='reopened' AND TIMESTAMP(bugs_activity.bug_when) >= TIMESTAMP('<from-date>')"

    "target_milestone" "SELECT bugs.bug_id, bugs_activity.bug_when, products.name as product, bugs_activity.removed AS removed, bugs_activity.added AS added, profiles.login_name AS user FROM bugs_activity LEFT JOIN fielddefs ON bugs_activity.fieldid=fielddefs.id LEFT JOIN profiles ON bugs_activity.who = profiles.userid LEFT JOIN bugs ON bugs.bug_id = bugs_activity.bug_id LEFT JOIN products ON products.id = bugs.product_id WHERE fielddefs.name='target_milestone' AND TIMESTAMP(bugs_activity.bug_when) >= TIMESTAMP('<from-date>')"


Included libraries
------------------

* [jQuery TableSorter v2.0.5b](http://tablesorter.com/docs/)
