import 'dart:typed_data';
import 'package:printing/printing.dart';

Future<String> saveBytesLocally(String filename, Uint8List bytes) async {
  await Printing.sharePdf(
    bytes: bytes,
    filename: filename,
  );
  return 'File berhasil diunduh ($filename)';
}
