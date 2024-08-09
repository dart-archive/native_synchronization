// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:native_synchronization_temp/mailbox.dart';
import 'package:native_synchronization_temp/sendable.dart';
import 'package:test/test.dart';

void main() {
  Future<String> startHelperIsolate(Sendable<Mailbox> sendableMailbox) async =>
      Isolate.run(() {
        sleep(const Duration(milliseconds: 500));
        sendableMailbox.materialize().put(Uint8List(42)..[41] = 42);
        return 'success';
      });

  test('mailbox', () async {
    final mailbox = Mailbox();
    final helperResult = startHelperIsolate(mailbox.asSendable);
    final value = mailbox.take();
    expect(value, isA<Uint8List>());
    expect(value.length, equals(42));
    expect(value[41], equals(42));
    expect(await helperResult, equals('success'));
  });

  test('mailbox - timeout', () async {
    final mailbox = Mailbox();
    expect(() => mailbox.take(timeout: const Duration(seconds: 2)),
        throwsA(isA<TimeoutException>()));
    final helperResult = startHelperIsolate(mailbox.asSendable);
    final value = mailbox.take(timeout: const Duration(seconds: 2));
    expect(value, isA<Uint8List>());
    expect(value.length, equals(42));
    expect(value[41], equals(42));
    expect(await helperResult, equals('success'));
  });

  Future<String> startHelperIsolateClose(Sendable<Mailbox> sendableMailbox) {
    return Isolate.run(() {
      sleep(const Duration(milliseconds: 500));
      final mailbox = sendableMailbox.materialize();
      try {
        mailbox.take();
      } catch (_) {
        return 'success';
      }
      return 'failed';
    });
  }

  test('mailbox close', () async {
    final mailbox = Mailbox();
    mailbox.put(Uint8List(42)..[41] = 42);
    mailbox.close();
    final helperResult = startHelperIsolateClose(mailbox.asSendable);
    expect(await helperResult, equals('success'));
  });
}
