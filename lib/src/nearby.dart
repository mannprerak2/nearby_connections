import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:nearby_connections/src/defs.dart';
import 'package:nearby_connections/src/classes.dart';

/// The NearbyConnection class
///
/// Only one instance is maintained
/// even on calling Nearby() multiple times
///
/// All methods are asynchronous.
class Nearby {
  //Singleton pattern for maintaining only 1 instance of this class
  static Nearby _instance;
  factory Nearby() {
    if (_instance == null) {
      _instance = Nearby._();
    }
    return _instance;
  }

  Nearby._() {
    _channel.setMethodCallHandler((handler) {
      Map<dynamic, dynamic> args = handler.arguments;
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
        case "onPayloadReceived":
          String endpointId = args['endpointId'];
          int type = args['type'];
          Uint8List bytes = args['bytes'];
          int payloadId = args['payloadId'];
          String filePath = args['filePath'];

          Payload payload = Payload(
            type: PayloadType.values[type],
            bytes: bytes,
            id: payloadId,
            filePath: filePath,
          );

          _onPayloadReceived?.call(endpointId, payload);

          break;
        case "onPayloadTransferUpdate":
          String endpointId = args['endpointId'];
          int payloadId = args['payloadId'];
          int status = args['status'];
          int bytesTransferred = args['bytesTransferred'];
          int totalBytes = args['totalBytes'];

          PayloadTransferUpdate payloadTransferUpdate = PayloadTransferUpdate(
            id: payloadId,
            status: PayloadStatus.values[status],
            bytesTransferred: bytesTransferred,
            totalBytes: totalBytes,
          );

          _onPayloadTransferUpdate?.call(endpointId, payloadTransferUpdate);
          break;
      }
      return null;
    });
  }

  //for advertisers
  OnConnctionInitiated _advertConnectionInitiated, _discoverConnectionInitiated;
  OnConnectionResult _advertConnectionResult, _discoverConnectionResult;
  OnDisconnected _advertDisconnected, _discoverDisconnected;

  //for discoverers
  OnEndpointFound _onEndpointFound;
  OnEndpointLost _onEndpointLost;

  //for receiving payload
  OnPayloadReceived _onPayloadReceived;
  OnPayloadTransferUpdate _onPayloadTransferUpdate;

  static const MethodChannel _channel =
      const MethodChannel('nearby_connections');

  /// Convinience method
  ///
  /// retruns true/false based on location permissions.
  /// Discovery cannot be started with insufficient permission
  Future<bool> checkLocationPermission() async => await _channel.invokeMethod(
        'checkLocationPermission',
      );

  /// Convinience method
  ///
  /// Asks location permission
  void askLocationPermission() =>
      _channel.invokeMethod('askLocationPermission');

  /// Convinience method
  ///
  /// retruns true/false based on external storage permissions.
  Future<bool> checkExternalStoragePermission() async =>
      await _channel.invokeMethod(
        'checkExternalStoragePermission',
      );

  /// Convinience method
  ///
  /// Asks external storage permission, required for file
  void askExternalStoragePermission() =>
      _channel.invokeMethod('askExternalStoragePermission');

  /// Convinience method
  ///
  /// Use this instead of calling both [askLocationPermission()] and [askExternalStoragePermission()]
  void askLocationAndExternalStoragePermission() =>
      _channel.invokeMethod('askLocationAndExternalStoragePermission');

  /// Start Advertising, Discoverers would be able to discover this advertiser.
  ///
  /// [serviceId] is a unique identifier for your app, its recommended to use your app package name only, it cannot be null
  /// [userNickName] and [strategy] should not be null
  Future<bool> startAdvertising(
    String userNickName,
    Strategy strategy, {
    @required OnConnctionInitiated onConnectionInitiated,
    @required OnConnectionResult onConnectionResult,
    @required OnDisconnected onDisconnected,
    String serviceId = "com.pkmnapps.nearby_connections",
  }) async {
    assert(userNickName != null && strategy != null && serviceId != null);

    this._advertConnectionInitiated = onConnectionInitiated;
    this._advertConnectionResult = onConnectionResult;
    this._advertDisconnected = onDisconnected;

    return await _channel.invokeMethod('startAdvertising', <String, dynamic>{
      'userNickName': userNickName,
      'strategy': strategy.index,
      'serviceId': serviceId,
    });
  }

  /// Stop Advertising
  ///
  /// This doesn't disconnect from any connected Endpoint
  ///
  /// For disconnection use
  /// [stopAllEndpoints] or [disconnectFromEndpoint]
  Future<void> stopAdvertising() async {
    await _channel.invokeMethod('stopAdvertising');
  }

  /// Start Discovery, You will now be able to discover the advertisers now.
  ///
  /// [serviceId] is a unique identifier for your app, its recommended to use your app package name only, it cannot be null
  /// [userNickName] and [strategy] should not be null
  Future<bool> startDiscovery(
    String userNickName,
    Strategy strategy, {
    @required OnEndpointFound onEndpointFound,
    @required OnEndpointLost onEndpointLost,
    String serviceId = "com.pkmnapps.nearby_connections",
  }) async {
    assert(userNickName != null && strategy != null && serviceId != null);
    this._onEndpointFound = onEndpointFound;
    this._onEndpointLost = onEndpointLost;

    return await _channel.invokeMethod('startDiscovery', <String, dynamic>{
      'userNickName': userNickName,
      'strategy': strategy.index,
      'serviceId': serviceId,
    });
  }

  /// Stop Discovery
  ///
  /// This doesn't disconnect from already connected Endpoint
  ///
  /// It is reccomended to call this method
  /// once you have connected to an endPoint
  /// as discovery uses heavy radio operations
  /// which may affect connection speed and integrity
  Future<void> stopDiscovery() async {
    await _channel.invokeMethod('stopDiscovery');
  }

  /// Stop All Endpoints
  ///
  /// Disconnects all connections,
  /// this will call the onDisconnected method on callbacks of
  /// all connected endPoints
  Future<void> stopAllEndpoints() async {
    await _channel.invokeMethod('stopAllEndpoints');
  }

  /// Disconnect from Endpoints
  ///
  /// Disconnects the  connections to given endPointId
  /// this will call the onDisconnected method on callbacks of
  /// connected endPoint
  Future<void> disconnectFromEndpoint(String endpointId) async {
    assert(endpointId != null);
    await _channel.invokeMethod(
        'disconnectFromEndpoint', <String, dynamic>{'endpointId': endpointId});
  }

  /// Request Connection
  ///
  /// Call this method when Discoverer calls the
  /// [OnEndpointFound] method
  ///
  /// This will call the [OnConnctionInitiated] method on
  /// both the endPoint and this
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

    assert(endpointId != null);
    assert(userNickName != null);

    return await _channel.invokeMethod(
      'requestConnection',
      <String, dynamic>{
        'userNickName': userNickName,
        'endpointId': endpointId,
      },
    );
  }

  /// Needs be called by both discoverer and advertiser
  /// to connect
  ///
  /// Call this in [OnConnctionInitiated]
  /// to accept an incoming connection
  ///
  /// [OnConnectionResult] is called on both
  /// only if both of them accept the connection
  Future<bool> acceptConnection(
    String endpointId, {
    @required OnPayloadReceived onPayLoadRecieved,
    OnPayloadTransferUpdate onPayloadTransferUpdate,
  }) async {
    this._onPayloadReceived = onPayLoadRecieved;
    this._onPayloadTransferUpdate = onPayloadTransferUpdate;

    assert(endpointId != null);

    return await _channel.invokeMethod(
      'acceptConnection',
      <String, dynamic>{
        'endpointId': endpointId,
      },
    );
  }

  /// Reject Connection
  ///
  /// To be called by both discoverer and advertiser
  ///
  /// Call this in [OnConnctionInitiated]
  /// to reject an incoming connection
  ///
  /// [OnConnectionResult] is called on both
  /// even if one of them rejects the connection
  Future<bool> rejectConnection(String endpointId) async {
    assert(endpointId != null);

    return await _channel.invokeMethod(
      'rejectConnection',
      <String, dynamic>{
        'endpointId': endpointId,
      },
    );
  }

  /// Send bytes [Uint8List] payload to endpoint
  ///
  /// Convert String to Uint8List as follows -
  ///
  /// ```dart
  /// String a = "hello";
  /// Uint8List bytes = Uint8List.fromList(a.codeUnits);
  ///
  /// ```
  /// Convert bytes [Uint8List] to String as follows -
  /// ```dart
  /// String str = String.fromCharCodes(payload.bytes);
  /// ```
  ///
  Future<void> sendBytesPayload(String endpointId, Uint8List bytes) async {
    assert(endpointId != null);

    return await _channel.invokeMethod(
      'sendPayload',
      <String, dynamic>{
        'endpointId': endpointId,
        'bytes': bytes,
      },
    );
  }

  /// Returns the payloadID as soon as file transfer has begun
  ///
  /// File is received in DOWNLOADS_DIRECTORY and is given a generic name
  /// without extension
  /// You must also send a bytes payload to send the filename and extension
  /// so that receiver can rename the file accordingly
  /// Send the payloadID and filename to receiver as bytes payload
  Future<int> sendFilePayload(String endpointId, String filePath) async {
    assert(endpointId != null);

    return await _channel.invokeMethod(
      'sendFilePayload',
      <String, dynamic>{
        'endpointId': endpointId,
        'filePath': filePath,
      },
    );
  }

  /// Use it to cancel/stop a payload transfer
  Future<void> cancelPayload(int payloadId) async {
    assert(payloadId != null);

    return await _channel.invokeMethod(
      'cancelPayload',
      <String, dynamic>{
        'payloadId': payloadId.toString(),
      },
    );
  }
}
