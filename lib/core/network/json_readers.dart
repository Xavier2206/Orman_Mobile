typedef JsonMap = Map<String, dynamic>;

JsonMap? jsonMap(Object? value) => value is Map
    ? value.map((key, entry) => MapEntry(key.toString(), entry))
    : null;

List<JsonMap> jsonMapList(Object? value) => value is List
    ? value.map(jsonMap).whereType<JsonMap>().toList(growable: false)
    : const [];

String? jsonString(Object? value) => value is String ? value : null;

int? jsonInt(Object? value) => value is int
    ? value
    : value is num
    ? value.toInt()
    : int.tryParse(value?.toString() ?? '');

double? jsonDouble(Object? value) =>
    value is num ? value.toDouble() : double.tryParse(value?.toString() ?? '');

DateTime? jsonDate(Object? value) =>
    value is String ? DateTime.tryParse(value) : null;
