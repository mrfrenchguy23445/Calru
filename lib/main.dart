import 'dart:convert';
import 'dart:io';

import 'package:decimal/decimal.dart';
import 'package:file_picker/file_picker.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const CalruApp());
}

const ink = Color(0xFF0A0D12);
const panel = Color(0xFF111821);
const panel2 = Color(0xFF17222E);
const accent = Color(0xFF63B8F5);
const green = Color(0xFF50D6A0);
const muted = Color(0xFF8B9AAA);

class CalruApp extends StatelessWidget {
  const CalruApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Calru',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: ink,
          colorScheme: const ColorScheme.dark(
            primary: accent,
            surface: panel,
            secondary: green,
          ),
          useMaterial3: true,
          fontFamily: 'Arial',
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: panel2,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withValues(alpha: .06)),
            ),
          ),
        ),
        home: const HomePage(),
      );
}

final _moneyPattern = RegExp(r'^-?(?:(?:\d{1,3}(?:,\d{3})+|\d+)(?:\.\d{1,2})?|\.\d{1,2})$');

bool isValidMoneyInput(String value) {
  final cleaned = value.trim();
  return cleaned.isEmpty || _moneyPattern.hasMatch(cleaned);
}

Decimal money(String value) {
  final cleaned = value.trim().replaceAll(',', '');
  if (cleaned.isEmpty || !isValidMoneyInput(value)) {
    return Decimal.zero;
  }
  return Decimal.tryParse(cleaned) ?? Decimal.zero;
}

String amount(Decimal value) => value.toStringAsFixed(2);

Decimal? calculateBreakEvenRevenue({
  required Decimal revenue,
  required Decimal cogs,
  required Decimal expenses,
}) {
  final contribution = revenue - cogs;
  if (revenue <= Decimal.zero || contribution <= Decimal.zero) {
    return null;
  }
  return (expenses * revenue / contribution)
      .toDecimal(scaleOnInfinitePrecision: 2);
}

class Entry {
  Entry({
    required this.label,
    required this.revenue,
    required this.cogs,
    required this.expenses,
    required this.createdAt,
    Decimal? taxRate,
  }) : taxRate = taxRate ?? Decimal.zero;

  final String label;
  final Decimal revenue;
  final Decimal cogs;
  final Decimal expenses;
  final Decimal taxRate;
  final DateTime createdAt;

  Decimal get grossProfit => revenue - cogs;
  Decimal get netProfit => grossProfit - expenses;
  Decimal get estimatedTax => netProfit <= Decimal.zero || taxRate <= Decimal.zero
      ? Decimal.zero
      : (netProfit * taxRate / Decimal.fromInt(100))
          .toDecimal(scaleOnInfinitePrecision: 2);
  Decimal get netAfterTax => netProfit - estimatedTax;
  Decimal get margin => revenue == Decimal.zero
      ? Decimal.zero
      : (grossProfit / revenue * Decimal.fromInt(100).toRational())
          .toDecimal(scaleOnInfinitePrecision: 2);

  Map<String, dynamic> toJson() => {
        'label': label,
        'revenue': revenue.toString(),
        'cogs': cogs.toString(),
        'expenses': expenses.toString(),
        'taxRate': taxRate.toString(),
        'createdAt': createdAt.toIso8601String(),
      };

  factory Entry.fromJson(Map<String, dynamic> json) => Entry(
        label: json['label'] as String? ?? 'Untitled',
        revenue: money(json['revenue']?.toString() ?? '0'),
        cogs: money(json['cogs']?.toString() ?? '0'),
        expenses: money(json['expenses']?.toString() ?? '0'),
        taxRate: money(json['taxRate']?.toString() ?? '0'),
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      );
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int page = 0;
  String currency = 'USD';
  List<Entry> entries = [];
  bool loaded = false;
  String historyQuery = '';

  @override
  void initState() {
    super.initState();
    loadEntries();
  }

