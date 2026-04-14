import 'package:finpat_mobile/app/app_scope.dart';
import 'package:finpat_mobile/core/theme/app_theme.dart';
import 'package:finpat_mobile/core/theme/ui_tokens.dart';
import 'package:flutter/material.dart';

class CentersScreen extends StatefulWidget {
  const CentersScreen({super.key});

  @override
  State<CentersScreen> createState() => _CentersScreenState();
}

class _CentersScreenState extends State<CentersScreen> {
  Future<void> _addCenter() async {
    final app = AppScope.of(context);
    final nameController = TextEditingController();
    final colorController = TextEditingController(text: '#0F766E');
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Center'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: colorController,
              decoration: const InputDecoration(labelText: 'Color hex'),
            ),
          ],
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

    if (nameController.text.trim().isEmpty) return;
    await app.addCenter(name: nameController.text.trim(), color: colorController.text.trim());
  }

  Future<void> _addObligation(String centerId) async {
    final app = AppScope.of(context);
    final titleController = TextEditingController();
    final amountController = TextEditingController();
    final currencyController = TextEditingController(text: 'USD');
    String type = 'monthly';

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Obligation'),
        content: StatefulBuilder(
          builder: (context, setModalState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Title'),
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
              DropdownButtonFormField<String>(
                initialValue: type,
                items: const [
                  DropdownMenuItem(value: 'monthly', child: Text('monthly')),
                  DropdownMenuItem(value: 'one-time', child: Text('one-time')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setModalState(() => type = value);
                  }
                },
                decoration: const InputDecoration(labelText: 'Type'),
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
    if (titleController.text.trim().isEmpty || amount == null || amount <= 0) {
      return;
    }
    await app.addObligation(
      centerId: centerId,
      title: titleController.text.trim(),
      amount: amount,
      currency: currencyController.text.trim(),
      type: type,
    );
  }

  Future<void> _toggleCompletion(Map<String, dynamic> item) async {
    final app = AppScope.of(context);
    final isCompleted = item['is_completed'] == true;
    await app.toggleObligation(obligationId: item['id'] as String, isCompleted: !isCompleted);
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final centers = app.centers;
    final obligations = app.obligations;
    if (app.loading && centers.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (centers.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('No centers yet. Create your first center.'),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _addCenter,
                  child: const Text('Add Center'),
                ),
              ],
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.fromLTRB(UiTokens.pagePadding, 4, UiTokens.pagePadding, 24),
          children: [
            const Text(
              'Manage your financial responsibilities and goals.',
              style: TextStyle(color: AppTheme.onSurfaceVariant, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: UiTokens.blockGap),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: _addCenter,
                child: const Text('Add Center'),
              ),
            ),
            const SizedBox(height: 12),
            ...centers.map((center) {
              final centerObligations = obligations
                  .where((o) => o['center_id'] == center['id'])
                  .toList();
              return Card(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(UiTokens.radiusLg),
                    border: Border(top: BorderSide(color: _fromHex(center['color'] as String? ?? '#004D60'), width: 4)),
                  ),
                  padding: const EdgeInsets.all(UiTokens.pagePadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              center['name'] as String? ?? 'Center',
                              style:
                                  const TextStyle(fontWeight: FontWeight.w800, color: AppTheme.primary),
                            ),
                          ),
                          TextButton(
                            onPressed: () => _addObligation(center['id'] as String),
                            child: const Text('Add Obligation'),
                          ),
                        ],
                      ),
                      if (centerObligations.isEmpty)
                        const Text('No obligations yet.'),
                      ...centerObligations.map(
                        (item) => CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          checkboxShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(UiTokens.itemGap - 2)),
                          value: item['is_completed'] == true,
                          onChanged: (_) => _toggleCompletion(item),
                          title: Text(
                            item['title'] as String? ?? 'Untitled',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          subtitle: Text(
                            '${item['amount']} ${item['currency']} (${item['type']})${item['due_date'] != null ? ' • Due ${item['due_date']}' : ''}',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        );
  }

  Color _fromHex(String hex) {
    final value = hex.replaceAll('#', '');
    if (value.length == 6) {
      return Color(int.parse('FF$value', radix: 16));
    }
    return AppTheme.primary;
  }
}
