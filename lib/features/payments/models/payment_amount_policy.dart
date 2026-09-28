import '../../../core/utils/formatters.dart';

enum PaymentAmountIssue {
  required,
  invalid,
  tooManyDecimals,
  nonPositive,
  exceedsMaximum,
}

class PaymentAmountValidation {
  const PaymentAmountValidation.valid(this.amountCents) : issue = null;

  const PaymentAmountValidation.invalid(this.issue) : amountCents = null;

  final int? amountCents;
  final PaymentAmountIssue? issue;

  bool get isValid => amountCents != null;

  String? messageFor(int maximumCents) => switch (issue) {
    null => null,
    PaymentAmountIssue.required => 'Ingresa el monto pagado.',
    PaymentAmountIssue.invalid => 'Ingresa un monto válido.',
    PaymentAmountIssue.tooManyDecimals => 'Ingresa como máximo 2 decimales.',
    PaymentAmountIssue.nonPositive => 'El monto debe ser mayor a Bs 0,00.',
    PaymentAmountIssue.exceedsMaximum =>
      'El monto supera el máximo que puedes registrar: '
          '${Formatters.currencyFromCents(maximumCents)}.',
  };
}

abstract final class PaymentAmountPolicy {
  static int maximumRegistrableCents({
    required double? balance,
    required double? pendingReviewAmount,
  }) {
    if (balance == null || !balance.isFinite) return 0;
    if (pendingReviewAmount != null && !pendingReviewAmount.isFinite) return 0;
    final balanceCents = _toCents(balance);
    final pendingCents = _toCents(pendingReviewAmount);
    final maximum = balanceCents - pendingCents;
    return maximum > 0 ? maximum : 0;
  }

  static PaymentAmountValidation validateInput(
    String? rawValue, {
    required int maximumCents,
  }) {
    final value = rawValue?.trim() ?? '';
    if (value.isEmpty) {
      return const PaymentAmountValidation.invalid(PaymentAmountIssue.required);
    }
    if (RegExp(r'^-?\d+[.,]\d{3,}$').hasMatch(value)) {
      return const PaymentAmountValidation.invalid(
        PaymentAmountIssue.tooManyDecimals,
      );
    }
    if (!RegExp(r'^-?\d+(?:[.,]\d{1,2})?$').hasMatch(value)) {
      return const PaymentAmountValidation.invalid(PaymentAmountIssue.invalid);
    }

    final negative = value.startsWith('-');
    final unsignedValue = negative ? value.substring(1) : value;
    final parts = unsignedValue.split(RegExp(r'[.,]'));
    final whole = int.tryParse(parts.first);
    if (whole == null) {
      return const PaymentAmountValidation.invalid(PaymentAmountIssue.invalid);
    }
    final decimals = parts.length == 1
        ? 0
        : int.parse(parts.last.padRight(2, '0'));
    final amountCents = whole * 100 + decimals;
    if (negative || amountCents <= 0) {
      return const PaymentAmountValidation.invalid(
        PaymentAmountIssue.nonPositive,
      );
    }
    if (amountCents > maximumCents) {
      return const PaymentAmountValidation.invalid(
        PaymentAmountIssue.exceedsMaximum,
      );
    }
    return PaymentAmountValidation.valid(amountCents);
  }

  static int _toCents(double? amount) {
    if (amount == null || amount <= 0) return 0;
    return (amount * 100).round();
  }
}
