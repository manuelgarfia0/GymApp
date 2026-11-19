import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/core/utils/weight_converter.dart';

void main() {
  group('WeightConverter', () {
    test('fromCode normalizes lb/lbs and defaults to kg', () {
      expect(WeightUnit.fromCode('lb'), WeightUnit.lb);
      expect(WeightUnit.fromCode('LBS'), WeightUnit.lb);
      expect(WeightUnit.fromCode('kg'), WeightUnit.kg);
      expect(WeightUnit.fromCode(null), WeightUnit.kg);
      expect(WeightUnit.fromCode('unknown'), WeightUnit.kg);
    });

    test('converts between kg and lb accurately', () {
      final lbs = WeightConverter.fromKg(100.0, WeightUnit.lb);
      expect(lbs, closeTo(220.46226, 0.001));

      final backToKg = WeightConverter.toKg(lbs, WeightUnit.lb);
      expect(backToKg, closeTo(100.0, 0.001));

      expect(WeightConverter.fromKg(82.5, WeightUnit.kg), 82.5);
      expect(WeightConverter.toKg(82.5, WeightUnit.kg), 82.5);
    });

    test('formats input and parses commas cleanly back to canonical kg', () {
      expect(WeightConverter.formatInputFromKg(60.0, WeightUnit.kg), '60');
      expect(WeightConverter.formatInputFromKg(62.5, WeightUnit.kg), '62.5');
      expect(WeightConverter.formatInputFromKg(100.0, WeightUnit.lb), '220.5');

      expect(
        WeightConverter.parseInputToKg('220,462262185', WeightUnit.lb),
        closeTo(100.0, 0.001),
      );
      expect(WeightConverter.parseInputToKg('75,5', WeightUnit.kg), 75.5);
      expect(WeightConverter.parseInputToKg('  ', WeightUnit.kg), isNull);
    });

    test('formats compact and full volume in selected unit', () {
      expect(WeightConverter.formatVolume(1000, WeightUnit.kg), '1000 kg');
      expect(WeightConverter.formatVolume(1000, WeightUnit.lb), '2205 lb');
      expect(
        WeightConverter.formatCompactVolume(2500, WeightUnit.kg),
        '2.5k kg',
      );
      expect(WeightConverter.formatCompactVolume(800, WeightUnit.kg), '800 kg');
    });
  });
}
