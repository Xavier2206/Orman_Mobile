import 'package:flutter_test/flutter_test.dart';
import 'package:orman/features/payments/models/payment_amount_policy.dart';

void main() {
  group('maximumRegistrableCents', () {
    test('uses confirmed saldo when nothing is under review', () {
      expect(
        PaymentAmountPolicy.maximumRegistrableCents(
          balance: 2500,
          pendingReviewAmount: 0,
        ),
        250000,
      );
    });

    test('subtracts the amount already under review', () {
      expect(
        PaymentAmountPolicy.maximumRegistrableCents(
          balance: 2500,
          pendingReviewAmount: 500,
        ),
        200000,
      );
    });

    test('never returns a negative maximum', () {
      expect(
        PaymentAmountPolicy.maximumRegistrableCents(
          balance: 500,
          pendingReviewAmount: 500,
        ),
        0,
      );
      expect(
        PaymentAmountPolicy.maximumRegistrableCents(
          balance: 500,
          pendingReviewAmount: 700,
        ),
        0,
      );
      expect(
        PaymentAmountPolicy.maximumRegistrableCents(
          balance: 500,
          pendingReviewAmount: double.infinity,
        ),
        0,
      );
    });
  });

  group('payment amount input', () {
    const maximumCents = 200000;

    test('allows partial payments up to the maximum in cents', () {
      for (final input in ['1', '500', '1999.99', '2000', '10,5', '10,50']) {
        expect(
          PaymentAmountPolicy.validateInput(
            input,
            maximumCents: maximumCents,
          ).isValid,
          isTrue,
          reason: input,
        );
      }
    });

    test('rejects amounts greater than the maximum', () {
      final result = PaymentAmountPolicy.validateInput(
        '2000.01',
        maximumCents: maximumCents,
      );

      expect(result.isValid, isFalse);
      expect(
        result.messageFor(maximumCents),
        'El monto supera el máximo que puedes registrar: Bs 2.000,00.',
      );
    });

    test('rejects any positive amount when the maximum is zero', () {
      final result = PaymentAmountPolicy.validateInput('1', maximumCents: 0);

      expect(result.isValid, isFalse);
      expect(
        result.messageFor(0),
        'El monto supera el máximo que puedes registrar: Bs 0,00.',
      );
    });

    test('handles required, zero, negative and decimal precision errors', () {
      expect(
        PaymentAmountPolicy.validateInput(
          '',
          maximumCents: maximumCents,
        ).messageFor(maximumCents),
        'Ingresa el monto pagado.',
      );
      for (final input in ['0', '-1']) {
        expect(
          PaymentAmountPolicy.validateInput(
            input,
            maximumCents: maximumCents,
          ).messageFor(maximumCents),
          'El monto debe ser mayor a Bs 0,00.',
          reason: input,
        );
      }
      expect(
        PaymentAmountPolicy.validateInput(
          '10.555',
          maximumCents: maximumCents,
        ).messageFor(maximumCents),
        'Ingresa como máximo 2 decimales.',
      );
    });

    test('rejects letters, NaN, infinity and mixed separators', () {
      for (final input in ['abc', 'NaN', 'Infinity', '10,5.00']) {
        expect(
          PaymentAmountPolicy.validateInput(
            input,
            maximumCents: maximumCents,
          ).isValid,
          isFalse,
          reason: input,
        );
      }
    });
  });
}
