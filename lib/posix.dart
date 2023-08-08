// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of 'primitives.dart';

class _PosixMutex extends Mutex {
  static const _sizeInBytes = 64;

  final Pointer<pthread_mutex_t> _impl;

  static final _finalizer = Finalizer<Pointer<pthread_mutex_t>>((ptr) {
    pthread_mutex_destroy(ptr);
    calloc.free(ptr);
  });

  _PosixMutex()
      : _impl = calloc.allocate(_PosixMutex._sizeInBytes),
        super._() {
    if (pthread_mutex_init(_impl, nullptr) != 0) {
      calloc.free(_impl);
      throw StateError('failed to initialize mutex');
    }
    _finalizer.attach(this, _impl);
  }

  _PosixMutex.fromAddress(int address)
      : _impl = Pointer.fromAddress(address),
        super._();

  @override
  void lock() {
    if (pthread_mutex_lock(_impl) != 0) {
      throw StateError('failed to lock mutex');
    }
  }

  @override
  void unlock() {
    if (pthread_mutex_unlock(_impl) != 0) {
      throw StateError('failed to unlock mutex');
    }
  }

  @override
  int get _address => _impl.address;
}

class _PosixConditionVariable extends ConditionVariable {
  static const _sizeInBytes = 64;

  final Pointer<pthread_cond_t> _impl;

  static final _finalizer = Finalizer<Pointer<pthread_cond_t>>((ptr) {
    pthread_cond_destroy(ptr);
    calloc.free(ptr);
  });

  _PosixConditionVariable()
      : _impl = calloc.allocate(_PosixConditionVariable._sizeInBytes),
        super._() {
    if (pthread_cond_init(_impl, nullptr) != 0) {
      calloc.free(_impl);
      throw StateError('failed to initialize condition variable');
    }
    _finalizer.attach(this, _impl);
  }

  _PosixConditionVariable.fromAddress(int address)
      : _impl = Pointer.fromAddress(address),
        super._();

  @override
  void notify() {
    if (pthread_cond_signal(_impl) != 0) {
      throw StateError('failed to signal condition variable');
    }
  }

  @override
  void wait(covariant _PosixMutex mutex) {
    if (pthread_cond_wait(_impl, mutex._impl) != 0) {
      throw StateError('failed to wait on a condition variable');
    }
  }

  @override
  int get _address => _impl.address;
}
