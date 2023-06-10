// contains enums and typedefs

import 'package:nearby_connections/src/classes.dart';

/// **P2P_CLUSTER** - best for small payloads and multiplayer games
///
/// **P2P_STAR** - best for medium payloads, higher bandwidth than cluster
///
/// **P2P_POINT_TO_POINT** - single connection, very high bandwidth
enum Strategy { P2P_CLUSTER, P2P_STAR, P2P_POINT_TO_POINT }

enum Status { CONNECTED, REJECTED, ERROR }

enum PayloadStatus { NONE, SUCCESS, FAILURE, IN_PROGRESS, CANCELED }

enum PayloadType { NONE, BYTES, FILE, STREAM }

//
//
//
// Advertising lifecycle callbacks
//
typedef OnConnectionInitiated = void Function(
    String endpointId, ConnectionInfo connectionInfo);
typedef OnConnectionResult = void Function(String endpointId, Status status);
typedef OnDisconnected = void Function(String endpointId);

//
//
//
// Discovery lifecycle callbacks
//
typedef OnEndpointFound = void Function(
    String endpointId, String endpointName, String serviceId);
typedef OnEndpointLost = void Function(String? endpointId);

//
//
//
/// For Bytes, this contains the bytes data
///
/// For File, this marks the start of transfer
///
/// Uint8List bytes may be null, if [type] is not [PayloadType.BYTES]
typedef OnPayloadReceived = void Function(String endpointId, Payload payload);

/// Called only once for Bytes and repeatedly for File until transfer is complete
typedef OnPayloadTransferUpdate = void Function(
    String endpointId, PayloadTransferUpdate payloadTransferUpdate);
