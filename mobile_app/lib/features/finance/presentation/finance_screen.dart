import 'package:finpat_mobile/app/app_scope.dart';
import 'package:finpat_mobile/core/theme/app_theme.dart';
import 'package:finpat_mobile/core/theme/ui_tokens.dart';
import 'package:finpat_mobile/core/utils/formatters.dart';
import 'package:flutter/material.dart';

// ── Currency list (mirrors onboarding) ────────────────────────────────────────
class _CurrencyOption {
  const _CurrencyOption(this.code, this.flag);
  final String code;
  final String flag;
}

const List<_CurrencyOption> _currencies = [
  _CurrencyOption('USD', '🇺🇸'),
  _CurrencyOption('EUR', '🇪🇺'),
  _CurrencyOption('GBP', '🇬🇧'),
  _CurrencyOption('AED', '🇦🇪'),
  _CurrencyOption('INR', '🇮🇳'),
  _CurrencyOption('PHP', '🇵🇭'),
  _CurrencyOption('PKR', '🇵🇰'),
  _CurrencyOption('EGP', '🇪🇬'),
  _CurrencyOption('MYR', '🇲🇾'),
  _CurrencyOption('SGD', '🇸🇬'),
  _CurrencyOption('IDR', '🇮🇩'),
  _CurrencyOption('THB', '🇹🇭'),
  _CurrencyOption('VND', '🇻🇳'),
  _CurrencyOption('BND', '🇧🇳'),
  _CurrencyOption('MMK', '🇲🇲'),
  _CurrencyOption('KHR', '🇰🇭'),
  _CurrencyOption('LAK', '🇱🇦'),
];

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

  Future<void> _addSpent() async {
    final app = AppScope.of(context);
    if (app.centers.isEmpty) return;
    final incomeCurrency = (app.profile?['income_currency'] as String?)?.toUpperCase() ?? 'USD';

    final result = await showModalBottomSheet<({String centerId, double amount, String currency, String? purpose})>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: AppTheme.surface,
      builder: (_) => _AddSpentSheet(
        centers: app.centers,
        incomeCurrency: incomeCurrency,
      ),
    );

    if (result != null && mounted) {
      await app.addRemittance(
        centerId: result.centerId,
        amount: result.amount,
        currency: result.currency,
        purpose: result.purpose,
        targetCurrency: incomeCurrency,
      );
    }
  }

  Future<void> _addSaving() async {
    final app = AppScope.of(context);
    final incomeCurrency = (app.profile?['income_currency'] as String?)?.toUpperCase() ?? 'USD';

    final result = await showModalBottomSheet<({double amount, String currency, String type, String? note})>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: AppTheme.surface,
      builder: (_) => _AddSavingSheet(incomeCurrency: incomeCurrency),
    );

    if (result != null && mounted) {
      await app.addSavings(
        amount: result.amount,
        currency: result.currency,
        type: result.type,
        note: result.note,
      );
    }
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
              onSelectionChanged: (selected) => setState(() => _tab = selected.first),
            ),
          ),
        Expanded(
          child: _tab == 0 ? _buildRemittanceList() : _buildSavingsList(),
        ),
        // ── Sticky bottom CTA ────────────────────────────────────────────────
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(UiTokens.pagePadding, 8, UiTokens.pagePadding, 16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _tab == 0 ? _addSpent : _addSaving,
                child: Text(_tab == 0 ? 'Add Spent' : 'Add Savings'),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRemittanceList() {
    final app = AppScope.of(context);
    if (app.remittances.isEmpty) {
      return const Center(child: Text('No entries yet. Add your first spend below.'));
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(UiTokens.pagePadding, 4, UiTokens.pagePadding, 8),
      children: app.remittances.map(
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
              onPressed: () => AppScope.of(context).deleteRemittance(item['id'] as String),
            ),
            title: Text(
              Formatters.money((item['amount'] as num?) ?? 0, currency: item['currency'] as String? ?? 'USD'),
              style: const TextStyle(fontWeight: FontWeight.w800, color: AppTheme.primary),
            ),
            subtitle: Text('${item['date']} ${item['purpose'] ?? ''}'.trim()),
          ),
        ),
      ).toList(),
    );
  }

  Widget _buildSavingsList() {
    final app = AppScope.of(context);
    if (app.savings.isEmpty) {
      return const Center(child: Text('No savings yet. Add your first entry below.'));
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(UiTokens.pagePadding, 4, UiTokens.pagePadding, 8),
      children: app.savings.map(
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
            subtitle: Text('${item['date']} (${item['type']}) ${item['note'] ?? ''}'.trim()),
          ),
        ),
      ).toList(),
    );
  }
}

