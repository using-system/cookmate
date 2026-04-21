import 'package:cookmate/features/recipe/domain/unit_system.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UnitSystem', () {
    test('defaultValue is metric', () {
      expect(UnitSystem.defaultValue, UnitSystem.metric);
    });

    test('toStorageValue returns enum name', () {
      expect(UnitSystem.metric.toStorageValue(), 'metric');
      expect(UnitSystem.imperial.toStorageValue(), 'imperial');
    });

    test('fromStorageValue returns matching enum value', () {
      expect(UnitSystem.fromStorageValue('metric'), UnitSystem.metric);
      expect(UnitSystem.fromStorageValue('imperial'), UnitSystem.imperial);
    });

    test('fromStorageValue returns default for null', () {
      expect(UnitSystem.fromStorageValue(null), UnitSystem.defaultValue);
    });

    test('fromStorageValue returns default for empty string', () {
      expect(UnitSystem.fromStorageValue(''), UnitSystem.defaultValue);
    });

    test('fromStorageValue returns default for unknown value', () {
      expect(UnitSystem.fromStorageValue('celsius'), UnitSystem.defaultValue);
    });

    test('toStorageValue and fromStorageValue roundtrip for all values', () {
      for (final v in UnitSystem.values) {
        expect(UnitSystem.fromStorageValue(v.toStorageValue()), v);
      }
    });
  });
}
