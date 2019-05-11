import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

enum STRATEGY { P2P_CLUSTER, P2P_STAR, P2P_POINT_TO_POINT }
enum Status { CONNECTED, REJECTED, ERROR }

typedef void OnConnctionInitiated(
    String endpointId, ConnectionInfo connectionInfo);
typedef void OnConnectionResult(String endpointId, Status status);
typedef void OnDisconnected(String endpointId);

typedef void OnEndpointFound(
    String endpointId, String endpointName, String serviceId);
typedef void OnEndpointLost(String endpointId);

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

          _advertConnectionInitiated?.call(
              endpointId,
              ConnectionInfo(
                  endpointName, authenticationToken, isIncomingConnection));

          return null;
        case "ad.onConnectionResult":
          String endpointId = args['endpointId'];
          Status statusCode = Status.values[args['statusCode']];

          _advertConnectionResult?.call(endpointId, statusCode);

          return null;
        case "ad.onDisconnected":
          String endpointId = args['endpointId'];

          _advertDisconnected?.call(endpointId);

          return null;

        case "dis.onConnectionInitiated":
          String endpointId = args['endpointId'];
          String endpointName = args['endpointName'];
          String authenticationToken = args['authenticationToken'];
          bool isIncomingConnection = args['isIncomingConnection'];

          _discoverConnectionInitiated?.call(
              endpointId,
              ConnectionInfo(
                  endpointName, authenticationToken, isIncomingConnection));

          return null;
        case "dis.onConnectionResult":
          String endpointId = args['endpointId'];
          Status statusCode = Status.values[args['statusCode']];

          _discoverConnectionResult?.call(endpointId, statusCode);

          return null;
        case "dis.onDisconnected":
          String endpointId = args['endpointId'];

          _discoverDisconnected?.call(endpointId);

          return null;

        case "dis.onEndpointFound":
          String endpointId = args['endpointId'];
          String endpointName = args['endpointName'];
          String serviceId = args['serviceId'];

          _onEndpointFound?.call(endpointId, endpointName, serviceId);

          return null;
        case "dis.onEndpointLost":
          String endpointId = args['endpointId'];

          _onEndpointLost?.call(endpointId);

          return null;
        default:
          return null;
      }
    });
  }

  OnConnctionInitiated _advertConnectionInitiated, _discoverConnectionInitiated;
  OnConnectionResult _advertConnectionResult, _discoverConnectionResult;
  OnDisconnected _advertDisconnected, _discoverDisconnected;

  OnEndpointFound _onEndpointFound;
  OnEndpointLost _onEndpointLost;

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

  Future<bool> startAdvertising(
    String userNickName,
    STRATEGY strategy, {
    @required OnConnctionInitiated onConnectionInitiated,
    @required OnConnectionResult onConnectionResult,
    @required OnDisconnected onDisconnected,
  }) async {
    assert(userNickName != null && strategy != null);

    this._advertConnectionInitiated = onConnectionInitiated;
    this._advertConnectionResult = onConnectionResult;
    this._advertDisconnected = onDisconnected;

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
    STRATEGY strategy, {
    OnEndpointFound onEndpointFound,
    OnEndpointLost onEndpointLost,
  }) async {
    assert(userNickName != null && strategy != null);

    return await _channel.invokeMethod('startDiscovery', <String, dynamic>{
      'userNickName': userNickName,
      'strategy': strategy.index
    });
  }

  Future<void> stopDiscovery() async {
    await _channel.invokeMethod('stopDiscovery');
  }

  Future<void> stopAllEndpoints() async {
    await _channel.invokeMethod('stopAllEndpoints');
  }

  Future<void> disconnectFromEndpoint(String endpointId) async {
    await _channel.invokeMethod(
        'disconnectFromEndpoint', <String, dynamic>{'endpointId': endpointId});
  }

  Future<bool> requestConnection(
    String userNickName,
    String endpointId, {
    @required OnConnctionInitiated onConnectionInitiated,
    @required OnConnectionResult onConnectionResult,
    @required OnDisconnected onDisconnected,
  }) async {
    this._discoverConnectionInitiated = onConnectionInitiated;
    this._discoverConnectionResult = onConnectionResult;
    this._discoverDisconnected = onDisconnected;

    return await _channel.invokeMethod(
      'requestConnection',
      <String, dynamic>{
        'userNickName': userNickName,
        'endpointId': endpointId,
      },
    );
  }

  Future<bool> acceptConnection(String endpointId) async {
    return await _channel.invokeMethod(
      'acceptConnection',
      <String, dynamic>{
        'endpointId': endpointId,
      },
    );
  }

  Future<bool> rejectConnection(String endpointId) async {
    return await _channel.invokeMethod(
      'acceptConnection',
      <String, dynamic>{
        'endpointId': endpointId,
      },
    );
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
  String endpointName, authenticationToken;
  bool isIncomingConnection;

  ConnectionInfo(
      this.endpointName, this.authenticationToken, this.isIncomingConnection);
}
