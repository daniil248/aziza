/// Picks the localized value from `{ru, kk, en}` payload with fallback chain.
///
/// Order: requested → ru → first non-empty → empty string.
String pickI18n(Map<String, dynamic>? map, String locale) {
  if (map == null) return '';
  final v = map[locale];
  if (v is String && v.isNotEmpty) return v;
  final ru = map['ru'];
  if (ru is String && ru.isNotEmpty) return ru;
  for (final entry in map.values) {
    if (entry is String && entry.isNotEmpty) return entry;
  }
  return '';
}
