// Copyright 2015 The Vanadium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

library syncbase_row_test;

import 'dart:convert' show UTF8;

import 'package:test/test.dart';

import 'package:syncbase/syncbase_client.dart' show SyncbaseClient;

import './utils.dart' as utils;

runRowTests(SyncbaseClient c) {
  test('getting a handle to a row', () {
    var app = c.app(utils.uniqueName('app'));
    var db = app.noSqlDatabase(utils.uniqueName('db'));
    var table = db.table(utils.uniqueName('table'));

    var rowKey = utils.uniqueName('row');
    var row = table.row(rowKey);

    expect(row.name, equals(rowKey));
    expect(row.fullName, equals(table.fullName + '/' + rowKey));
  });

  test('putting, getting and deleting row', () async {
    var app = c.app(utils.uniqueName('app/a\$%b')); // symbols are okay
    await app.create(utils.emptyPerms());
    var db = app.noSqlDatabase(utils.uniqueName('db'));
    await db.create(utils.emptyPerms());
    var table = db.table(utils.uniqueName('table'));
    await table.create(utils.emptyPerms());

    var row = table.row(utils.uniqueName('row/a\$%b')); // symbols are okay

    expect(await row.exists(), equals(false));

    var value1 = UTF8.encode('foo');
    await row.put(value1);

    expect(await row.exists(), equals(true));
    expect(await row.get(), equals(value1));

    var value2 = UTF8.encode('bar');
    await row.put(value2);

    expect(await row.exists(), equals(true));
    expect(await row.get(), equals(value2));

    await row.delete();
    expect(await row.exists(), equals(false));
  });
}
