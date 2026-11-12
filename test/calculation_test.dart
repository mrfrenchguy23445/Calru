import 'package:calru/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Calru money parsing', () {
    test('parses decimal amounts without binary floating point', () {
      final result = money('0.10') + money('0.20');
      expect(result.toStringAsFixed(2), '0.30');
    });

    test('parses comma grouped amounts', () {
      expect(money('12,345.67').toString(), '12345.67');
    });

    test('empty input becomes zero', () {
      expect(money('').toString(), '0');
    });
  });

  group('Calru financial records', () {
    test('calculates gross and net profit', () {
      final entry = Entry(
        label: 'Example',
        revenue: money('1000.00'),
        cogs: money('425.50'),
        expenses: money('74.50'),
        createdAt: DateTime.utc(2026, 1, 1),
      );
      expect(entry.grossProfit.toString(), '574.5');
      expect(entry.netProfit.toString(), '500');
      expect(entry.margin.toStringAsFixed(2), '57.45');
    });

    test('handles zero revenue margin safely', () {
      final entry = Entry(
        label: 'Zero',
        revenue: money('0'),
        cogs: money('0'),
        expenses: money('0'),
        createdAt: DateTime.utc(2026, 1, 1),
      );
      expect(entry.margin.toString(), '0');
    });
  });
}
