import 'package:finpat_mobile/app/app_scope.dart';
import 'package:finpat_mobile/app/app_state.dart';
import 'package:finpat_mobile/core/theme/app_theme.dart';
import 'package:finpat_mobile/core/theme/ui_tokens.dart';
import 'package:finpat_mobile/core/utils/formatters.dart';
import 'package:flutter/material.dart';

// Month names — avoids needing intl locale initialization.
const _monthNames = [
  '', 'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);

    // ── Loading ──────────────────────────────────────────────────────────────
    if (app.initializing || (app.summaryLoading && app.dashboardSummary == null)) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primary),
      );
    }

    // ── Local remittance totals (computed first — used as fallback below) ──────
    double commitmentSpent = 0;
    double additionalSpent = 0;
    for (final r in app.remittances) {
      final amt = (r['amount'] as num?)?.toDouble() ?? 0;
      final rate = (r['exchange_rate'] as num?)?.toDouble() ?? 1;
      final converted = amt * rate;
      if (r['obligation_id'] != null) {
        commitmentSpent += converted;
      } else {
        additionalSpent += converted;
      }
    }
    final localTotalSpent = commitmentSpent + additionalSpent;

    // Local manual-savings total (fallback when server summary unavailable)
    double localSavingsTotal = 0;
    for (final s in app.savings) {
      if ((s['type'] as String?) == 'manual') {
        localSavingsTotal += (s['amount'] as num?)?.toDouble() ?? 0;
      }
    }

    // ── Pull data from dashboard-summary (server is source of truth) ─────────
    final summary = app.dashboardSummary ?? const {};
    final income = (summary['income'] as Map<String, dynamic>?) ?? const {};

    // Fall back to profile fields when dashboard-summary hasn't loaded yet.
    final salaryCurrency = (income['currency'] as String?)
        ?? (app.profile?['income_currency'] as String?)
        ?? 'USD';
    final totalIncome = (income['amount'] as num?)?.toDouble()
        ?? (app.profile?['income_amount'] as num?)?.toDouble()
        ?? 0;
    // Fall back to local remittance sum when dashboard-summary is unavailable.
    final totalSpent = (summary['spent'] as num?)?.toDouble() ?? localTotalSpent;
    final savingsThisCycle = (summary['savings_this_cycle'] as num?)?.toDouble()
        ?? localSavingsTotal;
    final remainingBalance = (summary['remaining'] as num?)?.toDouble()
        ?? (totalIncome - totalSpent - localSavingsTotal);
    // pressure is 0–100 from server; fall back to local calculation
    final pressurePercent = (summary['pressure'] as num?)?.toDouble()
        ?? (totalIncome > 0 ? ((totalSpent + localSavingsTotal) / totalIncome * 100).clamp(0, 100) : 0);

    final obligationMeta = (summary['obligations'] as Map<String, dynamic>?) ?? const {};
    final completedCount = (obligationMeta['completed'] as num?)?.toInt() ?? 0;
    final totalCount = (obligationMeta['total'] as num?)?.toInt() ?? 0;

    final nextDue = summary['next_due'] as Map<String, dynamic>?;

    final goalProgress =
        (summary['goal_progress'] as List<dynamic>?)
            ?.cast<Map<String, dynamic>>() ??
        const [];

    // ── Commitment list from local state (full detail + toggle button) ────────
    final sortedObligations = [...app.obligations]..sort((a, b) {
        final aDone = a['is_completed'] == true;
        final bDone = b['is_completed'] == true;
        if (aDone != bDone) return aDone ? 1 : -1;
        final aAmt = (a['amount'] as num?)?.toDouble() ?? 0;
        final bAmt = (b['amount'] as num?)?.toDouble() ?? 0;
        return bAmt.compareTo(aAmt);
      });

    // ── Derived UI state ──────────────────────────────────────────────────────
    final now = DateTime.now();
    final endOfMonth = DateTime(now.year, now.month + 1, 0);
    final daysLeft =
        endOfMonth.difference(DateTime(now.year, now.month, now.day)).inDays;
    final isEndMonth = daysLeft <= 2;
    final isCritical = pressurePercent > 80;
    final statusLabel = isCritical ? 'CRITICAL' : 'OPTIMAL';
    final statusColor = isCritical ? AppTheme.critical : AppTheme.success;

    return RefreshIndicator(
      onRefresh: app.refreshAll,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          if (app.error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(app.error!,
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.error)),
            ),

          // ─── Current cycle header ─────────────────────────────────────────
          const Text(
            'CURRENT CYCLE',
            style: TextStyle(
              color: AppTheme.onSurfaceVariant,
              fontWeight: FontWeight.w800,
              fontSize: 10,
              letterSpacing: 2.0,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  '${_monthNames[now.month]} ${now.year}',
                  style: const TextStyle(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.w900,
                    fontSize: 36,
                    letterSpacing: -0.8,
                    height: 1.1,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(UiTokens.radiusMd),
                  border: Border.all(color: AppTheme.surfaceContainer),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.calendar_today_outlined,
                        size: 14, color: AppTheme.primary),
                    const SizedBox(width: 6),
                    Text(
                      '$daysLeft days left',
                      style: const TextStyle(
                        color: AppTheme.primary,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // ─── Hero card ────────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: AppTheme.primary,
              borderRadius: BorderRadius.circular(36),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primary.withValues(alpha: 0.2),
                  blurRadius: 28,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'TOTAL MONTHLY INCOME',
                            style: TextStyle(
                              color: Color(0x99FFFFFF),
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                              letterSpacing: 2.0,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            Formatters.money(totalIncome,
                                currency: salaryCurrency),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 44,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -1.2,
                              height: 1.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isEndMonth)
                      InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => _confirmResetCycle(context, remainingBalance, salaryCurrency),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.refresh, color: Colors.white, size: 18),
                              SizedBox(width: 6),
                              Text(
                                'RESET',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 28),
                Container(
                    height: 1,
                    color: Colors.white.withValues(alpha: 0.1)),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: _heroMetric(
                        'TOTAL SPENT',
                        Formatters.money(totalSpent, currency: salaryCurrency),
                        Colors.white,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _heroMetric(
                        'REMAINING BALANCE',
                        Formatters.money(remainingBalance,
                            currency: salaryCurrency),
                        const Color(0xFF76F2E1),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ─── Pressure indicator ───────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(36),
              border: Border.all(
                  color: AppTheme.surfaceContainer.withValues(alpha: 0.5)),
              boxShadow: const [
                BoxShadow(
                    color: Color(0x0A000000),
                    blurRadius: 8,
                    offset: Offset(0, 2)),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: AppTheme.primary.withValues(alpha: 0.1)),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(Icons.speed,
                      color: AppTheme.primary, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Pressure Indicator',
                                  style: TextStyle(
                                    color: AppTheme.primary,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 18,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: statusColor.withValues(alpha: 0.1),
                                        borderRadius:
                                            BorderRadius.circular(99),
                                      ),
                                      child: Text(
                                        statusLabel,
                                        style: TextStyle(
                                          color: statusColor,
                                          fontWeight: FontWeight.w900,
                                          fontSize: 9,
                                          letterSpacing: 1.3,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'STATUS',
                                      style: TextStyle(
                                        color: AppTheme.onSurfaceVariant
                                            .withValues(alpha: 0.5),
                                        fontWeight: FontWeight.w800,
                                        fontSize: 10,
                                        letterSpacing: 1.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${pressurePercent.round()}%',
                                style: const TextStyle(
                                  color: AppTheme.primary,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 26,
                                  letterSpacing: -0.8,
                                  height: 1.0,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'CAPACITY\nUSED',
                                textAlign: TextAlign.right,
                                style: TextStyle(
                                  color: AppTheme.onSurfaceVariant
                                      .withValues(alpha: 0.5),
                                  fontWeight: FontWeight.w800,
                                  fontSize: 9,
                                  letterSpacing: 1.3,
                                  height: 1.2,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(99),
                            child: LinearProgressIndicator(
                              value: (pressurePercent / 100).clamp(0.0, 1.0),
                              minHeight: 10,
                              backgroundColor: AppTheme.surfaceContainer,
                              color: isCritical
                                  ? AppTheme.critical
                                  : AppTheme.primary,
                            ),
                          ),
                          Positioned.fill(
                            child: LayoutBuilder(builder: (ctx, c) {
                              return Stack(
                                children: [
                                  Positioned(
                                    left: c.maxWidth * 0.70,
                                    top: 0,
                                    bottom: 0,
                                    child: Container(
                                        width: 1,
                                        color: Colors.white
                                            .withValues(alpha: 0.35)),
                                  ),
                                  Positioned(
                                    left: c.maxWidth * 0.90,
                                    top: 0,
                                    bottom: 0,
                                    child: Container(
                                        width: 1,
                                        color: Colors.white
                                            .withValues(alpha: 0.35)),
                                  ),
                                ],
                              );
                            }),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ─── Spent Breakdown / Due Next grid ──────────────────────────────
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _breakdownCard(
                    commitments:
                        Formatters.money(commitmentSpent, currency: salaryCurrency),
                    additional:
                        Formatters.money(additionalSpent, currency: salaryCurrency),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _dueNextCard(
                    amount: nextDue != null
                        ? Formatters.money(
                            (nextDue['amount'] as num?) ?? 0,
                            currency: (nextDue['currency'] as String?) ??
                                salaryCurrency,
                          )
                        : Formatters.money(0, currency: salaryCurrency),
                    caption: nextDue != null
                        ? _dueCaption(nextDue)
                        : 'No upcoming dues',
                    isOverdue: nextDue != null &&
                        ((nextDue['days_from_now'] as num?)?.toInt() ?? 1) < 0,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ─── Add to Savings ───────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(28),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppTheme.tertiaryContainer.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(Icons.account_balance_wallet_outlined,
                      color: AppTheme.primary, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Add to Savings',
                        style: TextStyle(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        savingsThisCycle > 0
                            ? '${Formatters.money(savingsThisCycle, currency: salaryCurrency)} saved this cycle'
                            : 'Deduct from current balance',
                        style: const TextStyle(
                          color: AppTheme.onSurfaceVariant,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => _showAddSavingsSheet(context, salaryCurrency),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppTheme.primary,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(Icons.add, color: Colors.white, size: 22),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // ─── Active commitments ───────────────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Expanded(
                child: Text(
                  'Active Commitments',
                  style: TextStyle(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.w900,
                    fontSize: 22,
                    letterSpacing: -0.4,
                  ),
                ),
              ),
              Text(
                '$completedCount / $totalCount DONE',
                style: const TextStyle(
                  color: AppTheme.onSurfaceVariant,
                  fontWeight: FontWeight.w800,
                  fontSize: 10,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (sortedObligations.isEmpty)
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppTheme.surfaceContainer),
              ),
              child: Text(
                'No active commitments yet.',
                style: TextStyle(
                  color: AppTheme.onSurfaceVariant.withValues(alpha: 0.8),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ...sortedObligations.map(
            (o) => _commitmentTile(context, app, o, salaryCurrency, goalProgress),
          ),
        ],
      ),
    );
  }

  // ── Widget helpers ──────────────────────────────────────────────────────────

  Widget _heroMetric(String label, String value, Color valueColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0x66FFFFFF),
            fontWeight: FontWeight.w800,
            fontSize: 10,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontWeight: FontWeight.w900,
            fontSize: 22,
            letterSpacing: -0.6,
          ),
        ),
      ],
    );
  }

  Widget _breakdownCard({
    required String commitments,
    required String additional,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
            color: AppTheme.surfaceContainer.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SPENT BREAKDOWN',
            style: TextStyle(
              color: AppTheme.onSurfaceVariant.withValues(alpha: 0.5),
              fontWeight: FontWeight.w800,
              fontSize: 10,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            height: 3,
            width: 32,
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'COMMITMENTS',
            style: TextStyle(
              color: AppTheme.onSurfaceVariant.withValues(alpha: 0.6),
              fontWeight: FontWeight.w800,
              fontSize: 10,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            commitments,
            style: const TextStyle(
              color: AppTheme.primary,
              fontWeight: FontWeight.w900,
              fontSize: 20,
              letterSpacing: -0.4,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'ADDITIONAL',
            style: TextStyle(
              color: AppTheme.onSurfaceVariant.withValues(alpha: 0.6),
              fontWeight: FontWeight.w800,
              fontSize: 10,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            additional,
            style: const TextStyle(
              color: AppTheme.primary,
              fontWeight: FontWeight.w900,
              fontSize: 20,
              letterSpacing: -0.4,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _dueNextCard({
    required String amount,
    required String caption,
    bool isOverdue = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4F4),
        borderRadius: BorderRadius.circular(32),
        border:
            Border.all(color: AppTheme.critical.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isOverdue ? 'OVERDUE' : 'DUE NEXT',
            style: TextStyle(
              color: AppTheme.critical.withValues(alpha: 0.5),
              fontWeight: FontWeight.w800,
              fontSize: 10,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            height: 3,
            width: 32,
            decoration: BoxDecoration(
              color: AppTheme.critical.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            amount,
            style: const TextStyle(
              color: AppTheme.critical,
              fontWeight: FontWeight.w900,
              fontSize: 28,
              letterSpacing: -1.0,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            caption,
            style: TextStyle(
              color: AppTheme.critical.withValues(alpha: 0.7),
              fontSize: 11,
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  /// Formats the "Due Next" caption using server-supplied `days_from_now`.
  String _dueCaption(Map<String, dynamic> nextDue) {
    final title = (nextDue['title'] as String?) ?? 'Commitment';
    final days = (nextDue['days_from_now'] as num?)?.toInt();
    if (days == null) return title;
    if (days < 0) return '$title · ${(-days)}d overdue';
    if (days == 0) return '$title · due today';
    return '$title · in ${days}d';
  }

  Widget _commitmentTile(
    BuildContext context,
    AppStateController app,
    Map<String, dynamic> o,
    String salaryCurrency,
    List<Map<String, dynamic>> goalProgress,
  ) {
    final isDone = o['is_completed'] == true;
    final title = (o['title'] ?? 'Untitled').toString();
    final type = (o['type'] ?? 'monthly').toString();
    final dueDate = o['due_date'] as String?;
    final amount = (o['amount'] as num?)?.toDouble() ?? 0;
    final ccy = (o['currency'] as String?) ?? salaryCurrency;
    final obligationId = o['id'] as String?;

    // Goal progress from summary — only shown when goal_amount is set.
    final goalData = obligationId != null
        ? goalProgress
            .where((g) => g['obligation_id'] == obligationId)
            .firstOrNull
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: EdgeInsets.only(bottom: goalData != null && !isDone ? 0 : 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDone
                ? AppTheme.surfaceContainerLow.withValues(alpha: 0.5)
                : AppTheme.surfaceContainerLowest,
            borderRadius: BorderRadius.vertical(
              top: const Radius.circular(28),
              bottom: goalData != null && !isDone
                  ? Radius.zero
                  : const Radius.circular(28),
            ),
            border: Border.all(
              color: isDone ? Colors.transparent : AppTheme.surfaceContainer,
            ),
            boxShadow: isDone
                ? null
                : const [
                    BoxShadow(
                        color: Color(0x08000000),
                        blurRadius: 6,
                        offset: Offset(0, 2))
                  ],
          ),
          child: Opacity(
            opacity: isDone ? 0.6 : 1,
            child: Row(
              children: [
                InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () async {
                    final err = await app.toggleObligation(
                      obligationId: o['id'] as String,
                      isCompleted: !isDone,
                    );
                    if (err != null && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(err),
                          backgroundColor: AppTheme.critical,
                        ),
                      );
                    }
                  },
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color:
                          isDone ? AppTheme.success : AppTheme.surfaceContainer,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.check_circle,
                      color: isDone
                          ? Colors.white
                          : AppTheme.onSurfaceVariant.withValues(alpha: 0.25),
                      size: 24,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                          color: AppTheme.onSurface,
                          decoration: isDone
                              ? TextDecoration.lineThrough
                              : TextDecoration.none,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${type.toUpperCase()}${dueDate != null ? ' • DUE $dueDate' : ''}',
                        style: TextStyle(
                          color: AppTheme.onSurfaceVariant
                              .withValues(alpha: 0.6),
                          fontWeight: FontWeight.w800,
                          fontSize: 10,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      Formatters.money(amount, currency: ccy),
                      style: const TextStyle(
                        color: AppTheme.primary,
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                      ),
                    ),
                    if (isDone)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          'SETTLED',
                          style: TextStyle(
                            color: AppTheme.success,
                            fontWeight: FontWeight.w900,
                            fontSize: 8,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
        // Goal progress bar — only for goal-based, non-completed obligations
        if (goalData != null && !isDone)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainerLowest,
              borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(28)),
              border: Border.all(color: AppTheme.surfaceContainer),
              boxShadow: const [
                BoxShadow(
                    color: Color(0x08000000),
                    blurRadius: 6,
                    offset: Offset(0, 2))
              ],
            ),
            child: _goalProgressBar(goalData, ccy),
          ),
      ],
    );
  }

  Widget _goalProgressBar(Map<String, dynamic> goal, String currency) {
    final pct = (goal['progress_pct'] as num?)?.toInt() ?? 0;
    final goalAmt = (goal['goal_amount'] as num?)?.toDouble() ?? 0;
    final remitted = (goal['remitted_amount'] as num?)?.toDouble() ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Progress to ${Formatters.money(goalAmt, currency: currency)}',
              style: TextStyle(
                color: AppTheme.onSurfaceVariant.withValues(alpha: 0.5),
                fontWeight: FontWeight.w800,
                fontSize: 9,
                letterSpacing: 1.3,
              ),
            ),
            Text(
              '$pct%',
              style: TextStyle(
                color: AppTheme.onSurfaceVariant.withValues(alpha: 0.5),
                fontWeight: FontWeight.w900,
                fontSize: 9,
                letterSpacing: 1.3,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(
            value: (pct / 100).clamp(0.0, 1.0),
            minHeight: 6,
            backgroundColor: AppTheme.surfaceContainer,
            color: AppTheme.primary.withValues(alpha: 0.4),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${Formatters.money(remitted, currency: currency)} remitted',
          style: TextStyle(
            color: AppTheme.onSurfaceVariant.withValues(alpha: 0.4),
            fontWeight: FontWeight.w700,
            fontSize: 9,
          ),
        ),
      ],
    );
  }

  // ── Action handlers ─────────────────────────────────────────────────────────

  Future<void> _confirmResetCycle(
    BuildContext context,
    double surplus,
    String currency,
  ) async {
    final app = AppScope.of(context);
    final now = DateTime.now();
    final cycleMonth =
        '${now.year}-${now.month.toString().padLeft(2, '0')}';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Close this cycle?'),
        content: Text(
          surplus > 0
              ? '${Formatters.money(surplus, currency: currency)} surplus will be moved to savings.'
              : 'No surplus to save. All obligations will be reset for the new cycle.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Confirm')),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final result = await app.resetCycle(cycleMonth);
    if (!context.mounted) return;

    if (result.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.error!)),
      );
      return;
    }

    final hasSurplus = result.data?['savings_log_id'] != null;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          hasSurplus
              ? '✓ Cycle closed — surplus moved to savings.'
              : '✓ Cycle closed.',
        ),
        backgroundColor: AppTheme.success,
      ),
    );
  }

  Future<void> _showAddSavingsSheet(
      BuildContext context, String currency) async {
    final controller = TextEditingController();
    final app = AppScope.of(context);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final viewInsets = MediaQuery.of(ctx).viewInsets;
        return Padding(
          padding: EdgeInsets.only(bottom: viewInsets.bottom),
          child: Container(
            decoration: const BoxDecoration(
              color: AppTheme.surface,
              borderRadius:
                  BorderRadius.vertical(top: Radius.circular(36)),
            ),
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Add to Savings',
                        style: TextStyle(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w900,
                          fontSize: 24,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  'AMOUNT ($currency)',
                  style: const TextStyle(
                    color: AppTheme.onSurfaceVariant,
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: controller,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                  ),
                  decoration: const InputDecoration(hintText: '0.00'),
                ),
                const SizedBox(height: 8),
                Text(
                  'This will be deducted from your remaining balance.',
                  style: TextStyle(
                    color: AppTheme.onSurfaceVariant.withValues(alpha: 0.6),
                    fontStyle: FontStyle.italic,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      final amt =
                          double.tryParse(controller.text) ?? 0;
                      if (amt <= 0) {
                        Navigator.pop(ctx);
                        return;
                      }
                      await app.addSavings(
                        amount: amt,
                        currency: currency,
                        type: 'manual',
                        note: 'Manual savings from current balance',
                      );
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                    child: const Text('Confirm Savings'),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }
}
