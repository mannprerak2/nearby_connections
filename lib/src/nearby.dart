import 'dart:async';
import 'dart:typed_data';

import 'package:nearby_connections/src/classes.dart';
import 'package:nearby_connections/src/defs.dart';

import 'messages.g.dart'; // import pigeon generated file for ease of method channel calls

/// The NearbyConnection class
///
/// Only one instance is maintained
/// even on calling Nearby() multiple times
///
/// All methods are asynchronous.
class Nearby {
  final NearbyApi _api = NearbyApi();

  final _EndpointDiscoveryApiCallback _endpointDiscoveryApiCallback =
      _EndpointDiscoveryApiCallback();
  final _PayloadApiCallback _payloadApiCallback = _PayloadApiCallback();
  final _AdvertisingConnectionLifecycleApiCallback _advertisingConnectionLifecycleApiCallback =
      _AdvertisingConnectionLifecycleApiCallback();
  final _DiscoveryConnectionLifecycleApiCallback _discoveryConnectionLifecycleApiCallback =
      _DiscoveryConnectionLifecycleApiCallback();

  //Singleton pattern for maintaining only 1 instance of this class
  static Nearby? _instance;

  factory Nearby() {
    if (_instance == null) {
      _instance = Nearby._();
    }
    return _instance!;
  }

  Nearby._() {
    EndpointDiscoveryApi.setup(_endpointDiscoveryApiCallback);
    PayloadApi.setup(_payloadApiCallback);
    AdvertisingConnectionLifecycleApi.setup(_advertisingConnectionLifecycleApiCallback);
    DiscoveryConnectionLifecycleApi.setup(_discoveryConnectionLifecycleApiCallback);
  }

  /// convenience method
  ///
  /// returns true/false based on location permissions.
  /// Discovery cannot be started with insufficient permission
  Future<bool> checkLocationPermission() async =>
      await _api.checkLocationPermission();

  /// convenience method
  ///
  /// Asks location permission
  Future<bool> askLocationPermission() async =>
      await _api.askLocationPermission();

  /// convenience method
  ///
  /// returns true/false based on external storage permissions.
  Future<bool> checkExternalStoragePermission() async =>
      await _api.checkExternalStoragePermission();

  /// convenience method
  ///
  /// returns true/false based on bluetooth permissions.
  Future<bool> checkBluetoothPermission() async =>
      await _api.checkBluetoothPermission();

  /// convenience method
  ///
  /// Checks if Location/GPS is enabled
  ///
  /// If Location isn't enabled, devices may disconnect often.
  /// Some devices may immediately disconnect
  Future<bool> checkLocationEnabled() async =>
      await _api.checkLocationEnabled();

  /// convenience method
  ///
  /// directs user to Location Settings, so they can turn on their Location/GPS
  Future<bool> enableLocationServices() async =>
      await _api.enableLocationServices();

  /// convenience method
  ///
  /// Asks external storage permission, required for file
  void askExternalStoragePermission() =>
      _api.askExternalStoragePermission();

  /// convenience method
  ///
  /// Asks bluetooth permissions, required for apps running on Android 12 and higher
  void askBluetoothPermission() =>
      _api.askBluetoothPermission();

  /// convenience method
  ///
  /// Use this instead of calling both [askLocationPermission()] and [askExternalStoragePermission()]
  void askLocationAndExternalStoragePermission() =>
      _api.askLocationAndExternalStoragePermission();

  /// convenience method
  ///
  /// Copy file from [sourceUri] to [destinationFilepath] and delete original.
  Future<bool> copyFileAndDeleteOriginal(
          String sourceUri, String destinationFilepath) async =>
      await _api.copyFileAndDeleteOriginal(sourceUri, destinationFilepath);

