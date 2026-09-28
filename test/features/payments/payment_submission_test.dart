import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orman/core/network/api_client.dart';
import 'package:orman/features/payments/data/payment_api.dart';
import 'package:orman/features/payments/models/payment_submission.dart';

import '../../support/fake_http_adapter.dart';
import '../../support/fake_portal_api.dart';

void main() {
  test('payment JSON matches PagoRequest without invented tenant fields', () {
    final submission = PaymentSubmission(
      amountCents: 50000,
      paymentDate: DateTime(2026, 9, 12),
      idempotencyKey: 'f30f8612-913c-442c-a451-635287e49203',
    );
    final body = submission.toJson();

    expect(body, {
      'monto': 500,
      'metodo': 'QR',
      'fechaPago': '2026-09-12T00:00:00',
      'idempotencyKey': 'f30f8612-913c-442c-a451-635287e49203',
    });
    expect(body.keys, isNot(contains('codper')));
    expect(body.keys, isNot(contains('propietaria')));
    expect(body.keys, isNot(contains('inquilino')));
  });

  test('partial amounts and 5 MiB proof limit are validated locally', () {
    final proof = PaymentProof(
      bytes: Uint8List.fromList([1, 2, 3]),
      fileName: 'comprobante.jpeg',
      contentType: 'image/jpeg',
    );
    expect(PaymentProofValidator.validate(proof), isNull);
    expect(
      PaymentProofValidator.validate(
        PaymentProof(
          bytes: Uint8List(0),
          fileName: 'comprobante.pdf',
          contentType: 'application/pdf',
        ),
      ),
      'Selecciona el comprobante del pago.',
    );
    expect(
      PaymentProofValidator.validate(
        PaymentProof(
          bytes: Uint8List(PaymentProofValidator.maxSizeInBytes + 1),
          fileName: 'comprobante.png',
          contentType: 'image/png',
        ),
      ),
      'El comprobante no puede superar 5 MiB.',
    );
    expect(
      PaymentProofValidator.validate(
        PaymentProof(
          bytes: Uint8List.fromList([1]),
          fileName: 'comprobante.pdf',
          contentType: 'application/pdf',
        ),
      ),
      'El comprobante debe ser una imagen PNG o JPG.',
    );
  });

  test(
    'payment uses authenticated multipart parts and expects review status',
    () async {
      RequestOptions? capturedOptions;
      var body = '';
      final dio = Dio(BaseOptions(baseUrl: 'https://orman.test/'));
      dio.httpClientAdapter = CallbackHttpAdapter.withRequestBody((
        options,
        stream,
      ) async {
        capturedOptions = options;
        final bytes = BytesBuilder();
        if (stream != null) await stream.forEach(bytes.add);
        body = String.fromCharCodes(bytes.takeBytes());
        return jsonResponse(paymentJson(), statusCode: 201);
      });
      final api = PaymentApi(ApiClient(dio));

      final response = await api.submitPayment(
        installmentCode: 88,
        submission: PaymentSubmission(
          amountCents: 50000,
          paymentDate: DateTime(2026, 9, 12),
          idempotencyKey: 'f30f8612-913c-442c-a451-635287e49203',
        ),
        proof: PaymentProof(
          bytes: Uint8List.fromList([0x89, 0x50, 0x4e, 0x47]),
          fileName: 'comprobante.png',
          contentType: 'image/png',
        ),
      );

      expect(response.status, 'PENDIENTE_REVISION');
      expect(response.installmentCode, 88);
      expect(capturedOptions!.method, 'POST');
      expect(capturedOptions!.path, 'api/v1/cuotas/88/pagos');
      expect(capturedOptions!.contentType, startsWith('multipart/form-data'));
      expect(body, contains('name="pago"; filename="pago.json"'));
      expect(body.toLowerCase(), contains('content-type: application/json'));
      expect(body, contains('"metodo":"QR"'));
      expect(body, contains('"fechaPago":"2026-09-12T00:00:00"'));
      expect(
        body,
        contains('"idempotencyKey":"f30f8612-913c-442c-a451-635287e49203"'),
      );
      expect(body, contains('name="comprobante"; filename="comprobante.png"'));
    },
  );

  test('QR response maps metadata from the backend', () async {
    final api = PaymentApi(createFakePortalApi());
    final qr = await api.getCurrentQr(88);

    expect(qr.code, 18);
    expect(qr.hasImage, isFalse);
    expect(qr.startDate, DateTime(2026, 9, 1));
    expect(qr.endDate, DateTime(2026, 9, 30));
  });
}
