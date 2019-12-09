import 'package:nanopacket/nanopacket.dart';
import '../example/make_data.dart';
import 'package:typed_data/typed_buffers.dart';

void doSome(Packet p) {
  print(p.payload);
}

void doChunk(Uint8Buffer ub) {
  print(ub);
}

void main() {
  try {
    var parser = Parser(0);
    parser.on('packet', doSome);
    var list = Uint8Buffer();
    list.addAll(tt);
    parser.parse(list);
  } catch (e) {
    print(e);
  }
  var h = Uint8Buffer();
  var p = Uint8Buffer();
  p.addAll(tt);
  var packet = Packet(h, p);
  var generator = Generator(packet, 60);
  generator.split(doChunk);
}
