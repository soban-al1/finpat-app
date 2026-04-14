import 'package:finpat_mobile/app/app_scope.dart';
import 'package:finpat_mobile/core/theme/app_theme.dart';
import 'package:finpat_mobile/core/theme/ui_tokens.dart';
import 'package:finpat_mobile/core/utils/formatters.dart';
import 'package:flutter/material.dart';

class ForecastScreen extends StatelessWidget {
  const ForecastScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: AppScope.of(context).loadForecast(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        final rows = snapshot.data ?? <Map<String, dynamic>>[];
        if (rows.isEmpty) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(UiTokens.pagePadding, 4, UiTokens.pagePadding, 24),
            children: const [
              Card(
                child: Padding(
                  padding: EdgeInsets.all(UiTokens.pagePadding),
                  child: Text('Forecast is temporarily unavailable.'),
                ),
              ),
            ],
          );
        }
        final remainingValues = rows
            .map((row) => (row['remaining'] as num?)?.toDouble() ?? 0)
            .toList();
        final minValue = remainingValues.isEmpty ? 0 : remainingValues.reduce((a, b) => a < b ? a : b);
        final maxValue = remainingValues.isEmpty ? 0 : remainingValues.reduce((a, b) => a > b ? a : b);
        final avgValue = remainingValues.isEmpty
            ? 0
            : remainingValues.reduce((a, b) => a + b) / remainingValues.length;

        return ListView(
          padding: const EdgeInsets.fromLTRB(UiTokens.pagePadding, 4, UiTokens.pagePadding, 24),
          children: rows.map<Widget>((row) {
            final month = (row['month'] ?? '').toString();
            final remaining = (row['remaining'] as num?)?.toDouble() ?? 0;
            final status = (row['status'] ?? 'N/A').toString();
            Color chipColor = AppTheme.success;
            if (status.toLowerCase().contains('critical')) chipColor = AppTheme.critical;
            if (status.toLowerCase().contains('warning')) chipColor = AppTheme.warning;
            return Card(
              margin: const EdgeInsets.only(bottom: UiTokens.blockGap),
              child: ListTile(
                title: Text(
                  month.isEmpty ? 'Upcoming month' : month,
                  style: const TextStyle(fontWeight: FontWeight.w800, color: AppTheme.primary),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: UiTokens.blockGap, vertical: 4),
                    decoration: BoxDecoration(
                      color: chipColor.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(UiTokens.radiusPill),
                    ),
                    child: Text(
                      status.toUpperCase(),
                      style: TextStyle(color: chipColor, fontWeight: FontWeight.w800, fontSize: 11),
                    ),
                  ),
                ),
                trailing: Text(
                  Formatters.money(remaining),
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            );
          }).toList()
            ..insert(
              0,
              const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Text(
                  'Projected month-by-month remaining balance.',
                  style: TextStyle(color: AppTheme.onSurfaceVariant, fontWeight: FontWeight.w600),
                ),
              ),
            )
            ..insert(
              1,
              Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(UiTokens.pagePadding),
                  child: Row(
                    children: [
                      Expanded(child: _summaryMetric('Min', Formatters.money(minValue))),
                      Expanded(child: _summaryMetric('Avg', Formatters.money(avgValue))),
                      Expanded(child: _summaryMetric('Max', Formatters.money(maxValue))),
                    ],
                  ),
                ),
              ),
            ),
        );
      },
    );
  }

  Widget _summaryMetric(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: UiTokens.metaSize, fontWeight: FontWeight.w800, color: AppTheme.onSurfaceVariant)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w800, color: AppTheme.primary)),
      ],
    );
  }
}
