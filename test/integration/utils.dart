// Copyright 2015 The Vanadium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

library utils;

import 'package:syncbase/syncbase_client.dart' show Perms, SyncbaseClient;

// Returns an empty Perms object.
Perms emptyPerms() => SyncbaseClient.perms();

// Returns the current timestamp in ms since epoch.
int timestamp() => new DateTime.now().millisecondsSinceEpoch;

int _nameCounter = timestamp();

// Returns a new unique name.
String uniqueName(String type) {
  type ??= 'unknown';
  _nameCounter++;
  return type + '_' + _nameCounter.toString();
}