import 'dart:typed_data';

import 'package:gal/gal.dart';

abstract interface class QrGallerySaver {
  Future<void> save({required Uint8List bytes, required String name});
}

class GalQrGallerySaver implements QrGallerySaver {
  const GalQrGallerySaver();

  @override
  Future<void> save({required Uint8List bytes, required String name}) =>
      Gal.putImageBytes(bytes, album: 'ORMAN', name: name);
}

String qrGalleryFileName({
  required int installmentCode,
  required DateTime date,
}) {
  String two(int value) => value.toString().padLeft(2, '0');
  final datePart = '${date.year}${two(date.month)}${two(date.day)}';
  return 'ORMAN_QR_COBRO_${installmentCode}_$datePart';
}
