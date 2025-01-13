// contains enums only
// ignore_for_file: constant_identifier_names

/// **P2P_CLUSTER** - best for small payloads and multiplayer games
/// **P2P_STAR** - best for medium payloads, higher bandwidth than cluster
/// **P2P_POINT_TO_POINT** - single connection, very high bandwidth
enum Strategy {
  P2P_CLUSTER,
  P2P_STAR,
  P2P_POINT_TO_POINT,
}

/// Status codes for connection results
enum Status {
  SUCCESS,
  ERROR,
  UNKNOWN,
}

/// Status codes for payload transfers
enum PayloadStatus {
  NONE,
  SUCCESS,
  FAILURE,
  IN_PROGRESS,
  CANCELED,
}

/// Types of payloads that can be transferred
enum PayloadType {
  NONE,
  BYTES,
  FILE,
  STREAM,
}
