import 'package:events2/events2.dart';
import 'package:nanopacket_dart/src/packet.dart';
import 'package:nanopacket_dart/src/constants.dart';
import 'package:typed_data/typed_buffers.dart';

class Parser extends EventEmitter {
  num header_size;
  List<String> states;
  String state;
  num pos;
  num counter;
  Uint8Buffer list;
  Packet packet;
  num error;

  Parser(num header_size) {
    this.header_size = header_size;
    states = ['stateHeader', 'stateLength', 'statePayload', 'statePacket'];
    state = 'stateHeader';
    reset();
  }

  void reset() {
    state = 'stateHeader';
    packet = Packet(null, null);
    error = 0;
    pos = 0;
    list = Uint8Buffer();
  }

  num parse(Uint8Buffer buffer) {
    if (error != 0) {
      reset();
    }
    list.addAll(buffer);
    var result = true;
    while (result && list.isNotEmpty) {
      if ((packet.length != -1 || list.isNotEmpty) &&
          error == 0 &&
          result &&
          state == states[0]) {
        result = stateHeader();
      }
      if ((packet.length != -1 || list.isNotEmpty) &&
          error == 0 &&
          result &&
          state == states[1]) {
        result = stateLength();
      }
      if ((packet.length != -1 || list.isNotEmpty) &&
          error == 0 &&
          result &&
          state == states[2]) {
        result = statePayload();
      }
      if ((packet.length != -1 || list.isNotEmpty) &&
          error == 0 &&
          result &&
          state == states[3]) {
        result = statePacket();
      }
    }
    return list.length;
  }

  void statesNext() {
    num index = states.indexOf(state);
    state = states[(index + 1) % states.length];
  }

  bool parseVarByteNum() {
    num bytes = 0;
    num mul = 1;
    num length = 0;
    var result = true;
    int current;
    int padding = pos != 0 ? pos : 0;

    while (bytes < 5) {
      current = list.first;
      bytes++;
      length += mul * (current & LENGTH_MASK);
      mul *= 0x80;

      var sub = list.sublist(1, list.length);
      list = Uint8Buffer();
      list.addAll(sub);

      if ((current & LENGTH_FIN_MASK) == 0) break;
      if (list.length <= bytes) {
        result = false;
        break;
      }
    }

    if (padding != 0) {
      pos = pos + bytes;
    }

    if (result) {
      packet.length = length;
//      var sub = list.sublist(bytes, list.length);
//      list = Uint8Buffer();
//      list.addAll(sub);
      statesNext();
      return true;
    }

    return false;
  }

  bool stateHeader() {
    if (header_size == 0) {
      statesNext();
      return true;
    }
    if (header_size > list.length) {
      return false;
    }
    packet.header = list.sublist(0, header_size);

    var sub = list.sublist(header_size, list.length);
    list = Uint8Buffer();
    list.addAll(sub);
    statesNext();
    return true;
  }

  bool stateLength() {
    return parseVarByteNum();
  }

  bool statePayload() {
    if (packet.length == 0 || list.length >= packet.length) {
      pos = 0;
      var sub = list.sublist(0, packet.length);
      var pList = Uint8Buffer();
      pList.addAll(sub);
      packet.payload = pList;
      statesNext();
      return true;
    }
    return false;
  }

  bool statePacket() {
    var sub = list.sublist(packet.length, list.length);
    list = Uint8Buffer();
    list.addAll(sub);
    onPacket();

    packet = Packet(null, null);
    pos = 0;
    error = 0;
    statesNext();

    return true;
  }

  void onPacket() {
    emit('packet', packet);
  }
}
