import 'dart:typed_data';

import 'file_saver_stub.dart'
    if (dart.library.io) 'file_saver_io.dart' as saver;

class FileSaver {
  static Future<String> saveFile(String filename, Uint8List bytes) async {
    return saver.saveBytesLocally(filename, bytes);
  }
}
