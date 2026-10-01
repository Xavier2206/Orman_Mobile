import 'package:flutter_test/flutter_test.dart';
import 'package:orman/core/network/json_readers.dart';
import 'package:orman/core/utils/formatters.dart';
import 'package:orman/features/notifications/models/tenant_notification.dart';
import 'package:orman/features/payments/models/payment_submission.dart';

void main() {
  group('timestamp presentation', () {
    final expectedInstant = DateTime.utc(2026, 9, 30, 17, 47, 48);
    final boliviaLocal = DateTime(2026, 9, 30, 13, 47, 48);

    for (final timestamp in [
      '2026-09-30T13:47:48-04:00',
      '2026-09-30T17:47:48Z',
    ]) {
      test('shows $timestamp in device local time', () {
        final parsed = jsonDate(timestamp);
        expect(parsed, expectedInstant);
        expect(parsed!.isUtc, isTrue);

        var conversionCount = 0;
        final displayed = Formatters.dateTime(
          parsed,
          localize: (instant) {
            conversionCount++;
            expect(instant, expectedInstant);
            return boliviaLocal;
          },
        );

        expect(displayed, '30/09/2026 · 13:47');
        expect(displayed, isNot(contains('17:47')));
        expect(conversionCount, 1);
      });
    }

    test('notification and payment timestamps retain the backend instant', () {
      final notification = TenantNotification.fromJson({
        'codnot': 1,
        'titulo': 'Pago confirmado',
        'mensaje': 'El pago fue confirmado.',
        'fechaCreacion': '2026-09-30T13:47:48-04:00',
        'leida': false,
      });
      final payment = PaymentSubmissionResult.fromJson({
        'codpag': 8,
        'codcuo': 4,
        'fechaPago': '2026-09-30T17:47:48Z',
        'estado': 'CONFIRMADO',
      });

      expect(notification.createdAt, expectedInstant);
      expect(payment.paymentDate, expectedInstant);
      expect(
        Formatters.dateTime(
          notification.createdAt,
          localize: (_) => boliviaLocal,
        ),
        '30/09/2026 · 13:47',
      );
      expect(
        Formatters.dateTime(payment.paymentDate, localize: (_) => boliviaLocal),
        '30/09/2026 · 13:47',
      );
    });
  });

  test('date-only values do not undergo timezone conversion', () {
    final dateOnly = jsonDate('2026-09-30');

    expect(dateOnly, DateTime(2026, 9, 30));
    expect(dateOnly!.isUtc, isFalse);
    expect(Formatters.date(dateOnly), '30/09/2026');
  });

  test('invalid or absent dates remain safe', () {
    expect(jsonDate(null), isNull);
    expect(jsonDate(42), isNull);
    expect(jsonDate('not-a-date'), isNull);
    expect(Formatters.dateTime(null), '—');
  });
}