  /// Start Advertising, Discoverers would be able to discover this advertiser.
  ///
  /// [serviceId] is a unique identifier for your app, its recommended to use your app package name only, it cannot be null
  /// [userNickName] and [strategy] should not be null
  Future<bool> startAdvertising(
    String userNickName,
    Strategy strategy, {
    required OnConnectionInitiated onConnectionInitiated,
    required OnConnectionResult onConnectionResult,
    required OnDisconnected onDisconnected,
    String serviceId = "com.pkmnapps.nearby_connections",
  }) async {
    _advertisingConnectionLifecycleApiCallback._advertConnectionInitiated = onConnectionInitiated;
    _advertisingConnectionLifecycleApiCallback._advertConnectionResult = onConnectionResult;
    _advertisingConnectionLifecycleApiCallback._advertDisconnected = onDisconnected;

    return await _api.startAdvertising(IdentifierMessage(userNickname: userNickName, strategy: strategy.index, serviceId: serviceId));
  }

  /// Stop Advertising
  ///
  /// This doesn't disconnect from any connected Endpoint
  ///
  /// For disconnection use
  /// [stopAllEndpoints] or [disconnectFromEndpoint]
  Future<void> stopAdvertising() async {
    await _api.stopAdvertising();
  }

  /// Start Discovery, You will now be able to discover the advertisers now.
  ///
  /// [serviceId] is a unique identifier for your app, its recommended to use your app package name only, it cannot be null
  /// [userNickName] and [strategy] should not be null
  Future<bool> startDiscovery(
    String userNickName,
    Strategy strategy, {
    required OnEndpointFound onEndpointFound,
    required OnEndpointLost onEndpointLost,
    String serviceId = "com.pkmnapps.nearby_connections",
  }) async {
    _endpointDiscoveryApiCallback._onEndpointFound = onEndpointFound;
    _endpointDiscoveryApiCallback._onEndpointLost = onEndpointLost;

    return await _api.startDiscovery(IdentifierMessage(userNickname: userNickName, strategy: strategy.index, serviceId: serviceId));
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
    await _api.stopDiscovery();
  }

  /// Stop All Endpoints
  ///
  /// Disconnects all connections,
  /// this will call the onDisconnected method on callbacks of
  /// all connected endPoints
  Future<void> stopAllEndpoints() async {
    await _api.stopAllEndpoints();
  }

  /// Disconnect from Endpoints
  ///
  /// Disconnects the  connections to given endPointId
  /// this will call the onDisconnected method on callbacks of
  /// connected endPoint
  Future<void> disconnectFromEndpoint(String endpointId) async {
    await _api.disconnectFromEndpoint(endpointId);
  }

  /// Request Connection
  ///
  /// Call this method when Discoverer calls the
  /// [OnEndpointFound] method
  ///
  /// This will call the [OnConnectionInitiated] method on
  /// both the endPoint and this
  Future<bool> requestConnection(
    String userNickName,
    String endpointId, {
    required OnConnectionInitiated onConnectionInitiated,
    required OnConnectionResult onConnectionResult,
    required OnDisconnected onDisconnected,
  }) async {
    _discoveryConnectionLifecycleApiCallback._discoverConnectionInitiated = onConnectionInitiated;
    _discoveryConnectionLifecycleApiCallback._discoverConnectionResult = onConnectionResult;
    _discoveryConnectionLifecycleApiCallback._discoverDisconnected = onDisconnected;

    return await _api.requestConnection(userNickName, endpointId);
  }

  /// Needs be called by both discoverer and advertiser
  /// to connect
  ///
  /// Call this in [OnConnectionInitiated]
  /// to accept an incoming connection
  ///
  /// [OnConnectionResult] is called on both
  /// only if both of them accept the connection
  Future<bool> acceptConnection(
    String endpointId, {
    required OnPayloadReceived onPayLoadRecieved,
    OnPayloadTransferUpdate? onPayloadTransferUpdate,
  }) async {
    _payloadApiCallback._onPayloadReceived = onPayLoadRecieved;
    _payloadApiCallback._onPayloadTransferUpdate = onPayloadTransferUpdate;

    return await _api.acceptConnection(endpointId);
  }

  /// Reject Connection
  ///
  /// To be called by both discoverer and advertiser
  ///
  /// Call this in [OnConnectionInitiated]
  /// to reject an incoming connection
  ///
  /// [OnConnectionResult] is called on both
  /// even if one of them rejects the connection
  Future<bool> rejectConnection(String endpointId) async {
    return await _api.rejectConnection(endpointId);
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
    return await _api.sendBytesPayload(endpointId, bytes);
  }

