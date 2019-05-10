import 'dart:async';

import 'package:flutter/services.dart';

enum STRATEGY { P2P_CLUSTER, P2P_STAR, P2P_POINT_TO_POINT }
enum Status { NONE, SUCCESS, FAILURE, IN_PROGRESS, CANCELED }

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

  Future<void> askPermission() async {
    await _channel.invokeMethod(
      'askPermissions',
    );
  }

  Future<bool> startAdvertising(String userNickName, STRATEGY strategy) async {
    assert(userNickName != null && strategy != null);

    return await _channel.invokeMethod('startAdvertising', <String, dynamic>{
      'userNickName': userNickName,
      'strategy': strategy.index
    });
  }

  Future<void> stopAdvertising() async {
    await _channel.invokeMethod('stopAdvertising');
  }
}

abstract class ConnectionLifecycleCallback {
  void onConnectionInitiated(String s, ConnectionInfo connectionInfo);
  void onConnectionResult(String s, Status status);
  void onDisconnected(String s) {}
}

class ConnectionInfo {
  String endPointName, authenticationToken;
  bool isIncomingConnection;

  ConnectionInfo(
      this.endPointName, this.authenticationToken, this.isIncomingConnection);
}
