import 'dart:async';

import 'package:flutter/services.dart';

class NearbyConnections {
  static const MethodChannel _channel =
      const MethodChannel('nearby_connections');

  static Future<String> get platformVersion async {
    final String version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }
}
