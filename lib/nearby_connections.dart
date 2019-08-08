import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// **P2P_CLUSTER** - best for small payloads and multiplayer games
///
/// **P2P_STAR** - best for medium payloads, higher bandwidth than cluster
///
/// **P2P_POINT_TO_POINT** - single connection, very high bandwidth
enum Strategy { P2P_CLUSTER, P2P_STAR, P2P_POINT_TO_POINT }
enum Status { CONNECTED, REJECTED, ERROR }
enum PayloadStatus { NONE, SUCCESS, FAILURE, IN_PROGRRESS, CANCELED }
enum PayloadType { NONE, BYTES, FILES, STREAM }
typedef void OnConnctionInitiated(
    String endpointId, ConnectionInfo connectionInfo);
typedef void OnConnectionResult(String endpointId, Status status);
typedef void OnDisconnected(String endpointId);

typedef void OnEndpointFound(
    String endpointId, String endpointName, String serviceId);
typedef void OnEndpointLost(String endpointId);

/// For Bytes, this contains the bytes dala
///
/// For File, this marks the start of transfer
///
/// Uint8List bytes may be null, if [payloadType] is not [PayloadType.BYTES]
typedef void OnPayloadReceived(
    String endpointId, Uint8List bytes, PayloadType payloadType);

/// Called only once for Bytes and repeatedly for File until transfer is complete
typedef void OnPayloadTransferUpdate(
    {String endpointId,
    int payloadId,
    PayloadStatus payloadStatus,
    int bytesTransferred,
    int totalBytes});

// typedef void OnPayloadTransferUpdate();
/// The NearbyConnection class
///
/// Only one instance is maintained
/// even on calling Nearby() multiple times
///
/// All methods are asynchronous.
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
      print("=========in handler============");

      Map<dynamic, dynamic> args = handler.arguments;

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
          print("in switch");
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

          _onPayloadReceived?.call(endpointId, bytes, PayloadType.values[type]);

          break;
        case "onPayloadTransferUpdate":
          String endpointId = args['endpointId'];
          int payloadId = args['payloadId'];
          int success = args['success'];
          int bytesTransferred = args['bytesTransferred'];
          int totalBytes = args['totalBytes'];

          _onPayloadTransferUpdate?.call(
            endpointId: endpointId,
            payloadId: payloadId,
            payloadStatus: PayloadStatus.values[success],
            bytesTransferred: bytesTransferred,
            totalBytes: totalBytes,
          );
          break;
      }
      return null;
    });
  }

  OnConnctionInitiated _advertConnectionInitiated, _discoverConnectionInitiated;
  OnConnectionResult _advertConnectionResult, _discoverConnectionResult;
  OnDisconnected _advertDisconnected, _discoverDisconnected;

  OnEndpointFound _onEndpointFound;
  OnEndpointLost _onEndpointLost;

  OnPayloadReceived _onPayloadReceived;
  OnPayloadTransferUpdate _onPayloadTransferUpdate;

  static const MethodChannel _channel =
      const MethodChannel('nearby_connections');

  /// Convinience method
  ///
  /// retruns true/false based on location permissions.
  /// Discovery cannot be started with insufficient permission
  Future<bool> checkPermissions() async => await _channel.invokeMethod(
        'checkPermissions',
      );

  /// Convinience method
  ///
  /// Asks location permission
  Future<void> askPermission() async {
    await _channel.invokeMethod(
      'askPermissions',
    );
  }

  /// Start Advertising
  ///
  /// [userNickName] and [strategy] should not be null
  Future<bool> startAdvertising(
    String userNickName,
    Strategy strategy, {
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

  /// Stop Advertising
  ///
  /// This doesn't disconnect from any connected Endpoint
  ///
  /// For disconnection use
  /// [stopAllEndpoints] or [disconnectFromEndpoint]
  Future<void> stopAdvertising() async {
    await _channel.invokeMethod('stopAdvertising');
  }

  /// Start Discovery
  ///
  /// [userNickName] and [strategy] should not be null
  Future<bool> startDiscovery(
    String userNickName,
    Strategy strategy, {
    @required OnEndpointFound onEndpointFound,
    @required OnEndpointLost onEndpointLost,
  }) async {
    assert(userNickName != null && strategy != null);
    this._onEndpointFound = onEndpointFound;
    this._onEndpointLost = onEndpointLost;

    return await _channel.invokeMethod('startDiscovery', <String, dynamic>{
      'userNickName': userNickName,
      'strategy': strategy.index
    });
  }

  /// Stop Discovery
  ///
  /// This doesn't disconnect from any connected Endpoint
  ///
  /// It is reccomended to call this method
  /// once you have connected to an endPoint
  /// as it uses heavy radio operations
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

    return await _channel.invokeMethod(
      'requestConnection',
      <String, dynamic>{
        'userNickName': userNickName,
        'endpointId': endpointId,
      },
    );
  }

  /// Accept Connection
  ///
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
    return await _channel.invokeMethod(
      'rejectConnection',
      <String, dynamic>{
        'endpointId': endpointId,
      },
    );
  }

  /// Send bytes [Uint8List] payload to endpoint
  ///
  /// Convert String to Uint8List as follows
  ///
  /// ```dart
  /// String a = "hello";
  /// Uint8List bytes = Uint8List.fromList(a.codeUnits);
  /// ```
  Future<void> sendPayload(String endpointId, Uint8List bytes) async {
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
    return await _channel.invokeMethod(
      'sendFilePayload',
      <String, dynamic>{
        'endpointId': endpointId,
        'filePath': filePath,
      },
    );
  }
}

/// ConnectionInfo class
///
/// Its a parameter in [OnConnctionInitiated]
///
/// [endPointName] is userNickName of requester
///
/// [authenticationToken] can be used to check the connection security
/// it must be same on both devices
class ConnectionInfo {
  String endpointName, authenticationToken;
  bool isIncomingConnection;

  ConnectionInfo(
      this.endpointName, this.authenticationToken, this.isIncomingConnection);
}
//TODO remove errors on failure for smooth experience
//TODO expose only relevant parts as library
//TODO publish to pub.dartlang