  Future<void> loadEntries() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('calru.entries');
    if (raw != null) {
      try {
        entries = (jsonDecode(raw) as List)
            .map((item) => Entry.fromJson(Map<String, dynamic>.from(item as Map)))
            .toList();
      } catch (_) {
        entries = [];
      }
    }
    currency = prefs.getString('calru.currency') ?? 'USD';
    if (mounted) {
      setState(() => loaded = true);
    }
  }

  Future<void> saveEntries() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('calru.entries', jsonEncode(entries.map((e) => e.toJson()).toList()));
    await prefs.setString('calru.currency', currency);
  }

  Decimal get totalRevenue =>
      entries.fold(Decimal.zero, (sum, item) => sum + item.revenue);
  Decimal get totalCogs => entries.fold(Decimal.zero, (sum, item) => sum + item.cogs);
  Decimal get totalExpenses =>
      entries.fold(Decimal.zero, (sum, item) => sum + item.expenses);
  Decimal get totalTax =>
      entries.fold(Decimal.zero, (sum, item) => sum + item.estimatedTax);
  Decimal get grossProfit => totalRevenue - totalCogs;
  Decimal get netProfit => grossProfit - totalExpenses;
  Decimal get netProfitAfterTax => netProfit - totalTax;
  String get symbol => switch (currency) {
        'USD' => '\$',
        'EUR' => '€',
        'GBP' => '£',
        'INR' => '₹',
        'LKR' => 'Rs ',
        'SGD' => 'S\$',
        'AUD' => 'A\$',
        'CAD' => 'C\$',
        _ => '$currency ',
      };

  Future<void> addEntry(Entry entry) async {
    setState(() => entries.insert(0, entry));
    await saveEntries();
  }

  Future<void> editEntry(Entry entry) async {
    final name = TextEditingController(text: entry.label);
    final revenue = TextEditingController(text: entry.revenue.toString());
    final cogs = TextEditingController(text: entry.cogs.toString());
    final expenses = TextEditingController(text: entry.expenses.toString());
    final tax = TextEditingController(text: entry.taxRate.toString());
    String? error;
    final edited = await showDialog<Entry>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, refresh) => AlertDialog(
          title: const Text('Edit financial record'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: name, decoration: const InputDecoration(labelText: 'Record name')),
                TextField(controller: revenue, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Revenue')),
                TextField(controller: cogs, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Cost of goods sold')),
                TextField(controller: expenses, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Other expenses')),
                TextField(controller: tax, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Tax rate (%)')),
                if (error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(error!, style: const TextStyle(color: Color(0xFFE18A8A))),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
            FilledButton(
              onPressed: () {
                final values = [revenue.text, cogs.text, expenses.text, tax.text];
                if (!values.every(isValidMoneyInput) ||
                    money(revenue.text) <= Decimal.zero ||
                    money(cogs.text) < Decimal.zero ||
                    money(expenses.text) < Decimal.zero ||
                    money(tax.text) < Decimal.zero ||
                    money(tax.text) > Decimal.fromInt(100)) {
                  refresh(() => error = 'Enter valid amounts and a tax rate from 0 to 100%.');
                  return;
                }
                Navigator.pop(
                  dialogContext,
                  Entry(
                    label: name.text.trim().isEmpty ? 'Untitled' : name.text.trim(),
                    revenue: money(revenue.text),
                    cogs: money(cogs.text),
                    expenses: money(expenses.text),
                    taxRate: money(tax.text),
                    createdAt: entry.createdAt,
                  ),
                );
              },
              child: const Text('Save changes'),
            ),
          ],
        ),
      ),
    );
    name.dispose();
    revenue.dispose();
    cogs.dispose();
    expenses.dispose();
    tax.dispose();
    if (edited == null) return;
    if (!mounted) {
      return;
    }
    final index = entries.indexOf(entry);
    if (index < 0) {
      return;
    }
    setState(() => entries[index] = edited);
    await saveEntries();
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Record updated.')));
  }

  Future<void> deleteEntry(Entry entry) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete this record?'),
        content: Text('“${entry.label}” will be permanently removed from this device.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
          FilledButton.tonal(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed != true) return;
    if (!mounted) {
      return;
    }
    setState(() => entries.remove(entry));
    await saveEntries();
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Record deleted.')));
  }

  Future<void> exportData({required bool csv}) async {
    final fileName = csv ? 'calru-records.csv' : 'calru-backup.json';
    final content = csv
        ? <String>[
            'name,revenue,cogs,expenses,gross_profit,net_profit,gross_margin,tax_rate,estimated_tax,net_after_tax,created_at',
            ...entries.map((entry) => [
                  entry.label,
                  entry.revenue,
                  entry.cogs,
                  entry.expenses,
                  entry.grossProfit,
                  entry.netProfit,
                  entry.margin,
                  entry.taxRate,
                  entry.estimatedTax,
                  entry.netAfterTax,
                  entry.createdAt.toIso8601String(),
                ].map((value) {
                  final raw = value.toString();
                  final safe = RegExp(r'^[=+@-]').hasMatch(raw) ? "'$raw" : raw;
                  return '"${safe.replaceAll('"', '""')}"';
                }).join(',')),
          ].join('\n')
        : const JsonEncoder.withIndent('  ').convert({
            'format': 'calru-backup',
            'version': 1,
            'currency': currency,
            'exportedAt': DateTime.now().toUtc().toIso8601String(),
            'records': entries.map((entry) => entry.toJson()).toList(),
          });
    try {
      final path = await FilePicker.saveFile(
        dialogTitle: csv ? 'Export Calru records' : 'Back up Calru data',
        fileName: fileName,
        mimeType: csv ? 'text/csv' : 'application/json',
        bytes: Uint8List.fromList(utf8.encode(content)),
      );
      if (path == null) {
        return;
      }
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Exported to $path')));
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Export failed: $error')));
    }
  }

  Future<void> importBackup() async {
    try {
      final selection = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      if (selection.isEmpty) {
        return;
      }
      final file = selection.single;
      final bytes = await file.readAsBytes();
      final decoded = jsonDecode(utf8.decode(bytes));
      final backup = decoded is Map ? Map<String, dynamic>.from(decoded) : null;
      final rawRecords = backup?['records'] ?? decoded;
      if (rawRecords is! List) {
        throw const FormatException('This is not a Calru records backup.');
      }
      final imported = rawRecords.map((item) {
        final record = Map<String, dynamic>.from(item as Map);
        for (final key in ['revenue', 'cogs', 'expenses', 'taxRate']) {
          if (!isValidMoneyInput(record[key]?.toString() ?? '0')) {
            throw FormatException('Invalid $key value in backup.');
          }
        }
        if (money(record['revenue']?.toString() ?? '0') <= Decimal.zero ||
            money(record['cogs']?.toString() ?? '0') < Decimal.zero ||
            money(record['expenses']?.toString() ?? '0') < Decimal.zero ||
            money(record['taxRate']?.toString() ?? '0') < Decimal.zero ||
            money(record['taxRate']?.toString() ?? '0') > Decimal.fromInt(100)) {
          throw const FormatException('Backup contains out-of-range financial values.');
        }
        if (DateTime.tryParse(record['createdAt']?.toString() ?? '') == null) {
          throw const FormatException('A record has an invalid creation date.');
        }
        return Entry.fromJson(record);
      }).toList();
      if (!mounted) {
        return;
      }
      final choice = await showDialog<String>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Import backup'),
          content: Text('${imported.length} records found. Choose how to import them.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext, 'cancel'), child: const Text('Cancel')),
            TextButton(onPressed: () => Navigator.pop(dialogContext, 'merge'), child: const Text('Merge')),
            FilledButton(onPressed: () => Navigator.pop(dialogContext, 'replace'), child: const Text('Replace all')),
          ],
        ),
      );
      if (choice == null || choice == 'cancel') return;
      if (!mounted) {
        return;
      }
      setState(() {
        if (choice == 'replace') {
          entries = imported;
        } else {
          final existing = entries.map((entry) => '${entry.label}|${entry.createdAt.toIso8601String()}').toSet();
          entries = [
            ...imported.where((entry) => !existing.contains('${entry.label}|${entry.createdAt.toIso8601String()}')),
            ...entries,
          ];
        }
        final restoredCurrency = backup?['currency'];
        if (restoredCurrency is String &&
            ['USD', 'EUR', 'GBP', 'INR', 'LKR', 'SGD', 'AUD', 'CAD'].contains(restoredCurrency)) {
          currency = restoredCurrency;
        }
      });
      await saveEntries();
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Imported ${imported.length} records.')));
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Import failed: $error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!loaded) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final pages = [
      dashboard(),
      CalculatorPage(currencySymbol: symbol, onSave: addEntry),
      ScreenshotPage(currencySymbol: symbol, onSave: addEntry),
      history(),
    ];
    return LayoutBuilder(builder: (context, constraints) {
      final wide = constraints.maxWidth >= 850;
      return Scaffold(
        body: Row(
          children: [
            if (wide) NavigationRail(
              backgroundColor: const Color(0xFF0D131B),
              selectedIndex: page,
              onDestinationSelected: (value) => setState(() => page = value),
              labelType: NavigationRailLabelType.all,
              destinations: const [
                NavigationRailDestination(icon: Icon(Icons.grid_view_rounded), label: Text('Overview')),
                NavigationRailDestination(icon: Icon(Icons.calculate_outlined), label: Text('Calculator')),
                NavigationRailDestination(icon: Icon(Icons.document_scanner_outlined), label: Text('Screenshotter')),
                NavigationRailDestination(icon: Icon(Icons.receipt_long_outlined), label: Text('History')),
              ],
            ),
            Expanded(child: pages[page]),
          ],
        ),
        bottomNavigationBar: wide ? null : NavigationBar(
          selectedIndex: page,
          onDestinationSelected: (value) => setState(() => page = value),
          destinations: const [
            NavigationDestination(icon: Icon(Icons.grid_view_rounded), label: 'Overview'),
            NavigationDestination(icon: Icon(Icons.calculate_outlined), label: 'Calculate'),
            NavigationDestination(icon: Icon(Icons.document_scanner_outlined), label: 'Capture'),
            NavigationDestination(icon: Icon(Icons.receipt_long_outlined), label: 'History'),
          ],
        ),
      );
    });
  }

  Widget shell(String title, String subtitle, Widget child) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1180),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Container(
                    width: 42, height: 42,
                    decoration: BoxDecoration(color: accent.withValues(alpha: .13), borderRadius: BorderRadius.circular(13)),
                    child: const Icon(Icons.query_stats_rounded, color: accent),
                  ),
                  const SizedBox(width: 12),
                  const Text('CALRU', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2.2, fontSize: 17)),
                  const Spacer(),
                  Text(currency, style: const TextStyle(color: muted, fontWeight: FontWeight.w600)),
                  const SizedBox(width: 8),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.tune_rounded, color: muted),
                    tooltip: 'Change display currency label (does not convert amounts)',
                    onSelected: (value) async {
                      if (value == 'export_csv') {
                        await exportData(csv: true);
                        return;
                      }
                      if (value == 'export_json') {
                        await exportData(csv: false);
                        return;
                      }
                      if (value == 'import_json') {
                        await importBackup();
                        return;
                      }
                      setState(() => currency = value);
                      await saveEntries();
                    },
                    itemBuilder: (_) => [
                      ...['USD', 'EUR', 'GBP', 'INR', 'LKR', 'SGD', 'AUD', 'CAD']
                          .map((value) => PopupMenuItem(value: value, child: Text(value))),
                      const PopupMenuDivider(),
                      const PopupMenuItem(value: 'export_csv', child: Text('Export CSV')),
                      const PopupMenuItem(value: 'export_json', child: Text('Back up as JSON')),
                      const PopupMenuItem(value: 'import_json', child: Text('Restore JSON backup')),
                    ],
                  ),
                ]),
                const SizedBox(height: 34),
                Text(title, style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800, letterSpacing: -.8)),
                const SizedBox(height: 6),
                Text(subtitle, style: const TextStyle(color: muted, fontSize: 14)),
                const SizedBox(height: 26),
                child,
              ]),
            ),
          ),
        ),
      );

  Widget dashboard() => shell('Financial overview', 'A clear picture of your revenue and profitability.', Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      GridView.count(
        crossAxisCount: MediaQuery.sizeOf(context).width > 900 ? 4 : MediaQuery.sizeOf(context).width > 560 ? 2 : 1,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.85,
        children: [
          MetricCard(title: 'Total revenue', value: '$symbol${amount(totalRevenue)}', icon: Icons.south_west_rounded, color: accent),
          MetricCard(title: 'Gross profit', value: '$symbol${amount(grossProfit)}', icon: Icons.account_balance_wallet_outlined, color: green),
          MetricCard(title: 'Gross margin', value: totalRevenue == Decimal.zero ? '—' : '${(grossProfit / totalRevenue * Decimal.fromInt(100).toRational()).toDecimal(scaleOnInfinitePrecision: 2).toStringAsFixed(2)}%', icon: Icons.donut_large_rounded, color: const Color(0xFFB59BFF)),
          MetricCard(title: 'Net profit', value: '$symbol${amount(netProfit)}', icon: Icons.trending_up_rounded, color: green),
          MetricCard(title: 'After estimated tax', value: '$symbol${amount(netProfitAfterTax)}', icon: Icons.account_balance_outlined, color: const Color(0xFFB59BFF)),
        ],
      ),
      const SizedBox(height: 18),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(color: panel, borderRadius: BorderRadius.circular(18), border: Border.all(color: Colors.white.withValues(alpha: .06))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Profit breakdown', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 20),
          BreakdownRow(label: 'Revenue', value: totalRevenue, symbol: symbol, color: accent),
          BreakdownRow(label: 'Cost of goods sold', value: totalCogs, symbol: symbol, color: const Color(0xFFF0B66D), negative: true),
          BreakdownRow(label: 'Gross profit', value: grossProfit, symbol: symbol, color: green, strong: true),
          BreakdownRow(label: 'Operating expenses', value: totalExpenses, symbol: symbol, color: const Color(0xFFE18A8A), negative: true),
          BreakdownRow(label: 'Estimated tax', value: totalTax, symbol: symbol, color: const Color(0xFFE18A8A), negative: true),
          const Divider(height: 28, color: Color(0xFF293542)),
          BreakdownRow(label: 'Net profit before tax', value: netProfit, symbol: symbol, color: green, strong: true),
          BreakdownRow(label: 'Net profit after estimated tax', value: netProfitAfterTax, symbol: symbol, color: const Color(0xFFB59BFF), strong: true),
        ]),
      ),
      const SizedBox(height: 18),
      Row(children: [
        const Expanded(child: Text('Recent activity', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16))),
        TextButton(onPressed: () => setState(() => page = 3), child: const Text('View history')),
      ]),
      if (entries.isEmpty) const EmptyState(text: 'No financial records yet. Add a calculation to start tracking.'),
      ...entries.take(4).map((entry) => EntryTile(entry: entry, symbol: symbol, onEdit: () => editEntry(entry), onDelete: () => deleteEntry(entry))),
    ],
  ));

  Widget history() {
    final filtered = entries
        .where((entry) => entry.label.toLowerCase().contains(historyQuery.toLowerCase()))
        .toList();
    return shell('Your records', 'Saved calculations, newest first.', Column(children: [
      TextField(
        decoration: const InputDecoration(
          hintText: 'Search records',
          prefixIcon: Icon(Icons.search_rounded),
        ),
        onChanged: (value) => setState(() => historyQuery = value),
      ),
      const SizedBox(height: 14),
      if (entries.isEmpty) const EmptyState(text: 'Your saved calculations will appear here.'),
      if (entries.isNotEmpty && filtered.isEmpty)
        const EmptyState(text: 'No records match your search.'),
      ...filtered.map((entry) => EntryTile(
            entry: entry,
            symbol: symbol,
            onEdit: () => editEntry(entry),
            onDelete: () => deleteEntry(entry),
          )),
    ]));
  }
}

