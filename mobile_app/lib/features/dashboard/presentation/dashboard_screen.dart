import 'package:finpat_mobile/app/app_scope.dart';
import 'package:finpat_mobile/core/theme/app_theme.dart';
import 'package:finpat_mobile/core/theme/ui_tokens.dart';
import 'package:finpat_mobile/core/utils/formatters.dart';
import 'package:flutter/material.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  String _statusFor(double income, double remaining) {
    if (income <= 0) return 'No income set';
    final remainingPct = remaining / income;
    if (remainingPct >= 0.2) return 'Healthy';
    if (remainingPct >= 0.05) return 'Warning';
    return 'Critical';
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final income = (app.profile?['income_amount'] as num?)?.toDouble() ?? 0;
    final currency = (app.profile?['income_currency'] as String?) ?? 'USD';
    final spent = app.remittances.fold<double>(0, (sum, item) => sum + ((item['amount'] as num?)?.toDouble() ?? 0));
    final totalSaved = app.savings.fold<double>(0, (sum, item) => sum + ((item['amount'] as num?)?.toDouble() ?? 0));
    final remaining = income - spent;
    final ratio = income > 0 ? spent / income : 0.0;
    final completed = app.obligations.where((o) => o['is_completed'] == true).length;
    final sortedObligations = [...app.obligations]..sort((a, b) {
      final aDone = a['is_completed'] == true;
      final bDone = b['is_completed'] == true;
      if (aDone != bDone) return aDone ? 1 : -1;
      final aAmt = ((a['amount'] as num?)?.toDouble() ?? 0);
      final bAmt = ((b['amount'] as num?)?.toDouble() ?? 0);
      return bAmt.compareTo(aAmt);
    });
    final status = _statusFor(income, remaining);
    final statusColor = status == 'Healthy'
        ? AppTheme.success
        : status == 'Warning'
            ? AppTheme.warning
            : AppTheme.critical;

    return RefreshIndicator(
      onRefresh: app.refreshAll,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(UiTokens.pagePadding, UiTokens.itemGap, UiTokens.pagePadding, 24),
        children: [
          Text(
            'Current Cycle',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppTheme.onSurfaceVariant),
          ),
          const SizedBox(height: 6),
          Text(
            'Monthly Snapshot',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: AppTheme.primary),
          ),
          const SizedBox(height: UiTokens.sectionGap),
          if (app.error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(app.error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.primary,
              borderRadius: BorderRadius.circular(UiTokens.radiusXl),
              boxShadow: const [UiTokens.heroShadow],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Total Monthly Income', style: TextStyle(color: Color(0x99FFFFFF), fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                Text(
                  Formatters.money(income, currency: currency),
                  style: const TextStyle(color: Colors.white, fontSize: UiTokens.headingSize, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _darkMetric('Spent', Formatters.money(spent, currency: currency))),
                    const SizedBox(width: 10),
                    Expanded(child: _darkMetric('Remaining', Formatters.money(remaining, currency: currency))),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: UiTokens.sectionGap),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Pressure Indicator', style: TextStyle(fontWeight: FontWeight.w800, color: AppTheme.primary)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(UiTokens.radiusPill),
                        ),
                        child: Text(
                          status.toUpperCase(),
                          style: TextStyle(color: statusColor, fontWeight: FontWeight.w800, fontSize: 10),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(UiTokens.radiusPill),
                    child: LinearProgressIndicator(
                      value: ratio.clamp(0, 1),
                      minHeight: 10,
                      backgroundColor: AppTheme.surfaceContainer,
                      color: statusColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${Formatters.percent(ratio)} capacity used',
                    style: TextStyle(color: statusColor, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: UiTokens.blockGap),
          Row(
            children: [
              Expanded(child: _kpiCard('Total Saved', Formatters.money(totalSaved, currency: currency))),
              const SizedBox(width: 12),
              Expanded(child: _kpiCard('Completed', '$completed/${app.obligations.length}')),
            ],
          ),
          const SizedBox(height: UiTokens.sectionGap),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Active Commitments',
                style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w800, fontSize: 20),
              ),
              Text(
                '$completed/${app.obligations.length} Done',
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.2, color: AppTheme.onSurfaceVariant),
              ),
            ],
          ),
          const SizedBox(height: UiTokens.itemGap),
          if (sortedObligations.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Text(
                  'No active commitments yet.',
                  style: TextStyle(color: AppTheme.onSurfaceVariant.withValues(alpha: 0.8), fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ...sortedObligations.take(8).map((item) {
            final isDone = item['is_completed'] == true;
            return Card(
              margin: const EdgeInsets.only(bottom: UiTokens.itemGap),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                leading: IconButton.filledTonal(
                  onPressed: () => app.toggleObligation(
                    obligationId: item['id'] as String,
                    isCompleted: !isDone,
                  ),
                  icon: Icon(isDone ? Icons.check_circle : Icons.circle_outlined),
                ),
                title: Text(
                  (item['title'] ?? 'Untitled').toString(),
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    decoration: isDone ? TextDecoration.lineThrough : TextDecoration.none,
                    color: isDone ? AppTheme.onSurfaceVariant : AppTheme.onSurface,
                  ),
                ),
                subtitle: Text(
                  '${item['type'] ?? 'monthly'}${item['due_date'] != null ? ' • Due ${item['due_date']}' : ''}',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                ),
                trailing: Text(
                  Formatters.money((item['amount'] as num?) ?? 0, currency: (item['currency'] ?? currency).toString()),
                  style: const TextStyle(fontWeight: FontWeight.w800, color: AppTheme.primary),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _darkMetric(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Color(0x77FFFFFF), fontWeight: FontWeight.w700)),
        const SizedBox(height: 3),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
      ],
    );
  }

  Widget _kpiCard(String label, String value) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppTheme.primary)),
          ],
        ),
      ),
    );
  }
}
