// contains custom classes
import 'dart:typed_data';

import 'package:nearby_connections/src/defs.dart';

/// Custom exception for Nearby Connection errors
class NearbyConnectionsException implements Exception {
  final String message;
  final dynamic error;

  NearbyConnectionsException(this.message, [this.error]);

  @override
  String toString() => 'NearbyConnectionsException: $message${error != null ? ' ($error)' : ''}';
}

/// Connection information for endpoints
class ConnectionInfo {
  final String endpointName;
  final String authenticationToken;
  final bool isIncomingConnection;

  ConnectionInfo(this.endpointName, this.authenticationToken, this.isIncomingConnection) {
    if (endpointName.isEmpty) {
      throw NearbyConnectionsException('Endpoint name cannot be empty');
    }
    if (authenticationToken.isEmpty) {
      throw NearbyConnectionsException('Authentication token cannot be empty');
    }
  }
}

/// Payload class for data transfer
///
/// Bytes may be null if [type] is not [PayloadType.BYTES]
/// File may be null if [type] is not [PayloadType.FILE]
class Payload {
  final PayloadType type;
  final Uint8List? bytes;
  final int id;
  @Deprecated('Use uri instead, Only available on Android 10 and below.')
  final String? filePath;
  final String? uri;

  Payload({
    required this.type,
    this.bytes,
    required this.id,
    this.filePath,
    this.uri,
  }) {
    if (id < 0) {
      throw NearbyConnectionsException('Payload ID cannot be negative');
    }
    if (type == PayloadType.BYTES && bytes == null) {
      throw NearbyConnectionsException('Bytes payload cannot be empty');
    }
    if (type == PayloadType.FILE && (filePath == null && uri == null)) {
      throw NearbyConnectionsException('File payload must have either filePath or uri');
    }
  }
}

/// Update information for payload transfers
class PayloadTransferUpdate {
  final int id;
  final PayloadStatus status;
  final int bytesTransferred;
  final int totalBytes;

  PayloadTransferUpdate({
    required this.id,
    required this.status,
    required this.bytesTransferred,
    required this.totalBytes,
  }) {
    if (id < 0) {
      throw NearbyConnectionsException('Payload ID cannot be negative');
    }
    if (bytesTransferred < 0) {
      throw NearbyConnectionsException('Bytes transferred cannot be negative');
    }
    if (totalBytes < 0) {
      throw NearbyConnectionsException('Total bytes cannot be negative');
    }
    if (bytesTransferred > totalBytes) {
      throw NearbyConnectionsException('Bytes transferred cannot be greater than total bytes');
    }
  }
}

// Callback type definitions
typedef OnConnectionInitiated = void Function(String endpointId, ConnectionInfo connectionInfo);
typedef OnConnectionResult = void Function(String endpointId, Status status);
typedef OnDisconnected = void Function(String endpointId);
typedef OnEndpointFound = void Function(String endpointId, String endpointName, String serviceId);
typedef OnEndpointLost = void Function(String endpointId);
typedef OnPayloadReceived = void Function(String endpointId, Payload payload);
typedef OnPayloadTransferUpdate = void Function(String endpointId, PayloadTransferUpdate update);