class MetricCard extends StatelessWidget {
  const MetricCard({super.key, required this.title, required this.value, required this.icon, required this.color});
  final String title, value;
  final IconData icon;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(color: panel, borderRadius: BorderRadius.circular(17), border: Border.all(color: Colors.white.withValues(alpha: .06))),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Row(children: [Icon(icon, color: color, size: 19), const SizedBox(width: 8), Text(title, style: const TextStyle(color: muted, fontSize: 13))]),
      FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: Text(value, style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w800, letterSpacing: -.6))),
    ]),
  );
}

class BreakdownRow extends StatelessWidget {
  const BreakdownRow({super.key, required this.label, required this.value, required this.symbol, required this.color, this.negative = false, this.strong = false});
  final String label, symbol;
  final Decimal value;
  final Color color;
  final bool negative, strong;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 7),
    child: Row(children: [
      Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 10),
      Expanded(child: Text(label, style: TextStyle(color: strong ? Colors.white : muted, fontWeight: strong ? FontWeight.w700 : FontWeight.w400))),
      Text('${negative ? '−' : ''}$symbol${amount(value)}', style: TextStyle(fontWeight: strong ? FontWeight.w800 : FontWeight.w600, color: strong ? color : Colors.white)),
    ]),
  );
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.text});
  final String text;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity, padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(color: panel, borderRadius: BorderRadius.circular(16)),
    child: Column(children: [const Icon(Icons.inbox_outlined, color: muted, size: 30), const SizedBox(height: 10), Text(text, textAlign: TextAlign.center, style: const TextStyle(color: muted))]),
  );
}

