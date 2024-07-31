# 0.4.0
- Made the TimeoutException messages more consistent. Fixed a lint for Timeout Test
 Note: the Mutex timeout is ignored on Windows.

## 0.3.0
Added a timeout to the Mailbox.take, Mutex.runLocked and ConditionVariable.wait methods.


## 0.2.0

- Lower SDK lower bound to 3.0.0.

## 0.1.0

- Initial version.
- Expose `Mutex` and `ConditionVariable`
- Implement `Mailbox`.
