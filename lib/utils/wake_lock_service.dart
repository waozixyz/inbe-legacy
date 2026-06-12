import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class WakeLockService {
  static const MethodChannel _channel = MethodChannel('io.naox.inbe/wake_lock');

  static Future<void> setEnabled(bool enabled) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return;
    }

    await _channel.invokeMethod('setKeepScreenOn', {'enabled': enabled});
  }
}
