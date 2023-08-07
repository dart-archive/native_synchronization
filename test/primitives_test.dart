// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';

import 'package:ffi/ffi.dart';
import 'package:native_synchronization/primitives.dart';
import 'package:native_synchronization/sendable.dart';
import 'package:test/test.dart';

void main() {
  group('mutex', () {
    test('simple', () {
      final mutex = Mutex();
      mutex.lock();
      mutex.unlock();
    });

    void spawnTestIsolate(int ptrAddress, Sendable<Mutex> sendableMutex) {
      Isolate.run(() {
        final ptr = Pointer<Uint8>.fromAddress(ptrAddress);
        final mutex = sendableMutex.materialize();

        while (true) {
          sleep(Duration(milliseconds: 10));
          if (mutex.runLocked(() {
            if (ptr.value == 2) {
              return true;
            }
            ptr.value = 0;
            sleep(Duration(milliseconds: 500));
            ptr.value = 1;
            return false;
          })) {
            break;
          }
        }

        return null;
      });
    }

    test('isolate', () async {
      final ptr = calloc.allocate<Uint8>(1);
      final mutex = Mutex();

      spawnTestIsolate(ptr.address, mutex.asSendable);

      while (true) {
        final sw = Stopwatch()..start();
        if (mutex.runLocked(() {
          if (sw.elapsedMilliseconds > 300 && ptr.value == 1) {
            ptr.value = 2;
            return true;
          }
          return false;
        })) {
          break;
        }
        sleep(const Duration(milliseconds: 10));
      }
    });
  });

  group('condvar', () {
    void spawnTestIsolate(int ptrAddress, Sendable<Mutex> sendableMutex,
        Sendable<ConditionVariable> sendableCondVar) {
      Isolate.run(() {
        final ptr = Pointer<Uint8>.fromAddress(ptrAddress);
        final mutex = sendableMutex.materialize();
        final condVar = sendableCondVar.materialize();

        mutex.runLocked(() {
          ptr.value = 1;
          while (ptr.value != 2) {
            condVar.wait(mutex);
          }
        });
        return null;
      });
    }

    test('isolate', () {
      final ptr = calloc.allocate<Uint8>(1);
      final mutex = Mutex();
      final condVar = ConditionVariable();

      spawnTestIsolate(ptr.address, mutex.asSendable, condVar.asSendable);

      while (true) {
        final success = mutex.runLocked(() {
          if (ptr.value == 1) {
            ptr.value = 2;
            condVar.notify();
            return true;
          }
          return false;
        });
        if (success) {
          break;
        }
        sleep(const Duration(milliseconds: 20));
      }
    });
  });
}
