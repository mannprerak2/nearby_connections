import 'dart:async';

import 'package:flutter/services.dart';

class Nearby {
  //for maintaining only 1 instance of this class
  static final Nearby _instance = Nearby._();
  static Nearby get instance => _instance;
  Nearby._();

  static const MethodChannel _channel =
      const MethodChannel('nearby_connections');

  Future<bool> checkPermissions() async => await _channel.invokeMethod(
        'checkPermissions',
      );
}
