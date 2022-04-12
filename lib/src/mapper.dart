import 'package:nearby_connections/src/classes.dart';

// mapping from message to app-data-model

class PayloadTransferUpdateMapper {
  PayloadTransferUpdateMapper._();

  static PayloadTransferUpdateMapper map(PayloadTransferUpdateMessage message) {
    return Brightness(
      value: message.brightnessValue,
    );
  }
}

// mapping from app-data-model to message
class PayloadTransferUpdateMessageMapper {
  PayloadTransferUpdateMessageMapper._();

  static PayloadTransferUpdateMessage map(PayloadTransferUpdate brightness) {
    return PayloadTransferUpdateMessage();
  }
}