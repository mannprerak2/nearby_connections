import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(PigeonOptions(
  dartOut: 'lib/src/messages.g.dart',
  javaOut: 'android/src/main/java/com/pkmnapps/nearby_connections/Messages.java',
  javaOptions: JavaOptions(
    package: 'com.pkmnapps.nearby_connections',
  ),
))
class ConnectionInfoMessage {
  ConnectionInfoMessage(this.endpointId, this.endpointName, this.authenticationToken, this.isIncomingConnection);

  String endpointId;
  String endpointName;
  String authenticationToken;
  bool isIncomingConnection;
}

class IdentifierMessage {
  IdentifierMessage(this.userNickname, this.strategy, this.serviceId);

  String userNickname;
  int strategy;
  String serviceId;
}

class PayloadMessage {
  PayloadMessage(this.endpointId, this.type, this.bytes, this.payloadId, this.filePath, this.uri);

  String endpointId;
  int type;
  Uint8List? bytes;
  int payloadId;
  String? filePath;
  String? uri;
}

class PayloadTransferUpdateMessage {
  PayloadTransferUpdateMessage(this.endpointId, this.payloadId, this.status, this.bytesTransferred, this.totalBytes);

  String endpointId;
  int payloadId;
  int status;
  int bytesTransferred;
  int totalBytes;
}

@HostApi()
abstract class NearbyApi {
  @async
  bool checkLocationPermission();
  @async
  bool askLocationPermission();
  @async
  bool checkExternalStoragePermission();
  @async
  bool checkBluetoothPermission();
  @async
  bool checkLocationEnabled();
  @async
  bool enableLocationServices();

  void askExternalStoragePermission();
  void askBluetoothPermission();
  void askLocationAndExternalStoragePermission();

  @async
  bool copyFileAndDeleteOriginal(String sourceUri, String destinationFilepath);
  @async
  bool startAdvertising(IdentifierMessage identifierMessage);

  @async
  void stopAdvertising();
  @async
  bool startDiscovery(IdentifierMessage identifierMessage);

  @async
  void stopDiscovery();

  @async
  void stopAllEndpoints();

  @async
  void disconnectFromEndpoint(String endpointId);

  @async
  bool requestConnection(String userNickName, String endpointId);

  @async
  bool acceptConnection(String endpointId);

  @async
  bool rejectConnection(String endpointId);

  @async
  void sendBytesPayload(String endpointId, Uint8List bytes);

  @async
  int sendFilePayload(String endpointId, String filePath);

  @async
  void cancelPayload(int payloadId);
}

@FlutterApi()
abstract class DiscoveryConnectionLifecycleApi {
  void onConnectionInitiated(ConnectionInfoMessage connectionInfoMessage);
  void onConnectionResult();
  void onDisconnected(String endpointId);
}

@FlutterApi()
abstract class AdvertisingConnectionLifecycleApi {
  void onConnectionInitiated(ConnectionInfoMessage connectionInfoMessage);
  void onConnectionResult();
  void onDisconnected(String endpointId);
}

@FlutterApi()
abstract class PayloadApi {
  void onPayloadReceived(String endpointId, PayloadMessage payloadMessage);
  void onPayloadTransferUpdate(String endpointId, PayloadTransferUpdateMessage payloadTransferUpdateMessage);
}

@FlutterApi()
abstract class EndpointDiscoveryApi {
  void onEndpointFound(String endpointId, String endpointName, String serviceId);
  void onEndpointLost(String endpointId);
}
