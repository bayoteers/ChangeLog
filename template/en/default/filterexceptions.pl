# -*- Mode: perl; indent-tabs-mode: nil -*-

%::safe = (

'pages/ChangeLog.html.tmpl' => [
  'q.id',
],

'pages/ChangeLogTable.html.tmpl' => [
  'query.id',
],

'pages/ChangeLogTable.csv.tmpl' => [
  'separator UNLESS loop.last',
],

'hook/admin/admin-end_links_right.html.tmpl' => [
  'class',
]

);
