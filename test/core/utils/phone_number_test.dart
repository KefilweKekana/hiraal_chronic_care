import 'package:flutter_test/flutter_test.dart';
import 'package:hiraal_chronic_care/core/utils/phone_number.dart';

void main() {
  group('PhoneNumber.normalize', () {
    test('local Somali 9-digit number gets 252 prefix, no plus', () {
      expect(PhoneNumber.normalize('636197117'), '252636197117');
      expect(PhoneNumber.normalize(' 636 197 117 '), '252636197117');
    });

    test('strips plus and leading zeros on Somali MSISDNs', () {
      expect(PhoneNumber.normalize('+252636197117'), '252636197117');
      expect(PhoneNumber.normalize('252636197117'), '252636197117');
      expect(PhoneNumber.normalize('0636197117'), '252636197117');
      expect(PhoneNumber.normalize('0634063505'), '252634063505');
      expect(PhoneNumber.normalize('252634063505'), '252634063505');
      expect(PhoneNumber.normalize('+2520636197117'), '252636197117');
    });

    test('leaves emails unchanged', () {
      expect(PhoneNumber.normalize('patient@hiraal.so'), 'patient@hiraal.so');
    });

    test('keeps non-Somali numbers with their selected country code', () {
      expect(
        PhoneNumber.normalize('+254712345678', defaultCountryCode: '+254'),
        '254712345678',
      );
    });
  });

  group('PhoneNumber.combine', () {
    test('dropdown + local digits does not double 252', () {
      expect(PhoneNumber.combine('+252', '636197117'), '252636197117');
      expect(PhoneNumber.combine('+252', '252636197117'), '252636197117');
      expect(PhoneNumber.combine('+252', '+252636197117'), '252636197117');
    });
  });
}
