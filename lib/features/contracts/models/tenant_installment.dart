import '../../../core/network/json_readers.dart';

class TenantInstallment {
  const TenantInstallment({
    required this.code,
    required this.contractCode,
    required this.status,
    this.period,
    this.dueDate,
    this.amount,
    this.confirmedAmount,
    this.pendingReviewAmount,
    this.balance,
    this.dueSituation,
  });

  final int code;
  final int contractCode;
  final DateTime? period;
  final DateTime? dueDate;
  final double? amount;
  final double? confirmedAmount;
  final double? pendingReviewAmount;
  final double? balance;
  final String status;
  final String? dueSituation;

  factory TenantInstallment.fromJson(JsonMap json) {
    final code = jsonInt(json['codcuo']);
    final contractCode = jsonInt(json['codcon']);
    if (code == null || contractCode == null) {
      throw const FormatException('La cuota no incluye sus códigos.');
    }
    return TenantInstallment(
      code: code,
      contractCode: contractCode,
      period: jsonDate(json['periodo']),
      dueDate: jsonDate(json['fechaVencimiento']),
      amount: jsonDouble(json['monto']),
      confirmedAmount: jsonDouble(json['montoConfirmado']),
      pendingReviewAmount: jsonDouble(json['montoPendienteRevision']),
      balance: jsonDouble(json['saldo']),
      status: jsonString(json['estado']) ?? '',
      dueSituation: jsonString(json['situacionVencimiento']),
    );
  }
}
