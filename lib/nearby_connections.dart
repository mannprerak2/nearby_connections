import 'dart:async';

import 'package:flutter/services.dart';

enum STRATEGY { P2P_CLUSTER, P2P_STAR, P2P_POINT_TO_POINT }
enum Status { CONNECTED, REJECTED, ERROR }

class Nearby {
  //for maintaining only 1 instance of this class
  static Nearby _instance;

  factory Nearby() {
    if (_instance == null) {
      _instance = Nearby._();
    }
    return _instance;
  }

  Nearby._() {
    _channel.setMethodCallHandler((handler) {
      Map<String, dynamic> args = handler.arguments;
      print("=====================");
      print(handler.method);
      args.forEach((s, d) {
        print(s + " : " + d.toString());
      });
      print("=====================");
      switch (handler.method) {
        case "ad.onConnectionInitiated":
          String endpointId = args['endpointId'];
          String endpointName = args['endpointName'];
          String authenticationToken = args['authenticationToken'];
          bool isIncomingConnection = args['isIncomingConnection'];
          
          return null;
        case "ad.onConnectionResult":
          String endpointId = args['endpointId'];
          Status statusCode = Status.values[args['statusCode']];

          return null;
        case "ad.onDisconnected":
          String endpointId = args['endpointId'];

          return null;

        case "dis.onEndpointFound":
          String endpointId = args['endpointId'];
          String endpointName = args['endpointName'];
          String serviceId = args['serviceId'];

          return null;
        case "dis.onEndpointLost":
          String endpointId = args['endpointId'];

          return null;
        default:
          return null;
      }
    });
  }

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

  Future<bool> startAdvertising(String userNickName, STRATEGY strategy,
      {void onConnctionInitiated(
          String endpointId, ConnectionInfo connectionInfo),
      void onConnectionResult(String endpointId, Status status),
      void onDisconnected(String endpointId)}) async {
    assert(userNickName != null && strategy != null);

    return await _channel.invokeMethod('startAdvertising', <String, dynamic>{
      'userNickName': userNickName,
      'strategy': strategy.index
    });
  }

  Future<void> stopAdvertising() async {
    await _channel.invokeMethod('stopAdvertising');
  }

  Future<bool> startDiscovery(
      String userNickName,
      STRATEGY strategy,
      void onEndpointFound(
          String endpointId, String endpointName, String serviceId),
      void onEndpointLost(String endpointId)) async {
    assert(userNickName != null && strategy != null);

    return await _channel.invokeMethod('startDiscovery', <String, dynamic>{
      'userNickName': userNickName,
      'strategy': strategy.index
    });
  }

  Future<void> stopDiscovery() async {
    await _channel.invokeMethod('stopDiscovery');
  }
}

abstract class ConnectionLifecycleCallback {
  void onConnectionInitiated(String endpointId, ConnectionInfo connectionInfo);
  void onConnectionResult(String endpointId, Status status);
  void onDisconnected(String endpointId);
}

abstract class EndpointDiscoveryCallback {
  void onEndpointFound(
      String endpointId, String endpointName, String serviceId);
  void onEndpointLost(String endpointId);
}

class ConnectionInfo {
  String endPointName, authenticationToken;
  bool isIncomingConnection;

  ConnectionInfo(
      this.endPointName, this.authenticationToken, this.isIncomingConnection);
}
