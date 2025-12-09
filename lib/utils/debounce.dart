import 'dart:async';

/// Utility class for debouncing function calls
/// Useful for search inputs, API calls triggered by user input, etc.
class Debounce {
  final Duration delay;
  Timer? _timer;

  Debounce({this.delay = const Duration(milliseconds: 500)});

  /// Call the function after the delay period
  /// If called again before the delay expires, the previous call is cancelled
  void call(void Function() action) {
    _timer?.cancel();
    _timer = Timer(delay, action);
  }

  /// Cancel any pending debounced calls
  void cancel() {
    _timer?.cancel();
  }

  /// Dispose the debounce instance
  void dispose() {
    _timer?.cancel();
  }
}

/// Extension for debouncing Stream events
extension DebounceExtension<T> on Stream<T> {
  /// Debounce stream events
  Stream<T> debounce(Duration duration) {
    var lastEventTime = DateTime.now();
    var controller = StreamController<T>();

    listen((event) {
      lastEventTime = DateTime.now();
      Future.delayed(duration, () {
        if (DateTime.now().difference(lastEventTime) >= duration) {
          controller.add(event);
        }
      });
    });

    return controller.stream;
  }
}