const _labelStyle = TextStyle(
  fontSize: 11,
  fontWeight: FontWeight.w900,
  letterSpacing: 1.3,
  color: AppTheme.onSurfaceVariant,
);

// ── Add Spent bottom sheet ───────────────────────────────────────────────────
class _AddSpentSheet extends StatefulWidget {
  const _AddSpentSheet({required this.centers, required this.incomeCurrency});
  final List<Map<String, dynamic>> centers;
  final String incomeCurrency;

  @override
  State<_AddSpentSheet> createState() => _AddSpentSheetState();
}

class _AddSpentSheetState extends State<_AddSpentSheet> {
  final _amountController = TextEditingController();
  final _purposeController = TextEditingController();
  late String _centerId;
  late String _currency;
  String? _error;

  @override
  void initState() {
    super.initState();
    _centerId = widget.centers.first['id'] as String;
    _currency = widget.incomeCurrency;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _purposeController.dispose();
    super.dispose();
  }

  Future<void> _pickCurrency() async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: AppTheme.surface,
      builder: (_) => _CurrencyPickerSheet(selected: _currency),
    );
    if (picked != null && mounted) setState(() => _currency = picked);
  }

  void _save() {
    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      setState(() => _error = 'Enter a valid amount.');
      return;
    }
    Navigator.pop(context, (
      centerId: _centerId,
      amount: amount,
      currency: _currency,
      purpose: _purposeController.text.trim().isEmpty ? null : _purposeController.text.trim(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final flag = _currencies.firstWhere(
      (c) => c.code == _currency,
      orElse: () => const _CurrencyOption('', '🌐'),
    ).flag;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Add Spent', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppTheme.primary)),
          const SizedBox(height: 20),
          const Text('CENTER', style: _labelStyle),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            initialValue: _centerId,
            items: widget.centers.map((c) => DropdownMenuItem<String>(
              value: c['id'] as String,
              child: Text(c['name'] as String? ?? 'Center'),
            )).toList(),
            onChanged: (v) { if (v != null) setState(() => _centerId = v); },
            decoration: const InputDecoration(),
          ),
          const SizedBox(height: 16),
          const Text('AMOUNT', style: _labelStyle),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppTheme.primary),
                  decoration: const InputDecoration(hintText: '0.00'),
                ),
              ),
              const SizedBox(width: 10),
              _CurrencyButton(flag: flag, code: _currency, onTap: _pickCurrency),
            ],
          ),
          if (_currency != widget.incomeCurrency) ...[
            const SizedBox(height: 6),
            Text('Will be converted to ${widget.incomeCurrency} at current rate',
                style: const TextStyle(fontSize: 12, color: AppTheme.onSurfaceVariant)),
          ],
          const SizedBox(height: 16),
          const Text('PURPOSE', style: _labelStyle),
          const SizedBox(height: 6),
          TextField(
            controller: _purposeController,
            decoration: const InputDecoration(hintText: 'e.g. rent, groceries'),
          ),
          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 13)),
          ],
          const SizedBox(height: 24),
          SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _save, child: const Text('Save'))),
        ],
      ),
    );
  }
}

// ── Add Saving bottom sheet ──────────────────────────────────────────────────
class _AddSavingSheet extends StatefulWidget {
  const _AddSavingSheet({required this.incomeCurrency});
  final String incomeCurrency;

