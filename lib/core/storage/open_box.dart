import 'dart:async';
import 'package:hive/hive.dart';

/// Hive 2.2.3 also completes an internal opening future with an error when
/// opening fails. Its first caller cannot subscribe to that internal future.
/// Contain that duplicate async error here and report one failure to the UI.
Future<Box<T>> openBoxSafely<T>(String name) {
  final result = Completer<Box<T>>();
  void fail(Object error, StackTrace stack) {
    if (!result.isCompleted) result.completeError(error, stack);
  }

  runZonedGuarded(() async {
    try {
      final box = await Hive.openBox<T>(name, crashRecovery: false);
      if (!result.isCompleted) result.complete(box);
    } catch (error, stack) {
      fail(error, stack);
    }
  }, fail);
  return result.future;
}
