import 'dart:async';

/// A utility to help detect race conditions by running multiple instances
/// of an asynchronous task concurrently.
class RaceDetector {
  /// Runs the provided [task] [iterations] times concurrently.
  /// 
  /// [delayBetweenStarts] can be used to slightly stagger the start times
  /// to increase the chance of catching certain types of races.
  static Future<List<T>> run<T>(
    int iterations,
    Future<T> Function() task, {
    Duration? delayBetweenStarts,
  }) async {
    final List<Future<T>> futures = [];
    for (int i = 0; i < iterations; i++) {
      if (delayBetweenStarts != null && i > 0) {
        await Future.delayed(delayBetweenStarts);
      }
      futures.add(task());
    }
    return await Future.wait(futures);
  }
}
