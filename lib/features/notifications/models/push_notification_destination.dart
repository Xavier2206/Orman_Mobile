enum OrmanPushNotificationType {
  paymentConfirmed('PAGO_CONFIRMADO'),
  paymentRejected('PAGO_RECHAZADO'),
  installmentDueSoon('CUOTA_PROXIMA_VENCER'),
  installmentOverdue('CUOTA_VENCIDA');

  const OrmanPushNotificationType(this.value);

  final String value;

  static OrmanPushNotificationType? parse(String? value) {
    for (final type in values) {
      if (type.value == value) return type;
    }
    return null;
  }

  String get fallbackBody => switch (this) {
    paymentConfirmed => 'Tu pago fue confirmado. Toca para consultar la cuota.',
    paymentRejected =>
      'Tu pago requiere revisión. Toca para consultar la cuota.',
    installmentDueSoon => 'Tienes una cuota próxima a vencer.',
    installmentOverdue => 'Tienes una cuota vencida.',
  };
}

class PushNotificationDestination {
  const PushNotificationDestination({
    required this.installmentCode,
    required this.type,
    this.notificationCode,
    this.messageId,
  });

  final int installmentCode;
  final int? notificationCode;
  final OrmanPushNotificationType type;
  final String? messageId;

  String get deduplicationKey =>
      notificationCode?.toString() ??
      (messageId?.trim().isNotEmpty == true
          ? messageId!.trim()
          : '${type.value}:$installmentCode');

  Map<String, String> toData() => {
    'tipo': type.value,
    'codcuo': installmentCode.toString(),
    if (notificationCode != null) 'codnot': notificationCode.toString(),
    if (messageId?.trim().isNotEmpty == true) 'messageId': messageId!.trim(),
  };

  static PushNotificationDestination? fromData(
    Map<String, Object?> data, {
    String? messageId,
  }) {
    if (data.values.any((value) => value is! String)) return null;

    final strings = data.map((key, value) => MapEntry(key, value as String));
    final type = OrmanPushNotificationType.parse(strings['tipo']?.trim());
    final installmentCode = _positiveInteger(strings['codcuo']);
    if (type == null || installmentCode == null) return null;

    return PushNotificationDestination(
      installmentCode: installmentCode,
      notificationCode: _positiveInteger(strings['codnot']),
      type: type,
      messageId: strings['messageId'] ?? messageId,
    );
  }

  static int? _positiveInteger(String? value) {
    if (value == null || !RegExp(r'^[0-9]+$').hasMatch(value)) return null;
    final parsed = int.tryParse(value);
    return parsed != null && parsed > 0 ? parsed : null;
  }
}