  @override
  State<_AddSavingSheet> createState() => _AddSavingSheetState();
}

class _AddSavingSheetState extends State<_AddSavingSheet> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  late String _currency;
  String _type = 'manual';
  String? _error;

  @override
  void initState() {
    super.initState();
    _currency = widget.incomeCurrency;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickCurrency() async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: AppTheme.surface,
      builder: (_) => _CurrencyPickerSheet(selected: _currency),
    );
    if (picked != null && mounted) setState(() => _currency = picked);
  }

  void _save() {
    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      setState(() => _error = 'Enter a valid amount.');
      return;
    }
    Navigator.pop(context, (
      amount: amount,
      currency: _currency,
      type: _type,
      note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final flag = _currencies.firstWhere(
      (c) => c.code == _currency,
      orElse: () => const _CurrencyOption('', '🌐'),
    ).flag;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Add Savings', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppTheme.primary)),
          const SizedBox(height: 20),
          const Text('AMOUNT', style: _labelStyle),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppTheme.success),
                  decoration: const InputDecoration(hintText: '0.00'),
                ),
              ),
              const SizedBox(width: 10),
              _CurrencyButton(flag: flag, code: _currency, onTap: _pickCurrency),
            ],
          ),
          const SizedBox(height: 16),
          const Text('TYPE', style: _labelStyle),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            initialValue: _type,
            items: const [
              DropdownMenuItem(value: 'manual', child: Text('Manual')),
              DropdownMenuItem(value: 'surplus', child: Text('Surplus')),
            ],
            onChanged: (v) { if (v != null) setState(() => _type = v); },
            decoration: const InputDecoration(),
          ),
          const SizedBox(height: 16),
          const Text('NOTE', style: _labelStyle),
          const SizedBox(height: 6),
          TextField(
            controller: _noteController,
            decoration: const InputDecoration(hintText: 'Optional note'),
          ),
          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 13)),
          ],
          const SizedBox(height: 24),
          SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _save, child: const Text('Save'))),
        ],
      ),
    );
  }
}

// ── Currency button ──────────────────────────────────────────────────────────
class _CurrencyButton extends StatelessWidget {
  const _CurrencyButton({required this.flag, required this.code, required this.onTap});

  final String flag;
  final String code;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: AppTheme.surfaceContainer,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(flag, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 6),
            Text(code, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppTheme.onSurface)),
            const SizedBox(width: 4),
            const Icon(Icons.keyboard_arrow_down_rounded, size: 20, color: AppTheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

// ── Currency picker bottom sheet ─────────────────────────────────────────────
class _CurrencyPickerSheet extends StatefulWidget {
  const _CurrencyPickerSheet({required this.selected});
  final String selected;

  @override
  State<_CurrencyPickerSheet> createState() => _CurrencyPickerSheetState();
}

class _CurrencyPickerSheetState extends State<_CurrencyPickerSheet> {
  final _searchController = TextEditingController();
  List<_CurrencyOption> _filtered = _currencies;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch(String q) {
    setState(() {
      _filtered = q.isEmpty
          ? _currencies
          : _currencies.where((c) => c.code.toLowerCase().contains(q.toLowerCase())).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      builder: (context, scrollController) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Select currency',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppTheme.primary),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _searchController,
                autofocus: true,
                onChanged: _onSearch,
                decoration: const InputDecoration(
                  hintText: 'Search currency...',
                  prefixIcon: Icon(Icons.search_rounded),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: _filtered.length,
                  itemBuilder: (context, i) {
                    final c = _filtered[i];
                    final isSelected = c.code == widget.selected;
                    return ListTile(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      tileColor: isSelected ? AppTheme.primary.withValues(alpha: 0.08) : null,
                      leading: Text(c.flag, style: const TextStyle(fontSize: 24)),
                      title: Text(c.code, style: const TextStyle(fontWeight: FontWeight.w800)),
                      trailing: isSelected ? const Icon(Icons.check_rounded, color: AppTheme.primary) : null,
                      onTap: () => Navigator.pop(context, c.code),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
