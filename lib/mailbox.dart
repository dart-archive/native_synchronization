// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:ffi';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';

import 'primitives.dart';
import 'sendable.dart';

final class _MailboxRepr extends Struct {
  external Pointer<Uint8> buffer;

  @Int32()
  external int bufferLength;

  @Int32()
  external int state;
}

class _SendableMailbox {
  final int address;
  final Sendable<Mutex> mutex;
  final Sendable<ConditionVariable> condVar;

  _SendableMailbox(
      {required this.address, required this.mutex, required this.condVar});
}

/// Mailbox communication primitive.
///
/// This synchronization primitive allows a single producer to send messages
/// to one or more consumers. Producer uses [put] to place a message into
/// a mailbox which consumers can then [take] out.
///
/// [Mailbox] object can not be directly sent to other isolates via a
/// `SendPort`, but it can be converted to a `Sendable<Mailbox>` via
/// `asSendable` getter.
///
/// [Mailbox] object is owned by an isolate which created them.
class Mailbox {
  final Pointer<_MailboxRepr> _mailbox;
  final Mutex _mutex;
  final ConditionVariable _condVar;

  static const _stateEmpty = 0;
  static const _stateFull = 1;
  static const _stateClosed = 2;

  static final finalizer = Finalizer((mailbox) {
    final p = mailbox! as Pointer<_MailboxRepr>;
    calloc
      ..free(p.ref.buffer)
      ..free(p);
  });

  Mailbox()
      : _mailbox = calloc.allocate(sizeOf<_MailboxRepr>()),
        _mutex = Mutex(),
        _condVar = ConditionVariable() {
    finalizer.attach(this, _mailbox);
  }

  Mailbox._fromSendable(_SendableMailbox sendable)
      : _mailbox = Pointer.fromAddress(sendable.address),
        _mutex = sendable.mutex.materialize(),
        _condVar = sendable.condVar.materialize();

  /// Place a message into the mailbox if has space for it.
  ///
  /// If mailbox already contains a message or mailbox is closed then [put] will
  /// throw [StateError].
  void put(Uint8List message) {
    final buffer = message.isEmpty ? nullptr : _toBuffer(message);
    _mutex.runLocked(() {
      if (_mailbox.ref.state != _stateEmpty) {
        throw StateError('Mailbox is closed or full');
      }

      _mailbox.ref.state = _stateFull;
      _mailbox.ref.buffer = buffer;
      _mailbox.ref.bufferLength = message.length;

      _condVar.notify();
    });
  }

  /// Close a mailbox.
  ///
  /// If mailbox already contains a message then [close] will drop the message.
  void close() => _mutex.runLocked(() {
        if (_mailbox.ref.state == _stateFull && _mailbox.ref.bufferLength > 0) {
          malloc.free(_mailbox.ref.buffer);
        }

        _mailbox.ref.state = _stateClosed;
        _mailbox.ref.buffer = nullptr;
        _mailbox.ref.bufferLength = 0;

        _condVar.notify();
      });

  /// Take a message from the mailbox.
  ///
  /// If the mailbox is empty this will synchronously block until message
  /// is available or a timeout occurs.
  /// If the mailbox is closed then [take] will throw [StateError].
  ///
  /// If not [timeout] is provided then this method will block
  /// indefinitely.
  ///
  /// If [timeout] is provided then this will block for at most [timeout].
  /// If the timeout expires before a message is available then this will
  /// throw a [TimeoutException].
  /// The [timeout] supports a resolution of microseconds.
  Uint8List take({Duration? timeout}) {
    if (timeout != null) {
      return _takeTimed(timeout);
    } else {
      return _take();
    }
  }

  Uint8List _takeTimed(final Duration timeout) {
    final start = DateTime.now();

    return _mutex.runLocked(
      timeout: timeout,
      () {
        /// Wait for an item to be posted into the mailbox.
        while (_mailbox.ref.state == _stateEmpty) {
          final remainingTime = _remainingTime(timeout, start);
          _condVar.wait(_mutex, timeout: remainingTime);
        }
        if (_mailbox.ref.state == _stateClosed) {
          throw StateError('Mailbox is closed');
        }

        final result = _toList(_mailbox.ref.buffer, _mailbox.ref.bufferLength);

        _mailbox.ref.state = _stateEmpty;
        _mailbox.ref.buffer = nullptr;
        _mailbox.ref.bufferLength = 0;
        return result;
      },
    );
  }

  Duration _remainingTime(Duration timeout, DateTime start) {
    var remainingTime = timeout - (DateTime.now().difference(start));
    if (remainingTime < Duration.zero) {
      remainingTime = Duration.zero;
    }
    return remainingTime;
  }

  Uint8List _take() => _mutex.runLocked(() {
        while (_mailbox.ref.state == _stateEmpty) {
          _condVar.wait(_mutex);
        }

        if (_mailbox.ref.state == _stateClosed) {
          throw StateError('Mailbox is closed');
        }

        final result = _toList(_mailbox.ref.buffer, _mailbox.ref.bufferLength);

        _mailbox.ref.state = _stateEmpty;
        _mailbox.ref.buffer = nullptr;
        _mailbox.ref.bufferLength = 0;
        return result;
      });

  static final _emptyResponse = Uint8List(0);

  static Uint8List _toList(Pointer<Uint8> buffer, int length) {
    if (length == 0) {
      return _emptyResponse;
    }

    // TODO: remove feature detection once 3.1 becomes stable.
    // ignore: omit_local_variable_types
    final Uint8List Function(int) asTypedList = buffer.asTypedList;
    if (asTypedList is Uint8List Function(int,
        {Pointer<NativeFinalizerFunction> finalizer})) {
      return asTypedList(length, finalizer: malloc.nativeFree);
    }

    final result = Uint8List(length)
      ..setRange(0, length, buffer.asTypedList(length));
    malloc.free(buffer);
    return result;
  }

  static Pointer<Uint8> _toBuffer(Uint8List list) {
    final buffer = malloc.allocate<Uint8>(list.length);
    buffer.asTypedList(list.length).setRange(0, list.length, list);
    return buffer;
  }

  Sendable<Mailbox> get asSendable => Sendable.wrap(
      Mailbox._fromSendable,
      _SendableMailbox(
          address: _mailbox.address,
          mutex: _mutex.asSendable,
          condVar: _condVar.asSendable));
}
