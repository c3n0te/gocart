import 'dart:async';

// --- Simple Sequential Lock / Task Queue Helper ---
class SequentialLock {
  Future<void> _lastTask = Future.value();

  Future<T> add<T>(Future<T> Function() task) {
    final completer = Completer<T>();
    
    _lastTask.whenComplete(() async {
      try {
        final result = await task();
        completer.complete(result);
      } catch (e, st) {
        completer.completeError(e, st);
      }
    });

    _lastTask = completer.future.catchError((_) => null as dynamic);
    return completer.future;
  }
}