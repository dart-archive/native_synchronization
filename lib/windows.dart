// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of 'primitives.dart';

class _WindowsMutex extends Mutex {
  static const _sizeInBytes = 8;

  final Pointer<SRWLOCK> _impl;

  static final _finalizer = Finalizer<Pointer<SRWLOCK>>((ptr) {
    calloc.free(ptr);
  });

  _WindowsMutex()
      : _impl = calloc.allocate(_WindowsMutex._sizeInBytes),
        super._() {
    InitializeSRWLock(_impl);
    _finalizer.attach(this, _impl);
  }

  _WindowsMutex.fromAddress(int address)
      : _impl = Pointer.fromAddress(address),
        super._();

  @override
  void lock() => AcquireSRWLockExclusive(_impl);

  @override
  void unlock() => ReleaseSRWLockExclusive(_impl);

  @override
  int get _address => _impl.address;
}

class _WindowsConditionVariable extends ConditionVariable {
  static const _sizeInBytes = 8;

  final Pointer<CONDITION_VARIABLE> _impl;

  static final _finalizer = Finalizer<Pointer<CONDITION_VARIABLE>>((ptr) {
    calloc.free(ptr);
  });

  _WindowsConditionVariable()
      : _impl = calloc.allocate(_WindowsConditionVariable._sizeInBytes),
        super._() {
    InitializeConditionVariable(_impl);
    _finalizer.attach(this, _impl);
  }

  _WindowsConditionVariable.fromAddress(int address)
      : _impl = Pointer.fromAddress(address),
        super._();

  @override
  void notify() {
    WakeConditionVariable(_impl);
  }

  @override
  void wait(covariant _WindowsMutex mutex) {
    const infinite = 0xFFFFFFFF;
    const exclusive = 0;
    if (SleepConditionVariableSRW(_impl, mutex._impl, infinite, exclusive) ==
        0) {
      throw StateError('failed to wait on a condition variable');
    }
  }

  @override
  int get _address => _impl.address;
}
