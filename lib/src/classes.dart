// contains custom classes
import 'dart:typed_data';

import 'package:nearby_connections/src/defs.dart';

/// Bytes may be null if [Payload.type] is not [PayloadType.BYTES] 
class Payload {
  int id;
  PayloadType type;
  Uint8List bytes;

  Payload({
    this.id,
    this.bytes,
    this.type = PayloadType.NONE,
  });
}

class PayloadTransferUpdate {
  int id, bytesTransferred, totalBytes;
  PayloadStatus status;

  PayloadTransferUpdate({
    this.id,
    this.bytesTransferred,
    this.totalBytes,
    this.status = PayloadStatus.NONE,
  });
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