import 'dart:async';
import 'package:flutter/foundation.dart';

class SleepTimerService {
  Timer? _timer;
  Duration? _remainingTime;
  final StreamController<Duration?> _remainingTimeController =
      StreamController<Duration?>.broadcast();

  Stream<Duration?> get remainingTimeStream => _remainingTimeController.stream;
  bool get isActive => _timer != null && _timer!.isActive;
  Duration? get remainingTime => _remainingTime;
  bool _isEndOfTrack = false;
  bool get isEndOfTrack => _isEndOfTrack;

  VoidCallback? onTimerEnd;

  void setEndOfTrack() {
    cancelTimer();
    _isEndOfTrack = true;
    _remainingTime = const Duration(seconds: -1);
    _remainingTimeController.add(_remainingTime);
  }

  void setTimer(Duration duration) {
    cancelTimer();
    _remainingTime = duration;
    _remainingTimeController.add(_remainingTime);

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingTime != null && _remainingTime!.inSeconds > 0) {
        _remainingTime = _remainingTime! - const Duration(seconds: 1);
        _remainingTimeController.add(_remainingTime);
      } else {
        cancelTimer();
        if (onTimerEnd != null) {
          onTimerEnd!();
        }
      }
    });
  }

  void cancelTimer() {
    _timer?.cancel();
    _timer = null;
    _remainingTime = null;
    _isEndOfTrack = false;
    _remainingTimeController.add(null);
  }

  void dispose() {
    cancelTimer();
    _remainingTimeController.close();
  }
}
