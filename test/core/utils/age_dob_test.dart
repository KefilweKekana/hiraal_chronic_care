import 'package:flutter_test/flutter_test.dart';
import 'package:hiraal_chronic_care/core/utils/age_dob.dart';

void main() {
  final now = DateTime(2026, 9, 7);

  group('AgeDob.isoFromAge', () {
    test('age 65 in 2026 is 1 January 1961', () {
      expect(AgeDob.isoFromAge(65, now: now), '1961-01-01');
    });

    test('age 1 is 1 January of previous year', () {
      expect(AgeDob.isoFromAge(1, now: now), '2025-01-01');
    });

    test('age 120 is 1 January of year − 120', () {
      expect(AgeDob.isoFromAge(120, now: now), '1906-01-01');
    });

    test('rejects ages outside 1–120', () {
      expect(AgeDob.isoFromAge(0, now: now), isNull);
      expect(AgeDob.isoFromAge(121, now: now), isNull);
      expect(AgeDob.isoFromAge(-3, now: now), isNull);
    });
  });

  group('AgeDob.parseAge / isoFromInput', () {
    test('accepts trimmed integer years', () {
      expect(AgeDob.parseAge(' 65 '), 65);
      expect(AgeDob.isoFromInput('65', now: now), '1961-01-01');
    });

    test('rejects empty, non-integer, and out-of-range input', () {
      expect(AgeDob.parseAge(''), isNull);
      expect(AgeDob.parseAge('   '), isNull);
      expect(AgeDob.parseAge('65.5'), isNull);
      expect(AgeDob.parseAge('abc'), isNull);
      expect(AgeDob.parseAge('0'), isNull);
      expect(AgeDob.parseAge('121'), isNull);
      expect(AgeDob.isoFromInput('', now: now), isNull);
    });
  });

  group('AgeDob.ageFromIso', () {
    test('synthetic 1 January DOB round-trips to the entered age', () {
      expect(AgeDob.ageFromIso('1961-01-01', now: now), 65);
    });

    test('stored mid-year DOB uses calendar age, not an invented birthday', () {
      expect(AgeDob.ageFromIso('1961-12-31', now: now), 64);
      expect(AgeDob.ageFromIso('1961-09-07', now: now), 65);
    });
  });
}