class EntryTile extends StatelessWidget {
  const EntryTile({super.key, required this.entry, required this.symbol, this.onEdit, this.onDelete});
  final Entry entry;
  final String symbol;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 9), padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(color: panel, borderRadius: BorderRadius.circular(14)),
    child: Row(children: [
      const Icon(Icons.receipt_long_outlined, color: accent),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(entry.label, style: const TextStyle(fontWeight: FontWeight.w700)),
        Text(entry.createdAt.toLocal().toString().substring(0, 16), style: const TextStyle(color: muted, fontSize: 11)),
      ])),
      Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Text('$symbol${amount(entry.grossProfit)}', style: const TextStyle(fontWeight: FontWeight.w700, color: green)),
        Text('Revenue $symbol${amount(entry.revenue)}', style: const TextStyle(color: muted, fontSize: 11)),
      ]),
      if (onEdit != null)
        IconButton(
          tooltip: 'Edit record',
          onPressed: onEdit,
          icon: const Icon(Icons.edit_outlined, color: muted),
        ),
      if (onDelete != null)
        IconButton(
          tooltip: 'Delete record',
          onPressed: onDelete,
          icon: const Icon(Icons.delete_outline_rounded, color: muted),
        ),
    ]),
  );
}

class CalculatorPage extends StatefulWidget {
  const CalculatorPage({super.key, required this.currencySymbol, required this.onSave});
  final String currencySymbol;
  final Future<void> Function(Entry) onSave;
  @override
  State<CalculatorPage> createState() => _CalculatorPageState();
}

