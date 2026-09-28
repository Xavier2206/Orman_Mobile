import '../../../core/network/json_readers.dart';

class TenantContract {
  const TenantContract({
    required this.code,
    required this.status,
    this.startDate,
    this.endDate,
    this.rescissionDate,
    this.rescissionReason,
    this.monthlyAmount,
    this.currency,
    this.deposit,
    this.propertyCode,
    this.propertyName,
    this.unitCode,
    this.unitName,
  });

  final int code;
  final String status;
  final DateTime? startDate;
  final DateTime? endDate;
  final DateTime? rescissionDate;
  final String? rescissionReason;
  final double? monthlyAmount;
  final String? currency;
  final double? deposit;
  final int? propertyCode;
  final String? propertyName;
  final int? unitCode;
  final String? unitName;

  factory TenantContract.fromJson(JsonMap json) {
    final code = jsonInt(json['codcon']);
    if (code == null) {
      throw const FormatException('El contrato no incluye codcon.');
    }
    return TenantContract(
      code: code,
      status: jsonString(json['estado']) ?? '',
      startDate: jsonDate(json['fechaInicio']),
      endDate: jsonDate(json['fechaFin']),
      rescissionDate: jsonDate(json['fechaRescision']),
      rescissionReason: jsonString(json['motivoRescision']),
      monthlyAmount: jsonDouble(json['montoMensual']),
      currency: jsonString(json['moneda']),
      deposit: jsonDouble(json['garantia']),
      propertyCode: jsonInt(json['codprop']),
      propertyName: jsonString(json['nombrePropiedad']),
      unitCode: jsonInt(json['coduni']),
      unitName: jsonString(json['nombreUnidad']),
    );
  }
}

class TenantContractPage {
  const TenantContractPage({
    required this.content,
    required this.page,
    required this.size,
    required this.totalElements,
    required this.totalPages,
    required this.first,
    required this.last,
  });

  final List<TenantContract> content;
  final int page;
  final int size;
  final int totalElements;
  final int totalPages;
  final bool first;
  final bool last;

  factory TenantContractPage.fromJson(Object? value) {
    final json = jsonMap(value);
    if (json == null || json['content'] is! List) {
      throw const FormatException('La respuesta de contratos no es paginada.');
    }
    return TenantContractPage(
      content: jsonMapList(
        json['content'],
      ).map(TenantContract.fromJson).toList(growable: false),
      page: jsonInt(json['page']) ?? 0,
      size: jsonInt(json['size']) ?? 20,
      totalElements: jsonInt(json['totalElements']) ?? 0,
      totalPages: jsonInt(json['totalPages']) ?? 0,
      first: json['first'] == true,
      last: json['last'] == true,
    );
  }
}
