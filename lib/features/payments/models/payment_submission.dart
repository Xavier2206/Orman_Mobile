import 'dart:typed_data';

import '../../../core/network/json_readers.dart';

class PaymentSubmission {
  const PaymentSubmission({
    required this.amountCents,
    required this.paymentDate,
    required this.idempotencyKey,
  });

  final int amountCents;
  final DateTime paymentDate;
  final String idempotencyKey;

  Map<String, Object> toJson() => {
    'monto': amountCents / 100,
    'metodo': 'QR',
    'fechaPago': _localDateTime(paymentDate),
    'idempotencyKey': idempotencyKey,
  };

  static String _localDateTime(DateTime date) {
    String two(int value) => value.toString().padLeft(2, '0');
    return '${date.year}-${two(date.month)}-${two(date.day)}T00:00:00';
  }
}

class PaymentProof {
  const PaymentProof({
    required this.bytes,
    required this.fileName,
    required this.contentType,
  });

  final Uint8List bytes;
  final String fileName;
  final String contentType;
  int get sizeInBytes => bytes.lengthInBytes;
}

class PaymentProofValidator {
  static const maxSizeInBytes = 5 * 1024 * 1024;

  static String? validate(PaymentProof? proof) {
    if (proof == null || proof.bytes.isEmpty) {
      return 'Selecciona el comprobante del pago.';
    }
    if (proof.sizeInBytes > maxSizeInBytes) {
      return 'El comprobante no puede superar 5 MiB.';
    }
    final extension = proof.fileName.split('.').last.toLowerCase();
    final expectedType = switch (extension) {
      'png' => 'image/png',
      'jpg' || 'jpeg' => 'image/jpeg',
      _ => null,
    };
    if (expectedType == null ||
        proof.contentType.toLowerCase() != expectedType) {
      return 'El comprobante debe ser una imagen PNG o JPG.';
    }
    return null;
  }
}

class PaymentSubmissionResult {
  const PaymentSubmissionResult({
    required this.code,
    required this.installmentCode,
    required this.amount,
    required this.method,
    required this.status,
    this.qrCode,
    this.paymentDate,
  });

  final int code;
  final int installmentCode;
  final int? qrCode;
  final double? amount;
  final String? method;
  final DateTime? paymentDate;
  final String status;

  factory PaymentSubmissionResult.fromJson(Object? value) {
    final json = jsonMap(value);
    final code = jsonInt(json?['codpag']);
    final installmentCode = jsonInt(json?['codcuo']);
    if (json == null || code == null || installmentCode == null) {
      throw const FormatException('La respuesta del pago no es válida.');
    }
    return PaymentSubmissionResult(
      code: code,
      installmentCode: installmentCode,
      qrCode: jsonInt(json['codqr']),
      amount: jsonDouble(json['monto']),
      method: jsonString(json['metodo']),
      paymentDate: jsonDate(json['fechaPago']),
      status: jsonString(json['estado']) ?? '',
    );
  }
}
