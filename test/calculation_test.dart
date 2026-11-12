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

  group('Calru planning calculations', () {
    test('calculates estimated tax and after-tax profit', () {
      final entry = Entry(
        label: 'Tax example',
        revenue: money('1000'),
        cogs: money('400'),
        expenses: money('100'),
        taxRate: money('10'),
        createdAt: DateTime.utc(2026, 1, 1),
      );

      expect(entry.estimatedTax.toStringAsFixed(2), '50.00');
      expect(entry.netAfterTax.toStringAsFixed(2), '450.00');
    });

    test('calculates break-even revenue from contribution margin', () {
      final result = calculateBreakEvenRevenue(
        revenue: money('1000'),
        cogs: money('400'),
        expenses: money('300'),
      );

      expect(result?.toStringAsFixed(2), '500.00');
    });

    test('returns no break-even when contribution is zero or negative', () {
      expect(
        calculateBreakEvenRevenue(
          revenue: money('100'),
          cogs: money('100'),
          expenses: money('20'),
        ),
        isNull,
      );
    });


    test('round-trips tax rate and timestamps through JSON', () {
      final entry = Entry(
        label: 'Backup',
        revenue: money('250.00'),
        cogs: money('100.00'),
        expenses: money('25.00'),
        taxRate: money('12.5'),
        createdAt: DateTime.utc(2026, 11, 12, 12),
      );

      final restored = Entry.fromJson(entry.toJson());
      expect(restored.taxRate.toString(), '12.5');
      expect(restored.createdAt, entry.createdAt);
      expect(restored.netAfterTax.toStringAsFixed(2), '109.38');
    });

    test('loads legacy records without a tax rate', () {
      final restored = Entry.fromJson({
        'label': 'Legacy',
        'revenue': '100',
        'cogs': '20',
        'expenses': '10',
        'createdAt': '2026-01-01T00:00:00.000Z',
      });

      expect(restored.taxRate, Decimal.zero);
      expect(restored.netAfterTax.toString(), '70');
    });

    test('validates grouped monetary input instead of silently accepting it', () {
      expect(isValidMoneyInput('12,345.67'), isTrue);
      expect(isValidMoneyInput('12,34.67'), isFalse);
      expect(isValidMoneyInput('10.999'), isFalse);
    });
  });

}
