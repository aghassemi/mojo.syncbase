// Copyright 2015 The Vanadium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

library syncbase_database_test;

import 'dart:async';
import 'dart:convert' show UTF8;

import 'package:async/async.dart' show StreamSplitter;
import 'package:test/test.dart';

import 'package:syncbase/src/testing_instrumentation.dart' as testing;
import 'package:syncbase/syncbase_client.dart'
    show SyncbaseClient, WatchChangeTypes, WatchChange, WatchGlobStreamImpl;

import './utils.dart' as utils;

Iterable<String> decodeStrs(List<List<int>> bufList) {
  return bufList.map((x) => UTF8.decode(x));
}

Future checkWatch(
    Stream<WatchChange> stream, List<WatchChange> expected) async {
  var changeNum = 0;
  await for (var change in stream) {
    // Classes generated by the mojom Dart compiler do not override == and
    // hashCode, but do override toString. So, we use toString for our
    // equality checks.
    expect(change.toString(), equals(expected[changeNum].toString()));
    changeNum++;
    // Break out of waiting for values on the watch stream. (Ideally we'd
    // cancel the stream, but such a mechanism does not yet exist.)
    // TODO(sadovsky): It would be nice to somehow test that no extra values
    // show up on the watch stream.
    if (changeNum == expected.length) {
      break;
    }
  }
}