class _CalculatorPageState extends State<CalculatorPage> {
  final label = TextEditingController(text: 'Sales estimate');
  final revenue = TextEditingController();
  final cogs = TextEditingController();
  final expenses = TextEditingController();
  final taxRate = TextEditingController(text: '0');
  Decimal get r => money(revenue.text);
  Decimal get c => money(cogs.text);
  Decimal get e => money(expenses.text);
  Decimal get t => money(taxRate.text);
  Decimal get gross => r - c;
  Decimal get net => gross - e;
  Decimal get estimatedTax => net <= Decimal.zero || t <= Decimal.zero
      ? Decimal.zero
      : (net * t / Decimal.fromInt(100)).toDecimal(scaleOnInfinitePrecision: 2);
  Decimal get afterTax => net - estimatedTax;
  Decimal? get breakEvenRevenue => calculateBreakEvenRevenue(revenue: r, cogs: c, expenses: e);
  String get margin => r == Decimal.zero
      ? '—'
      : '${(gross / r * Decimal.fromInt(100).toRational()).toDecimal(scaleOnInfinitePrecision: 2).toStringAsFixed(2)}%';

  @override
  void dispose() { label.dispose(); revenue.dispose(); cogs.dispose(); expenses.dispose(); taxRate.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => SafeArea(child: SingleChildScrollView(padding: const EdgeInsets.all(26), child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 900), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    const Text('CALRU', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2.2)),
    const SizedBox(height: 34),
    const Text('Profit calculator', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800)),
    const SizedBox(height: 6),
    const Text('Enter your figures to calculate profitability instantly.', style: TextStyle(color: muted)),
    const SizedBox(height: 25),
    Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: panel, borderRadius: BorderRadius.circular(18)), child: Column(children: [
      field('Calculation name', label, hint: 'e.g. Product launch'),
      field('Revenue / sales', revenue, hint: '0.00'),
      field('Cost of goods sold', cogs, hint: '0.00'),
      field('Other expenses', expenses, hint: '0.00'),
      field('Estimated tax rate (%)', taxRate, hint: '0'),
    ])),
    const SizedBox(height: 15),
    Container(padding: const EdgeInsets.all(22), decoration: BoxDecoration(color: panel, borderRadius: BorderRadius.circular(18), border: Border.all(color: accent.withValues(alpha: .25)),), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('CALCULATION RESULTS', style: TextStyle(color: muted, fontSize: 11, letterSpacing: 1.4, fontWeight: FontWeight.w700)),
      const SizedBox(height: 16),
      resultRow('Gross profit', gross, green, big: true),
      resultRow('Gross margin', null, accent, extra: margin),
      resultRow('Break-even revenue', breakEvenRevenue, accent, extra: breakEvenRevenue == null ? '—' : '${widget.currencySymbol}${amount(breakEvenRevenue!)}'),
      resultRow('Net profit (before tax)', net, net < Decimal.zero ? const Color(0xFFE18A8A) : green, big: true),
      resultRow('Estimated tax', estimatedTax, const Color(0xFFE18A8A)),
      resultRow('Net profit (after tax)', afterTax, afterTax < Decimal.zero ? const Color(0xFFE18A8A) : green, big: true),
      if (!isValidMoneyInput(revenue.text) || !isValidMoneyInput(cogs.text) || !isValidMoneyInput(expenses.text) || !isValidMoneyInput(taxRate.text) || r < Decimal.zero || c < Decimal.zero || e < Decimal.zero || t < Decimal.zero || t > Decimal.fromInt(100)) const Text('Check your inputs. Enter valid amounts with up to two decimal places. Costs and tax rate must be non-negative, and tax rate cannot exceed 100%.', style: TextStyle(color: Color(0xFFE18A8A), fontSize: 12)),
    ])),
    const SizedBox(height: 16),
    FilledButton.icon(
      onPressed: !isValidMoneyInput(revenue.text) || !isValidMoneyInput(cogs.text) || !isValidMoneyInput(expenses.text) || !isValidMoneyInput(taxRate.text) || r <= Decimal.zero || c < Decimal.zero || e < Decimal.zero || t < Decimal.zero || t > Decimal.fromInt(100) ? null : () async {
        await widget.onSave(Entry(label: label.text.trim().isEmpty ? 'Untitled' : label.text.trim(), revenue: r, cogs: c, expenses: e, taxRate: t, createdAt: DateTime.now()));
        if (!mounted) {
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Calculation saved to your records.')));
      },
      icon: const Icon(Icons.save_outlined), label: const Text('Save calculation'),
      style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
    ),
  ])))));

  Widget field(String title, TextEditingController controller, {String? hint}) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(fontSize: 13, color: muted, fontWeight: FontWeight.w600)),
      const SizedBox(height: 7),
      TextField(controller: controller, keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true), inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,-]'))], decoration: InputDecoration(hintText: hint), onChanged: (_) => setState(() {})),
    ]),
  );

  Widget resultRow(String title, Decimal? value, Color color, {bool big = false, String? extra}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 9),
    child: Row(children: [
      Expanded(child: Text(title, style: TextStyle(color: big ? Colors.white : muted, fontWeight: big ? FontWeight.w700 : FontWeight.w500))),
      Text(extra ?? '${widget.currencySymbol}${amount(value ?? Decimal.zero)}', style: TextStyle(color: color, fontSize: big ? 21 : 16, fontWeight: FontWeight.w800)),
    ]),
  );
}

