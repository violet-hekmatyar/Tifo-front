String? jsonString(Object? value) {
  if (value is! String || value.trim().isEmpty) return null;
  return value.trim();
}

int? jsonInt(Object? value) {
  if (value is int) return value;
  if (value is num && value.isFinite) return value.toInt();
  return null;
}

double? jsonDouble(Object? value) {
  if (value is num && value.isFinite) return value.toDouble();
  return null;
}

DateTime? jsonIsoDateTime(Object? value) {
  final text = jsonString(value);
  return text == null ? null : DateTime.tryParse(text);
}

Map<Object?, Object?>? jsonMap(Object? value) => value is Map ? value : null;

List<T> jsonList<T>(Object? value, T? Function(Object? item) decode) {
  if (value is! List) return const [];
  return value.map(decode).whereType<T>().toList(growable: false);
}