runDatabaseTests(SyncbaseClient c) {
  test('getting a handle to a database', () {
    var app = c.app(utils.uniqueName('app'));
    var dbName = utils.uniqueName('db');
    var db = app.noSqlDatabase(dbName);
    expect(db.name, equals(dbName));
    expect(db.fullName, equals(app.fullName + '/' + dbName));
  });

  test('creating and destroying a database', () async {
    var app = c.app(utils.uniqueName('app'));
    await app.create(utils.emptyPerms());

    var db = app.noSqlDatabase(utils.uniqueName('db'));

    expect(await db.exists(), equals(false));
    await db.create(utils.emptyPerms());
    expect(await db.exists(), equals(true));
    await db.destroy();
    expect(await db.exists(), equals(false));
  });

  test('listing tables', () async {
    var app = c.app(utils.uniqueName('app'));
    await app.create(utils.emptyPerms());
    var db = app.noSqlDatabase(utils.uniqueName('db'));
    await db.create(utils.emptyPerms());

    var want = [utils.uniqueName('table1'), utils.uniqueName('table2')];
    want.sort();

    for (var tableName in want) {
      await db.table(tableName).create(utils.emptyPerms());
    }

    var got = await db.listTables();
    got.sort((t1, t2) => t1.compareTo(t2));
    expect(got.length, equals(want.length));
    for (var i = 0; i < got.length; i++) {
      expect(got[i], equals(want[i]));
    }
  });

  test('basic watch', () async {
    var app = c.app(utils.uniqueName('app'));
    await app.create(utils.emptyPerms());
    var db = app.noSqlDatabase(utils.uniqueName('db'));
    await db.create(utils.emptyPerms());
    var table = db.table(utils.uniqueName('table'));
    await table.create(utils.emptyPerms());

    // Perform some operations before we start watching.
    await table.put('row1', UTF8.encode('value1'));
    await table.delete('row1');
    await table.put('row3', UTF8.encode('value3'));
    await table.put('row4', UTF8.encode('value4'));

    var resumeMarker = await db.getResumeMarker();
    var initialChanges = [
      SyncbaseClient.watchChange(table.name, 'row3', [], WatchChangeTypes.put,
          valueBytes: UTF8.encode('value3'), continued: true),
      SyncbaseClient.watchChange(
          table.name, 'row4', resumeMarker, WatchChangeTypes.put,
          valueBytes: UTF8.encode('value4'))
    ];

    // Start watching from current resumeMarker.
    var prefix = '';
    var watchStream = db.watch(table.name, prefix, resumeMarker);

    // Also start watching with empty resume marker.
    // Split into two streams to allow verifying at different times.
    var watchStreamsWithInitialState = StreamSplitter.splitFrom(
        db.watch(table.name, prefix), 2);

    // Wait for the empty resume marker watch to see initial changes.
    await checkWatch(watchStreamsWithInitialState[0], initialChanges);

    // Perform some operations after we've started watching.
    var expectedChanges = new List<WatchChange>();

    await table.put('row2', UTF8.encode('value2'));
    resumeMarker = await db.getResumeMarker();
    var expectedChange = SyncbaseClient.watchChange(
        table.name, 'row2', resumeMarker, WatchChangeTypes.put,
        valueBytes: UTF8.encode('value2'));
    expectedChanges.add(expectedChange);

    await table.delete('row2');
    resumeMarker = await db.getResumeMarker();
    expectedChange = SyncbaseClient.watchChange(
        table.name, 'row2', resumeMarker, WatchChangeTypes.delete);
    expectedChanges.add(expectedChange);

    // Check that we see all changes made since we started watching.
    await checkWatch(watchStream, expectedChanges);
    // Check that the empty resume marker watch also sees initial changes.
    await checkWatch(watchStreamsWithInitialState[1],
        []..addAll(initialChanges)..addAll(expectedChanges));
  });

  test('watch flow control', () async {
    var app = c.app(utils.uniqueName('app'));
    await app.create(utils.emptyPerms());
    var db = app.noSqlDatabase(utils.uniqueName('db'));
    await db.create(utils.emptyPerms());
    var table = db.table(utils.uniqueName('table'));
    await table.create(utils.emptyPerms());

    var resumeMarker = await db.getResumeMarker();
    var aFewMoments = new Duration(seconds: 1);
    const int numOperations = 10;
    var allOperations = [];

    // Do several put operations in parallel and wait until they are all done.
    for (var i = 0; i < numOperations; i++) {
      allOperations.add(table.put('row $i', UTF8.encode('value$i')));
    }
    await Future.wait(allOperations);

    // Reset testing instrumentation.
    testing.DatabaseWatch.onChangeCounter.reset();

    // Create a watch stream.
    var watchStream = db.watch(table.name, '', resumeMarker);

    // Listen for the data on the stream.
    var allExpectedChangesReceived = new Completer();
    onData(_) {
      if (testing.DatabaseWatch.onChangeCounter.count == numOperations) {
        allExpectedChangesReceived.complete();
      }
    }
    var streamListener = watchStream.listen(onData);

    // Pause the stream.
    streamListener.pause();

    // Wait a few moments.
    await new Future.delayed(aFewMoments);

    // Use testing.DatabaseWatch.onChangeCounter to verify that we didn't
    // receive any* events from the server after pausing the stream, i.e. that
    // the pause propagated to the server end of the pipe.
    // *Note: Since no-ack is what tells the server to stop sending changes, we
    // always get one change on the stream after pausing.
    expect(testing.DatabaseWatch.onChangeCounter.count, equals(1));

    // Resume the stream.
    streamListener.resume();

    // Wait until we get all expected changes.
    await allExpectedChangesReceived.future;

    // Assert we've received all the expected changes after resuming.
    expect(testing.DatabaseWatch.onChangeCounter.count, equals(numOperations));
  });

  test('basic exec', () async {
    var app = c.app(utils.uniqueName('app'));
    await app.create(utils.emptyPerms());
    var db = app.noSqlDatabase(utils.uniqueName('db'));
    await db.create(utils.emptyPerms());
    var table = db.table('airports');
    await table.create(utils.emptyPerms());

    await table.put('aӲ읔', UTF8.encode('ᚸӲ읔+קAل'));
    await table.put('yyz', UTF8.encode('Toronto'));

    var query = 'select k as code, v as cityname from airports';
    var resultStream = db.exec(query);

    var results = await resultStream.toList();
    // Expect column headers plus two rows.
    expect(results.length, 3);

    // Check column headers.
    expect(decodeStrs(results[0].values), equals(['code', 'cityname']));

    // Check rows.
    expect(decodeStrs(results[1].values), equals(['aӲ읔', 'ᚸӲ읔+קAل']));
    expect(decodeStrs(results[2].values), equals(['yyz', 'Toronto']));
  });

  test('parameterized exec', () async {
    var app = c.app(utils.uniqueName('app'));
    await app.create(utils.emptyPerms());
    var db = app.noSqlDatabase(utils.uniqueName('db'));
    await db.create(utils.emptyPerms());
    var table = db.table('airports');
    await table.create(utils.emptyPerms());

    await table.put('jfk', UTF8.encode('New York'));
    await table.put('lga', UTF8.encode('New York'));
    await table.put('ord', UTF8.encode('Chicago'));
    await table.put('sfo', UTF8.encode('San Francisco'));

    // TODO(ivanpi): Once VDL types are in, add parameterized key comparison
    // and non-string parameters in where clause.
    var query = 'select k as code, v as cityname from airports where v = ? or v = ?';
    var resultStream = db.exec(query, [UTF8.encode('Chicago'), UTF8.encode('New York')]);

    var results = await resultStream.toList();
    // Expect column headers plus three rows.
    expect(results.length, 4);

    // Check column headers.
    expect(decodeStrs(results[0].values), equals(['code', 'cityname']));

    // Check rows.
    expect(decodeStrs(results[1].values), equals(['jfk', 'New York']));
    expect(decodeStrs(results[2].values), equals(['lga', 'New York']));
    expect(decodeStrs(results[3].values), equals(['ord', 'Chicago']));
  });

  // TODO(nlacasse): Test database.get/setPermissions.
}