class ScreenshotPage extends StatefulWidget {
  const ScreenshotPage({super.key, required this.currencySymbol, required this.onSave});
  final String currencySymbol;
  final Future<void> Function(Entry) onSave;
  @override
  State<ScreenshotPage> createState() => _ScreenshotPageState();
}

class _ScreenshotPageState extends State<ScreenshotPage> {
  String? imagePath;
  String extractedText = '';
  final extractedTextController = TextEditingController();
  final taxRate = TextEditingController(text: '0');
  bool processing = false;
  String status = 'Import a receipt, sales dashboard, invoice or financial screenshot.';
  final label = TextEditingController(text: 'Screenshot import');
  final revenue = TextEditingController();
  final cogs = TextEditingController();
  final expenses = TextEditingController();
  final recognizer = TextRecognizer(script: TextRecognitionScript.latin);

  @override
  void dispose() {
    if (Platform.isAndroid || Platform.isIOS) {
      recognizer.close();
    }
    label.dispose(); revenue.dispose(); cogs.dispose(); expenses.dispose();
    extractedTextController.dispose(); taxRate.dispose();
    super.dispose();
  }

  Future<void> importImage() async {
    final result = await FilePicker.pickFiles(type: FileType.image);
    if (!mounted) {
      return;
    }
    if (result.isEmpty || result.single.path == null) return;
    setState(() { imagePath = result.single.path; status = 'Image loaded. Starting text recognition…'; extractedText = ''; extractedTextController.clear(); });
    await recognize();
  }

