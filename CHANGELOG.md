## 0.5.0
- Added an initial call to GetLastError for windows to get around the dynamic link of windows dlls which can result in other windows system calls between when dart calls GetLastError and when it is actually called in the windows subsystem.
- changed all print statemetns to use the dart logger and cleaned up the logging messages. 
- Now support microsecond resolution for timeouts.
- Fixed a bug in the calculations for remaining time when the wait wakes up for sperious reasons. 
- Add closed state to Mailbox (#26) - calling MailBox.close is still not fully supported due to https://github.com/dart-lang/sdk/issues/56412

## 0.4.0
- Added a timeout to the Mailbox.take, Mutex.runLocked and ConditionVariable.wait methods.
 Note: the Mutex timeout is ignored on Windows.

## 0.3.0
- Add a closed state to `Mailbox`.

## 0.2.0

- Lower SDK lower bound to 3.0.0.

## 0.1.0

- Initial version.
- Expose `Mutex` and `ConditionVariable`
- Implement `Mailbox`.
