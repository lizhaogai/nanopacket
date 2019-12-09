import 'package:typed_data/typed_buffers.dart';

class Packet {
  Uint8Buffer header;
  Uint8Buffer payload;
  num length;

  Packet(Uint8Buffer header, Uint8Buffer payload) {
    this.header = header;
    this.payload = payload;
    length = payload != null ? this.payload.length : -1;
  }
}
