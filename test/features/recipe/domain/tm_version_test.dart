import 'package:cookmate/features/recipe/domain/tm_version.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TmVersion', () {
    test('defaultValue is tm6', () {
      expect(TmVersion.defaultValue, TmVersion.tm6);
    });

    test('toStorageValue returns enum name', () {
      expect(TmVersion.tm5.toStorageValue(), 'tm5');
      expect(TmVersion.tm6.toStorageValue(), 'tm6');
      expect(TmVersion.tm7.toStorageValue(), 'tm7');
    });

    test('fromStorageValue returns matching enum value', () {
      expect(TmVersion.fromStorageValue('tm5'), TmVersion.tm5);
      expect(TmVersion.fromStorageValue('tm6'), TmVersion.tm6);
      expect(TmVersion.fromStorageValue('tm7'), TmVersion.tm7);
    });

    test('fromStorageValue returns default for null', () {
      expect(TmVersion.fromStorageValue(null), TmVersion.defaultValue);
    });

    test('fromStorageValue returns default for empty string', () {
      expect(TmVersion.fromStorageValue(''), TmVersion.defaultValue);
    });

    test('fromStorageValue returns default for unknown value', () {
      expect(TmVersion.fromStorageValue('tm99'), TmVersion.defaultValue);
    });

    test('toStorageValue and fromStorageValue roundtrip for all values', () {
      for (final v in TmVersion.values) {
        expect(TmVersion.fromStorageValue(v.toStorageValue()), v);
      }
    });
  });
}
