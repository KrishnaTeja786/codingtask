import 'dart:async';

/// Drop-in debouncer for search inputs. Cancels prior pending callback so
/// only the most recent intent fires.
class Debouncer {
  Debouncer({this.delay = const Duration(milliseconds: 350)});
  final Duration delay;
  Timer? _timer;

  void run(void Function() action) {
    _timer?.cancel();
    _timer = Timer(delay, action);
  }

  void dispose() => _timer?.cancel();
}