  Future<void> recognize() async {
    final path = imagePath;
    if (path == null) {
      return;
    }
    setState(() => processing = true);
    try {
      String text;
      if (Platform.isAndroid || Platform.isIOS) {
        final input = InputImage.fromFilePath(path);
        final result = await recognizer.processImage(input);
        text = result.text;
      } else {
        final result = await Process.run('tesseract', [path, 'stdout', '--psm', '6']);
        if (result.exitCode != 0) {
          throw Exception(result.stderr.toString().trim().isEmpty ? 'Tesseract OCR failed.' : result.stderr.toString());
        }
        text = result.stdout.toString();
      }
      if (!mounted) {
        return;
      }
      setState(() {
        extractedText = text;
        extractedTextController.text = text;
        status = text.trim().isEmpty ? 'No text found. You can still enter values manually.' : 'Text extracted. Review every value before saving.';
        suggestNumbers(text);
      });
    } catch (error) {
      if (mounted) {
        setState(() => status = 'OCR unavailable: $error. Enter values manually or install Tesseract on desktop.');
      }
    } finally {
      if (mounted) {
        setState(() => processing = false);
      }
    }
  }

  void suggestNumbers(String text) {
    final lines = text.split(RegExp(r'[\r\n]+'));
    String? find(List<String> keys) {
      for (final line in lines) {
        if (keys.any((key) => line.toLowerCase().contains(key))) {
          final matches = RegExp(r'(?<![A-Za-z])[-]?\d[\d,]*(?:\.\d{1,2})?').allMatches(line).toList();
          if (matches.isNotEmpty) {
            return matches.last.group(0)!.replaceAll(',', '');
          }
        }
      }
      return null;
    }
    final rev = find(['total revenue', 'revenue', 'gross sales', 'total sales', 'sales', 'grand total']);
    final cost = find(['cost of goods', 'cogs', 'cost']);
    final expense = find(['expenses', 'operating expense']);
    if (rev != null) {
      revenue.text = rev;
    }
    if (cost != null) {
      cogs.text = cost;
    }
    if (expense != null) {
      expenses.text = expense;
    }
  }

  bool get canSave =>
      isValidMoneyInput(revenue.text) &&
      isValidMoneyInput(cogs.text) &&
      isValidMoneyInput(expenses.text) &&
      isValidMoneyInput(taxRate.text) &&
      money(revenue.text) > Decimal.zero &&
      money(cogs.text) >= Decimal.zero &&
      money(expenses.text) >= Decimal.zero &&
      money(taxRate.text) >= Decimal.zero &&
      money(taxRate.text) <= Decimal.fromInt(100);

