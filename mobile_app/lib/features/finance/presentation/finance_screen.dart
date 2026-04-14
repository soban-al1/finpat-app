import 'package:finpat_mobile/app/app_scope.dart';
import 'package:finpat_mobile/core/theme/app_theme.dart';
import 'package:finpat_mobile/core/theme/ui_tokens.dart';
import 'package:finpat_mobile/core/utils/formatters.dart';
import 'package:flutter/material.dart';

class FinanceScreen extends StatefulWidget {
  const FinanceScreen({super.key, this.initialTab = 0, this.showTabs = true});

  final int initialTab;
  final bool showTabs;

  @override
  State<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends State<FinanceScreen> {
  late int _tab;

  @override
  void initState() {
    super.initState();
    _tab = widget.initialTab;
  }

  Future<void> _addRemittance() async {
    final app = AppScope.of(context);
    if (app.centers.isEmpty) return;
    final amountController = TextEditingController();
    final currencyController = TextEditingController(text: 'USD');
    final purposeController = TextEditingController();
    String centerId = app.centers.first['id'] as String;

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Remittance'),
        content: StatefulBuilder(
          builder: (context, setModalState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: centerId,
                items: app.centers
                    .map(
                      (c) => DropdownMenuItem<String>(
                        value: c['id'] as String,
                        child: Text(c['name'] as String? ?? 'Center'),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) setModalState(() => centerId = value);
                },
                decoration: const InputDecoration(labelText: 'Center'),
              ),
              TextField(
                controller: amountController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Amount'),
              ),
              TextField(
                controller: currencyController,
                decoration: const InputDecoration(labelText: 'Currency'),
              ),
              TextField(
                controller: purposeController,
                decoration: const InputDecoration(labelText: 'Purpose'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (ok != true || !mounted) return;
    final amount = double.tryParse(amountController.text.trim());
    if (amount == null || amount <= 0) return;

    await app.addRemittance(
      centerId: centerId,
      amount: amount,
      currency: currencyController.text.trim(),
      purpose: purposeController.text.trim().isEmpty ? null : purposeController.text.trim(),
    );
  }

  Future<void> _addSaving() async {
    final app = AppScope.of(context);
    final amountController = TextEditingController();
    final currencyController = TextEditingController(text: 'USD');
    final noteController = TextEditingController();
    String type = 'manual';

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Savings'),
        content: StatefulBuilder(
          builder: (context, setModalState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: amountController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Amount'),
              ),
              TextField(
                controller: currencyController,
                decoration: const InputDecoration(labelText: 'Currency'),
              ),
              DropdownButtonFormField<String>(
                initialValue: type,
                items: const [
                  DropdownMenuItem(value: 'manual', child: Text('manual')),
                  DropdownMenuItem(value: 'surplus', child: Text('surplus')),
                ],
                onChanged: (value) {
                  if (value != null) setModalState(() => type = value);
                },
                decoration: const InputDecoration(labelText: 'Type'),
              ),
              TextField(
                controller: noteController,
                decoration: const InputDecoration(labelText: 'Note'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (ok != true || !mounted) return;
    final amount = double.tryParse(amountController.text.trim());
    if (amount == null || amount <= 0) return;

    await app.addSavings(
      amount: amount,
      currency: currencyController.text.trim(),
      type: type,
      note: noteController.text.trim().isEmpty ? null : noteController.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    if (app.loading && app.remittances.isEmpty && app.savings.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(UiTokens.pagePadding, 2, UiTokens.pagePadding, 4),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              _tab == 0
                  ? 'Track your daily expenses and commitment payments.'
                  : 'View your safety-net growth over time.',
              style: const TextStyle(color: AppTheme.onSurfaceVariant, fontWeight: FontWeight.w600),
            ),
          ),
        ),
        if (widget.showTabs)
          Padding(
            padding: const EdgeInsets.fromLTRB(UiTokens.pagePadding, 4, UiTokens.pagePadding, UiTokens.blockGap),
            child: SegmentedButton<int>(
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) return AppTheme.primary;
                  return AppTheme.surfaceContainer;
                }),
                foregroundColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) return Colors.white;
                  return AppTheme.onSurfaceVariant;
                }),
                textStyle: const WidgetStatePropertyAll(TextStyle(fontWeight: FontWeight.w800)),
              ),
              segments: const [
                ButtonSegment<int>(value: 0, label: Text('Spent')),
                ButtonSegment<int>(value: 1, label: Text('Savings')),
              ],
              selected: {_tab},
              onSelectionChanged: (selected) {
                setState(() => _tab = selected.first);
              },
            ),
          ),
        Expanded(
          child: _tab == 0 ? _buildRemittanceList() : _buildSavingsList(),
        ),
      ],
    );
  }

  Widget _buildRemittanceList() {
    final app = AppScope.of(context);
    if (app.remittances.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('No remittances yet.'),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _addRemittance,
              child: const Text('Add Remittance'),
            ),
          ],
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(UiTokens.pagePadding, 4, UiTokens.pagePadding, 24),
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton(
            onPressed: _addRemittance,
            child: const Text('Add Remittance'),
          ),
        ),
        const SizedBox(height: 12),
        ...app.remittances.map(
          (item) => Card(
            child: ListTile(
              leading: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(UiTokens.radiusSm),
                ),
                child: const Icon(Icons.arrow_outward_rounded, color: AppTheme.primary),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () => app.deleteRemittance(item['id'] as String),
              ),
              title: Text(
                Formatters.money((item['amount'] as num?) ?? 0, currency: item['currency'] as String? ?? 'USD'),
                style: const TextStyle(fontWeight: FontWeight.w800, color: AppTheme.primary),
              ),
              subtitle: Text(
                '${item['date']} ${item['purpose'] ?? ''}'.trim(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSavingsList() {
    final app = AppScope.of(context);
    if (app.savings.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('No savings entries yet.'),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _addSaving,
              child: const Text('Add Savings'),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(UiTokens.pagePadding, 4, UiTokens.pagePadding, 24),
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton(
            onPressed: _addSaving,
            child: const Text('Add Savings'),
          ),
        ),
        const SizedBox(height: 12),
        ...app.savings.map(
          (item) => Card(
            child: ListTile(
              leading: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: (item['type'] == 'surplus' ? AppTheme.primary : AppTheme.success).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(UiTokens.radiusSm),
                ),
                child: Icon(
                  item['type'] == 'surplus' ? Icons.trending_up : Icons.savings_outlined,
                  color: item['type'] == 'surplus' ? AppTheme.primary : AppTheme.success,
                ),
              ),
              title: Text(
                Formatters.money((item['amount'] as num?) ?? 0, currency: item['currency'] as String? ?? 'USD'),
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: item['type'] == 'surplus' ? AppTheme.primary : AppTheme.success,
                ),
              ),
              subtitle: Text(
                '${item['date']} (${item['type']}) ${item['note'] ?? ''}'.trim(),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
