import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';

import '../../../core/network/api_client.dart';
import '../models/payment_submission.dart';
import '../models/qr_collection.dart';

class PaymentApi {
  const PaymentApi(this._http);

  final ApiClient _http;

  Future<QrCollection> getCurrentQr(int installmentCode) async =>
      QrCollection.fromJson(
        await _http.getJson('api/v1/cuotas/$installmentCode/qr-cobro'),
      );

  Future<Uint8List> getCurrentQrImage(int installmentCode) =>
      _http.getBytes('api/v1/cuotas/$installmentCode/qr-cobro/imagen');

  Future<PaymentSubmissionResult> submitPayment({
    required int installmentCode,
    required PaymentSubmission submission,
    required PaymentProof proof,
  }) async {
    final validation = PaymentProofValidator.validate(proof);
    if (validation != null) throw ArgumentError(validation);

    final body = FormData.fromMap({
      'pago': MultipartFile.fromString(
        jsonEncode(submission.toJson()),
        filename: 'pago.json',
        contentType: MediaType('application', 'json'),
      ),
      'comprobante': MultipartFile.fromBytes(
        proof.bytes,
        filename: proof.fileName,
        contentType: MediaType.parse(proof.contentType),
      ),
    });
    return PaymentSubmissionResult.fromJson(
      await _http.postMultipart(
        'api/v1/cuotas/$installmentCode/pagos',
        data: body,
      ),
    );
  }
}