  Future<void> saveFigures() async {
    await widget.onSave(Entry(
      label: label.text.trim().isEmpty ? 'Screenshot import' : label.text.trim(),
      revenue: money(revenue.text),
      cogs: money(cogs.text),
      expenses: money(expenses.text),
      taxRate: money(taxRate.text),
      createdAt: DateTime.now(),
    ));
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Reviewed screenshot figures saved.')),
    );
  }

  @override
  Widget build(BuildContext context) => SafeArea(child: SingleChildScrollView(padding: const EdgeInsets.all(26), child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 900), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    const Text('CALRU', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2.2)),
    const SizedBox(height: 34),
    const Text('Screenshot intelligence', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800)),
    const SizedBox(height: 6),
    const Text('Extract figures from screenshots, then review and correct them.', style: TextStyle(color: muted)),
    const SizedBox(height: 22),
    InkWell(onTap: processing ? null : importImage, borderRadius: BorderRadius.circular(18), child: Container(
      width: double.infinity, constraints: const BoxConstraints(minHeight: 180), padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(color: panel, borderRadius: BorderRadius.circular(18), border: Border.all(color: accent.withValues(alpha: .35))),
      child: imagePath == null ? const Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.add_photo_alternate_outlined, size: 38, color: accent),
        SizedBox(height: 12),
        Text('Import a screenshot', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
        SizedBox(height: 5),
        Text('PNG, JPG, WEBP and other supported image formats', style: TextStyle(color: muted, fontSize: 12)),
      ]) : Column(children: [
        ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.file(File(imagePath!), height: 220, fit: BoxFit.contain)),
        const SizedBox(height: 10),
        const Text('Tap to choose a different image', style: TextStyle(color: muted, fontSize: 12)),
      ]),
    )),
    const SizedBox(height: 14),
    Row(children: [
      if (processing) const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
      if (processing) const SizedBox(width: 10),
      Expanded(child: Text(status, style: const TextStyle(color: muted, fontSize: 12))),
      if (imagePath != null) TextButton(onPressed: processing ? null : recognize, child: const Text('Run OCR again')),
      if (imagePath != null) TextButton(onPressed: processing ? null : () => setState(() { imagePath = null; extractedText = ''; extractedTextController.clear(); status = 'Import a receipt, sales dashboard, invoice or financial screenshot.'; }), child: const Text('Clear')),
    ]),
    const SizedBox(height: 12),
    if (extractedText.isNotEmpty) Container(width: double.infinity, padding: const EdgeInsets.all(15), decoration: BoxDecoration(color: panel, borderRadius: BorderRadius.circular(14)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('RECOGNIZED TEXT · EDITABLE', style: TextStyle(color: muted, fontSize: 10, letterSpacing: 1.2, fontWeight: FontWeight.w700)),
      const SizedBox(height: 8),
      TextField(
        controller: extractedTextController,
        minLines: 4,
        maxLines: 10,
        keyboardType: TextInputType.multiline,
        style: const TextStyle(fontSize: 12, height: 1.5),
        decoration: const InputDecoration(hintText: 'Recognized text appears here'),
      ),
      Align(
        alignment: Alignment.centerRight,
        child: TextButton.icon(
          onPressed: () {
            suggestNumbers(extractedTextController.text);
            setState(() => status = 'Suggestions refreshed from your edited text. Verify every amount.');
          },
          icon: const Icon(Icons.refresh_rounded, size: 16),
          label: const Text('Refresh amount suggestions'),
        ),
      ),
    ])),
    const SizedBox(height: 18),
    const Text('Review extracted figures', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
    const SizedBox(height: 5),
    const Text('OCR suggestions are not trusted until you verify them.', style: TextStyle(color: muted, fontSize: 12)),
    const SizedBox(height: 14),
    input('Record name', label),
    input('Revenue', revenue),
    input('Cost of goods sold', cogs),
    input('Other expenses', expenses),
    input('Estimated tax rate (%)', taxRate),
    const SizedBox(height: 12),
    FilledButton.icon(
      onPressed: canSave ? saveFigures : null,
      icon: const Icon(Icons.verified_outlined),
      label: const Text('Confirm and save figures'),
      style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
    ),
  ])))));

  Widget input(String title, TextEditingController controller) => Padding(padding: const EdgeInsets.only(bottom: 12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(title, style: const TextStyle(color: muted, fontSize: 12, fontWeight: FontWeight.w600)),
    const SizedBox(height: 6),
    TextField(controller: controller, keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true), inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,-]'))], decoration: const InputDecoration(hintText: '0.00'), onChanged: (_) => setState(() {})),
  ]));
}