  /// Returns the payloadID as soon as file transfer has begun
  ///
  /// File is received in DOWNLOADS_DIRECTORY and is given a generic name
  /// without extension
  /// You must also send a bytes payload to send the filename and extension
  /// so that receiver can rename the file accordingly
  /// Send the payloadID and filename to receiver as bytes payload
  Future<int> sendFilePayload(String endpointId, String filePath) async {
    return await _api.sendFilePayload(endpointId, filePath);
  }

  /// Use it to cancel/stop a payload transfer
  Future<void> cancelPayload(int payloadId) async {
    return await _api.cancelPayload(payloadId);
  }
}

class _EndpointDiscoveryApiCallback implements EndpointDiscoveryApi {
  OnEndpointFound? _onEndpointFound;
  OnEndpointLost? _onEndpointLost;

  @override
  void onEndpointFound(String endpointId, String endpointName, String serviceId) {
    // TODO: implement onEndpointFound
    _onEndpointFound?.call(endpointId, endpointName, serviceId);
  }

  @override
  void onEndpointLost(String endpointId) {
    // TODO: implement onEndpointLost
    _onEndpointLost?.call(endpointId);
  }
}

class _PayloadApiCallback implements PayloadApi {
  //for receiving payload
  OnPayloadReceived? _onPayloadReceived;
  OnPayloadTransferUpdate? _onPayloadTransferUpdate;

  @override
  void onPayloadReceived(String endpointId, PayloadMessage payloadMessage) {
    Payload payload = Payload(
      type: PayloadType.values[payloadMessage.type],
      bytes: payloadMessage.bytes,
      id: payloadMessage.payloadId,
      filePath: payloadMessage.filePath,
      uri: payloadMessage.uri,
    );

    _onPayloadReceived?.call(endpointId, payload);
  }

  @override
  void onPayloadTransferUpdate(String endpointId, PayloadTransferUpdateMessage payloadTransferUpdateMessage) {
    PayloadTransferUpdate payloadTransferUpdate = PayloadTransferUpdate(
      id: payloadTransferUpdateMessage.payloadId,
      status: PayloadStatus.values[payloadTransferUpdateMessage.status],
      bytesTransferred: payloadTransferUpdateMessage.bytesTransferred,
      totalBytes: payloadTransferUpdateMessage.totalBytes,
    );

    _onPayloadTransferUpdate?.call(endpointId, payloadTransferUpdate);
  }
}

class _AdvertisingConnectionLifecycleApiCallback implements AdvertisingConnectionLifecycleApi {
  //for advertisers
  OnConnectionInitiated? _advertConnectionInitiated;
  OnConnectionResult? _advertConnectionResult;
  OnDisconnected? _advertDisconnected;

  @override
  void onConnectionInitiated(ConnectionInfoMessage connectionInfoMessage) {
    _advertConnectionInitiated?.call(
        connectionInfoMessage.endpointId,
        ConnectionInfo(
            connectionInfoMessage.endpointName, connectionInfoMessage.authenticationToken, connectionInfoMessage.isIncomingConnection));
  }

  @override
  void onConnectionResult(String endpointId, int statusCode) {
    _advertConnectionResult?.call(endpointId, Status.values[statusCode]);
  }

  @override
  void onDisconnected(String endpointId) {
    _advertDisconnected?.call(endpointId);
  }
}

class _DiscoveryConnectionLifecycleApiCallback implements DiscoveryConnectionLifecycleApi {
  //for advertisers
  OnConnectionInitiated? _discoverConnectionInitiated;
  OnConnectionResult? _discoverConnectionResult;
  OnDisconnected? _discoverDisconnected;

  @override
  void onConnectionInitiated(ConnectionInfoMessage connectionInfoMessage) {
    _discoverConnectionInitiated?.call(
        connectionInfoMessage.endpointId,
        ConnectionInfo(
            connectionInfoMessage.endpointName, connectionInfoMessage.authenticationToken, connectionInfoMessage.isIncomingConnection));
  }

  @override
  void onConnectionResult(String endpointId, int statusCode) {
    _discoverConnectionResult?.call(endpointId, Status.values[statusCode]);
  }

  @override
  void onDisconnected(String endpointId) {
    _discoverDisconnected?.call(endpointId);
  }
}