> [!NOTE]  
> The source-of-truth for this package has moved to
https://github.com/dart-lang/labs/tree/main/pkgs/native_synchronization.

## package:native_synchronization

This package exposes a portable interface for low-level thread
synchronization primitives like `Mutex` and `ConditionVariable`.

It also provides some slightly more high-level synchronization primitives
like `Mailbox` built on top of low-level primitives.

## Status: experimental

**NOTE**: This package is currently experimental and published under the
[labs.dart.dev](https://dart.dev/dart-team-packages) pub publisher in order to
solicit feedback.

For packages in the labs.dart.dev publisher we generally plan to either graduate
the package into a supported publisher (dart.dev, tools.dart.dev) after a period
of feedback and iteration, or discontinue the package. These packages have a
much higher expected rate of API and breaking changes.

Your feedback is valuable and will help us evolve this package. For general
feedback, suggestions, and comments, please file an issue in the
[bug tracker](https://github.com/dart-lang/native_synchronization/issues).
