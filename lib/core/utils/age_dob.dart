/// Age (whole years) ↔ synthetic date of birth.
///
/// Formula: DOB = 1 January of (current calendar year − age).
/// Example: in 2026, age 65 → 1961-01-01.
///
/// Day and month are always 1 January. We do not invent a real birthday.
class AgeDob {
  AgeDob._();

  static const int minAge = 1;
  static const int maxAge = 120;

  static bool isValidAge(int age) => age >= minAge && age <= maxAge;

  /// Parses a whole-year age. Returns null for empty, non-integer, or out of range.
  static int? parseAge(String? raw) {
    if (raw == null) return null;
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;
    final age = int.tryParse(trimmed);
    if (age == null || !isValidAge(age)) return null;
    return age;
  }

  /// Hidden/internal DOB for [age]: 1 January of ([now].year − age).
  static DateTime? dateFromAge(int age, {DateTime? now}) {
    if (!isValidAge(age)) return null;
    final year = (now ?? DateTime.now()).year - age;
    return DateTime(year, 1, 1);
  }

  /// ISO `yyyy-MM-dd` for the API `dob` field. Always `…-01-01`.
  static String? isoFromAge(int age, {DateTime? now}) {
    final date = dateFromAge(age, now: now);
    if (date == null) return null;
    final y = date.year.toString().padLeft(4, '0');
    return '$y-01-01';
  }

  /// ISO DOB from a text field, or null if the age is missing/invalid.
  static String? isoFromInput(String? raw, {DateTime? now}) {
    final age = parseAge(raw);
    if (age == null) return null;
    return isoFromAge(age, now: now);
  }

  /// Whole years from a stored ISO DOB for display. Uses calendar age so
  /// existing (non-1-January) records stay accurate.
  static int? ageFromIso(String? iso, {DateTime? now}) {
    if (iso == null || iso.trim().isEmpty) return null;
    final parsed = DateTime.tryParse(iso.trim());
    if (parsed == null) return null;
    final today = now ?? DateTime.now();
    var age = today.year - parsed.year;
    if (today.month < parsed.month ||
        (today.month == parsed.month && today.day < parsed.day)) {
      age -= 1;
    }
    if (age < 0) return null;
    return age;
  }
}
