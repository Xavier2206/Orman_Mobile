import '../../../core/network/json_readers.dart';

class QrCollection {
  const QrCollection({
    required this.hasImage,
    this.code,
    this.startDate,
    this.endDate,
    this.status,
    this.fileName,
    this.contentType,
    this.registeredAt,
  });

  final int? code;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? status;
  final bool hasImage;
  final String? fileName;
  final String? contentType;
  final DateTime? registeredAt;

  factory QrCollection.fromJson(Object? value) {
    final json = jsonMap(value);
    if (json == null) {
      throw const FormatException('La respuesta del QR no es válida.');
    }
    return QrCollection(
      code: jsonInt(json['codqr']),
      startDate: jsonDate(json['fechaInicio']),
      endDate: jsonDate(json['fechaFin']),
      status: jsonString(json['estado']),
      hasImage: json['tieneImagen'] == true,
      fileName: jsonString(json['nombreArchivo']),
      contentType: jsonString(json['tipoContenido']),
      registeredAt: jsonDate(json['fechaRegistro']),
    );
  }
}
