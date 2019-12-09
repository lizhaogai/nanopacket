import 'package:nanopacket/src/packet.dart';
import 'package:nanopacket/src/constants.dart';
import 'package:typed_data/typed_buffers.dart';

class Generator {
  Packet packet;
  num chunkSize;

  Generator(Packet packet, num chunkSize) {
    this.packet = packet;
    this.chunkSize = chunkSize == 0 || chunkSize == null ? 60 : chunkSize;
  }

  Uint8Buffer generate() {
    var ub = Uint8Buffer();
    ub.addAll(packet.header);
    int len = packet.length;
    while (true) {
      if (len > LENGTH_MASK) {
        var _len = len & LENGTH_MASK;
        _len = _len | LENGTH_FIN_MASK;
        ub.add(_len);
        len = len >> 7;
      } else {
        ub.add(len);
        break;
      }
    }
    ub.addAll(packet.payload);
    return ub;
  }

  void split(Function func) {
    split_size(chunkSize, func);
  }

  void split_size(num chunkSize, Function func) {
    if (chunkSize <= 0) {
      return;
    }
    var data = generate();
    for (var i = 0; i < (data.length / chunkSize); i++) {
      int end =
          (i + 1) * chunkSize > data.length ? data.length : (i + 1) * chunkSize;
      var sub = data.sublist(i * chunkSize, end);
      var ub = Uint8Buffer();
      ub.addAll(sub);
      func(ub);
    }
  }
}
