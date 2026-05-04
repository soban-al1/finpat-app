import 'package:finpat_mobile/app/app_scope.dart';
import 'package:finpat_mobile/app/app_state.dart';
import 'package:finpat_mobile/core/theme/app_theme.dart';
import 'package:finpat_mobile/core/theme/ui_tokens.dart';
import 'package:finpat_mobile/core/utils/currency.dart';
import 'package:finpat_mobile/core/utils/formatters.dart';
import 'package:flutter/material.dart';

// ── Currency data (mirrors onboarding) ──────────────────────────────────────
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

// ── Theme colors for new center (matching mock palette) ──────────────────────
const List<Color> _centerColors = [
  Color(0xFF004D60),
  Color(0xFFBA1A1A),
  Color(0xFF005049),
  Color(0xFF526772),
  Color(0xFF00677F),
];

String _colorToHex(Color c) {
  final r = ((c.value >> 16) & 0xFF).toRadixString(16).padLeft(2, '0');
  final g = ((c.value >> 8) & 0xFF).toRadixString(16).padLeft(2, '0');
  final b = (c.value & 0xFF).toRadixString(16).padLeft(2, '0');
  return '#$r$g$b'.toUpperCase();
}

Color _fromHex(String hex) {
  final value = hex.replaceAll('#', '');
  if (value.length == 6) {
    return Color(int.parse('FF$value', radix: 16));
  }
  return AppTheme.primary;
}

// ═══════════════════════════════════════════════════════════════════════════════
// MAIN SCREEN
// ═══════════════════════════════════════════════════════════════════════════════
class CentersScreen extends StatefulWidget {
  const CentersScreen({super.key});

  @override
  State<CentersScreen> createState() => _CentersScreenState();
}

class _CentersScreenState extends State<CentersScreen> {
  /// Opens the full 2-step wizard (creates center then obligation).
  /// We pass [app] explicitly because modal routes can't access AppScope.
  Future<void> _openNewCenterWizard() async {
    final app = AppScope.of(context);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CenterWizardSheet(app: app, initialCenterId: null),
    );
    if (mounted) setState(() {}); // rebuild after data changes
  }

  /// Opens directly at obligation step for an existing center.
  Future<void> _openAddObligationSheet(String centerId) async {
    final app = AppScope.of(context);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          _CenterWizardSheet(app: app, initialCenterId: centerId),
    );
    if (mounted) setState(() {});
  }

  Future<void> _toggleCompletion(Map<String, dynamic> item) async {
    final app = AppScope.of(context);
    final isCompleted = item['is_completed'] == true;
    final err = await app.toggleObligation(
      obligationId: item['id'] as String,
      isCompleted: !isCompleted,
    );
    if (err != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err), backgroundColor: AppTheme.critical),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final centers = app.centers;
    final obligations = app.obligations;
    final incomeCurrency =
        (app.profile?['income_currency'] as String?)?.toUpperCase() ?? 'USD';

    if (app.loading && centers.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        UiTokens.pagePadding, 8, UiTokens.pagePadding, 120,
      ),
      children: [
        // ── Page header ─────────────────────────────────────────────────────
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Commitments',
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.primary,
                      letterSpacing: -0.6,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Manage your financial responsibilities and goals.',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.onSurfaceVariant.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: _openNewCenterWizard,
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: const [UiTokens.heroShadow],
                ),
                child: const Icon(
                    Icons.add_rounded, color: Colors.white, size: 28),
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),

        // ── Empty state ─────────────────────────────────────────────────────
        if (centers.isEmpty)
          GestureDetector(
            onTap: _openNewCenterWizard,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 56),
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(UiTokens.radiusLg),
                border: Border.all(color: AppTheme.surfaceContainer, width: 1.5),
              ),
              child: Column(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceContainer,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(
                      Icons.add_rounded, size: 28,
                      color: AppTheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'NO CENTERS YET',
                    style: TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w900,
                      color: AppTheme.onSurfaceVariant.withValues(alpha: 0.5),
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Tap to add your first responsibility center',
                    style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w500,
                      color: AppTheme.onSurfaceVariant.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
          ),

        // ── Center cards ────────────────────────────────────────────────────
        ...centers.map((center) {
          final centerColor =
              _fromHex(center['color'] as String? ?? '#004D60');
          final centerObligations = obligations
              .where((o) => o['center_id'] == center['id'])
              .toList();

          final totalInBase = centerObligations.fold<double>(
            0,
            (acc, o) =>
                acc +
                Currency.convert(
                  (o['amount'] as num).toDouble(),
                  (o['currency'] as String?) ?? 'USD',
                  incomeCurrency,
                ),
          );

          return Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(UiTokens.radiusXl),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Colored top accent stripe ───────────────────────────
                  Container(height: 5, color: centerColor),

                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Center header row ─────────────────────────────
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Icon — 60×60 rounded-[20]
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: centerColor,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: centerColor.withValues(alpha: 0.35),
                                    blurRadius: 14,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.track_changes_rounded,
                                color: Colors.white,
                                size: 30,
                              ),
                            ),
                            const SizedBox(width: 16),
                            // Name + subtitle
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    center['name'] as String? ?? 'Center',
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w900,
                                      color: AppTheme.primary,
                                      letterSpacing: -0.3,
                                      height: 1.15,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'RESPONSIBILITY CENTER',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: AppTheme.onSurfaceVariant
                                          .withValues(alpha: 0.42),
                                      letterSpacing: 1.6,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // "+" button — 42×42 rounded-[14]
                            GestureDetector(
                              onTap: () => _openAddObligationSheet(
                                  center['id'] as String),
                              child: Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: AppTheme.surfaceContainer
                                      .withValues(alpha: 0.7),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Icon(
                                  Icons.add_rounded,
                                  size: 22,
                                  color: AppTheme.primary
                                      .withValues(alpha: 0.65),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // ── Obligations ───────────────────────────────────
                        if (centerObligations.isEmpty)
                          _EmptyObligationsButton(
                            onTap: () => _openAddObligationSheet(
                                center['id'] as String),
                          )
                        else
                          ...centerObligations.map((item) {
                            final oblId = item['id'] as String?;
                            final goalAmt = (item['goal_amount'] as num?)?.toDouble();
                            final paid = oblId == null
                                ? 0.0
                                : app.remittances
                                    .where((r) => r['obligation_id'] == oblId)
                                    .fold<double>(
                                      0,
                                      (acc, r) =>
                                          acc +
                                          ((r['amount'] as num?)?.toDouble() ??
                                              0),
                                    );
                            return _ObligationCard(
                              item: item,
                              incomeCurrency: incomeCurrency,
                              onToggle: () => _toggleCompletion(item),
                              goalAmount: goalAmt,
                              totalPaid: paid,
                            );
                          }),

                        const SizedBox(height: 8),
                      ],
                    ),
                  ),

                  // ── Monthly Impact footer ───────────────────────────────
                  Container(
                    margin: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                    padding: const EdgeInsets.fromLTRB(0, 18, 0, 0),
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(
                          color:
                              AppTheme.surfaceContainer.withValues(alpha: 0.6),
                          width: 1,
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'MONTHLY IMPACT',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                color: AppTheme.onSurfaceVariant
                                    .withValues(alpha: 0.38),
                                letterSpacing: 1.8,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Converted to $incomeCurrency',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color:
                                    AppTheme.primary.withValues(alpha: 0.42),
                              ),
                            ),
                          ],
                        ),
                        Text(
                          Formatters.money(totalInBase,
                              currency: incomeCurrency),
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.primary,
                            letterSpacing: -1.0,
                          ),
                        ),
                      ],
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
}

// ═══════════════════════════════════════════════════════════════════════════════
// OBLIGATION CARD — visible container with rounded border (matches screenshot)
// ═══════════════════════════════════════════════════════════════════════════════
class _ObligationCard extends StatelessWidget {
  const _ObligationCard({
    required this.item,
    required this.incomeCurrency,
    required this.onToggle,
    this.goalAmount,
    this.totalPaid = 0,
  });

  final Map<String, dynamic> item;
  final String incomeCurrency;
  final VoidCallback onToggle;
  final double? goalAmount;
  final double totalPaid;

  @override
  Widget build(BuildContext context) {
    final isCompleted = item['is_completed'] == true;
    final currency = (item['currency'] as String?) ?? 'USD';
    final amount = (item['amount'] as num?)?.toDouble() ?? 0;
    final type = (item['type'] as String?) ?? 'monthly';
    final isEssential = (item['is_essential'] as bool?) ?? true;
    final dueDate = item['due_date'] as String?;

    final amountInBase = Currency.convert(amount, currency, incomeCurrency);
    final showConversion = currency.toUpperCase() != incomeCurrency;

    final hasGoal = goalAmount != null && goalAmount! > 0;
    final progress = hasGoal ? (totalPaid / goalAmount! * 100).clamp(0.0, 100.0) : 0.0;

    return Opacity(
      opacity: isCompleted ? 0.5 : 1.0,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: AppTheme.surfaceContainer.withValues(alpha: 0.6),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Main row: toggle + title/tags + amount ────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Toggle circle — 36×36 ───────────────────────
                GestureDetector(
                  onTap: onToggle,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isCompleted
                          ? AppTheme.success
                          : AppTheme.surfaceContainer,
                    ),
                    child: isCompleted
                        ? const Icon(Icons.check_rounded,
                            size: 18, color: Colors.white)
                        : Center(
                            child: Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppTheme.onSurfaceVariant
                                    .withValues(alpha: 0.18),
                              ),
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 12),

                // ── Title + badges (title on its own line) ───────
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title — full width, wraps cleanly
                      Text(
                        item['title'] as String? ?? 'Untitled',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.onSurface,
                          letterSpacing: -0.2,
                          height: 1.2,
                          decoration: isCompleted
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                      const SizedBox(height: 6),
                      // Badges row — all on one line, wraps if needed
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Icon(
                              type == 'monthly'
                                  ? Icons.sync_rounded
                                  : Icons.calendar_today_rounded,
                              size: 14,
                              color: AppTheme.primary.withValues(alpha: 0.42),
                            ),
                          ),
                          if (isEssential)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppTheme.critical.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(99),
                              ),
                              child: const Text(
                                'ESSENTIAL',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                  color: AppTheme.critical,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceContainer,
                              borderRadius: BorderRadius.circular(99),
                            ),
                            child: Text(
                              type.toUpperCase(),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.onSurfaceVariant
                                    .withValues(alpha: 0.48),
                                letterSpacing: 1.0,
                              ),
                            ),
                          ),
                          if (dueDate != null)
                            Text(
                              '· Due $dueDate',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.critical.withValues(alpha: 0.7),
                                letterSpacing: 0.5,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 10),

                // ── Amount ───────────────────────────────────────
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      Formatters.money(amount, currency: currency),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.primary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    if (showConversion)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          '≈ ${Formatters.money(amountInBase, currency: incomeCurrency)}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.onSurfaceVariant
                                .withValues(alpha: 0.42),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),

            // ── Settlement Goal section ───────────────────────────
            if (hasGoal) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceContainerLow.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppTheme.surfaceContainer.withValues(alpha: 0.5),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header: label + % badge
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'SETTLEMENT GOAL',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.onSurfaceVariant
                                .withValues(alpha: 0.4),
                            letterSpacing: 1.2,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: progress >= 100
                                ? AppTheme.success.withValues(alpha: 0.15)
                                : AppTheme.surfaceContainer,
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: Text(
                            progress >= 100
                                ? '✓ Complete'
                                : '${progress.round()}%',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              color: progress >= 100
                                  ? AppTheme.success
                                  : AppTheme.onSurfaceVariant
                                      .withValues(alpha: 0.5),
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Paid so far ↔ Goal
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Paid so far',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.onSurfaceVariant
                                    .withValues(alpha: 0.4),
                              ),
                            ),
                            Text(
                              Formatters.money(totalPaid, currency: currency),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                                color: AppTheme.success,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Goal',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.onSurfaceVariant
                                    .withValues(alpha: 0.4),
                              ),
                            ),
                            Text(
                              Formatters.money(goalAmount!, currency: currency),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Progress bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(99),
                      child: LinearProgressIndicator(
                        value: progress / 100,
                        minHeight: 6,
                        backgroundColor: AppTheme.surfaceContainer,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          progress >= 100
                              ? AppTheme.success
                              : AppTheme.primary.withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Empty obligations placeholder ─────────────────────────────────────────────
class _EmptyObligationsButton extends StatelessWidget {
  const _EmptyObligationsButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 40),
        decoration: BoxDecoration(
          color: AppTheme.surfaceContainerLow.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: AppTheme.surfaceContainer,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.add_rounded, size: 32,
                color: AppTheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'NO ACTIVE COMMITMENTS',
              style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.w900,
                color: AppTheme.onSurfaceVariant.withValues(alpha: 0.4),
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Tap to add your first commitment',
              style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w500,
                color: AppTheme.onSurfaceVariant.withValues(alpha: 0.35),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// 2-STEP WIZARD BOTTOM SHEET
//
// Receives [app] (AppStateController) explicitly because modal bottom sheets
// live in a separate route and cannot access InheritedWidgets from the parent.
// ═══════════════════════════════════════════════════════════════════════════════
class _CenterWizardSheet extends StatefulWidget {
  const _CenterWizardSheet({required this.app, this.initialCenterId});

  final AppStateController app;
  final String? initialCenterId;

  @override
  State<_CenterWizardSheet> createState() => _CenterWizardSheetState();
}

class _CenterWizardSheetState extends State<_CenterWizardSheet> {
  late int _step;
  String? _createdCenterId;

  // Step 0 – Center
  final _nameController = TextEditingController();
  Color _selectedColor = _centerColors[0];

  // Step 1 – Obligation
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _goalAmountController = TextEditingController();
  String _currency = 'USD';
  String _type = 'monthly';
  bool _hasGoal = false;

  bool _saving = false;
  String? _error;

  AppStateController get _app => widget.app;

  @override
  void initState() {
    super.initState();
    if (widget.initialCenterId != null) {
      _step = 1;
      _createdCenterId = widget.initialCenterId;
    } else {
      _step = 0;
    }
    // Default currency to user's income currency
    final userCurrency =
        (_app.profile?['income_currency'] as String?)?.toUpperCase();
    if (userCurrency != null) _currency = userCurrency;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _titleController.dispose();
    _amountController.dispose();
    _goalAmountController.dispose();
    super.dispose();
  }

  // ── Step 0 → 1: create center, then advance ──────────────────────────────
  Future<void> _handleNextStep() async {
    if (_nameController.text.trim().isEmpty) return;

    setState(() {
      _saving = true;
      _error = null;
    });

    final hexColor = _colorToHex(_selectedColor);
    final err = await _app.addCenter(
      name: _nameController.text.trim(),
      color: hexColor,
    );

    if (!mounted) return;

    if (err != null) {
      setState(() { _saving = false; _error = err; });
      return;
    }

    // Centers are ordered by created_at ASC, so the newest is last.
    final newCenter = _app.centers.lastWhere(
      (c) => c['name'] == _nameController.text.trim(),
      orElse: () => _app.centers.last,
    );

    setState(() {
      _saving = false;
      _createdCenterId = newCenter['id'] as String;
      _step = 1;
    });
  }

  // ── Step 1: save obligation ───────────────────────────────────────────────
  Future<void> _handleSaveObligation({bool addAnother = false}) async {
    if (_titleController.text.trim().isEmpty) return;
    if (_createdCenterId == null) return;

    final amount = double.tryParse(_amountController.text.trim()) ?? 0;
    final goalAmount =
        _hasGoal ? (double.tryParse(_goalAmountController.text.trim())) : null;

    setState(() {
      _saving = true;
      _error = null;
    });

    final err = await _app.addObligation(
      centerId: _createdCenterId!,
      title: _titleController.text.trim(),
      amount: amount,
      currency: _currency,
      type: _type,
      goalAmount: goalAmount,
    );

    if (!mounted) return;

    if (err != null) {
      setState(() { _saving = false; _error = err; });
      return;
    }

    setState(() => _saving = false);

    if (addAnother) {
      _titleController.clear();
      _amountController.clear();
      _goalAmountController.clear();
      setState(() {
        _type = 'monthly';
        _hasGoal = false;
        _error = null;
      });
    } else {
      if (mounted) Navigator.pop(context);
    }
  }

  // ── Currency picker (mirrors onboarding) ──────────────────────────────────
  Future<void> _openCurrencyPicker() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      backgroundColor: AppTheme.surface,
      builder: (ctx) => SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            const Text(
              'Select country / currency',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            ..._currencies.map((c) {
              final isSelected = c.code == _currency;
              return ListTile(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                tileColor: isSelected
                    ? AppTheme.primary.withValues(alpha: 0.08)
                    : null,
                leading:
                    Text(c.flag, style: const TextStyle(fontSize: 20)),
                title: Text(c.code,
                    style: const TextStyle(fontWeight: FontWeight.w800)),
                trailing: isSelected
                    ? const Icon(Icons.check_rounded,
                        color: AppTheme.primary)
                    : null,
                onTap: () => Navigator.pop(ctx, c.code),
              );
            }),
          ],
        ),
      ),
    );

    if (selected != null && mounted) {
      setState(() => _currency = selected);
    }
  }

  // ── Main build ────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(UiTokens.radiusXl)),
      ),
      padding: EdgeInsets.fromLTRB(24, 12, 24, bottomInset + 28),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Wizard header
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _step == 0 ? 'New Center' : 'Add\nCommitment',
                        style: const TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.primary,
                          letterSpacing: -0.5,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 9, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(99),
                            ),
                            child: Text(
                              'STEP ${_step + 1}/2',
                              style: const TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                color: AppTheme.primary,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _step == 0
                                ? 'DEFINE RESPONSIBILITY'
                                : 'SET THE DETAILS',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.onSurfaceVariant
                                  .withValues(alpha: 0.5),
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceContainer,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.close_rounded,
                        size: 20, color: AppTheme.onSurfaceVariant),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 28),

            // Error banner
            if (_error != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppTheme.errorContainer,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(_error!,
                    style: const TextStyle(
                        color: AppTheme.critical,
                        fontWeight: FontWeight.w600)),
              ),
            ],

            if (_step == 0) _buildStep0() else _buildStep1(),
          ],
        ),
      ),
    );
  }

  // ── Step 0: New Center ────────────────────────────────────────────────────
  Widget _buildStep0() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _WizardLabel('CENTER NAME'),
        const SizedBox(height: 8),
        TextField(
          controller: _nameController,
          textCapitalization: TextCapitalization.words,
          decoration:
              const InputDecoration(hintText: "e.g. Parents' Support"),
        ),

        const SizedBox(height: 24),

        const _WizardLabel('THEME COLOR'),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.surfaceContainer,
            borderRadius: BorderRadius.circular(UiTokens.radiusMd),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: _centerColors.map((c) {
              final isSelected = _selectedColor == c;
              return GestureDetector(
                onTap: () => setState(() => _selectedColor = c),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 52, height: 52,
                  decoration: BoxDecoration(
                    color: c,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: c.withValues(alpha: 0.5),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            )
                          ]
                        : null,
                    border: isSelected
                        ? Border.all(color: Colors.white, width: 3)
                        : null,
                  ),
                  child: isSelected
                      ? const Icon(Icons.add_rounded,
                          color: Colors.white, size: 22)
                      : const SizedBox.shrink(),
                ),
              );
            }).toList(),
          ),
        ),

        const SizedBox(height: 36),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _saving ? null : _handleNextStep,
            child: _saving
                ? const SizedBox(
                    width: 18, height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Next: Add Commitments'),
                      SizedBox(width: 8),
                      Icon(Icons.chevron_right_rounded, color: Colors.white),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  // ── Step 1: Add Commitment ────────────────────────────────────────────────
  Widget _buildStep1() {
    final currencyOption = _currencies.firstWhere(
      (c) => c.code == _currency,
      orElse: () => const _CurrencyOption('USD', '🇺🇸'),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _WizardLabel('TITLE'),
        const SizedBox(height: 8),
        TextField(
          controller: _titleController,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(hintText: 'e.g. Monthly Rent'),
        ),

        const SizedBox(height: 20),

        const _WizardLabel('TYPE'),
        const SizedBox(height: 8),
        Row(
          children: [
            _TypePill(
              label: 'Monthly',
              selected: _type == 'monthly',
              onTap: () => setState(() => _type = 'monthly'),
            ),
            const SizedBox(width: 10),
            _TypePill(
              label: 'One-time',
              selected: _type == 'one-time',
              onTap: () => setState(() => _type = 'one-time'),
            ),
          ],
        ),

        const SizedBox(height: 20),

        // Amount + Currency
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _WizardLabel(
                    _type == 'monthly' ? 'MONTHLY AMOUNT' : 'TOTAL AMOUNT',
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _amountController,
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.primary,
                    ),
                    decoration: const InputDecoration(hintText: '0'),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _WizardLabel('CURRENCY'),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: _openCurrencyPicker,
                  child: Container(
                    height: 58,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceContainer,
                      borderRadius:
                          BorderRadius.circular(UiTokens.radiusMd),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(currencyOption.flag,
                            style: const TextStyle(fontSize: 20)),
                        const SizedBox(width: 6),
                        Text(
                          _currency,
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                            color: AppTheme.primary,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: 20,
                          color: AppTheme.onSurfaceVariant,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),

        const SizedBox(height: 20),

        // Settlement Goal toggle
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppTheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(UiTokens.radiusMd),
            border: Border.all(color: AppTheme.surfaceContainer, width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'SETTLEMENT GOAL',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.primary,
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Track progress towards a total amount',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.onSurfaceVariant
                                .withValues(alpha: 0.65),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _hasGoal,
                    onChanged: (v) => setState(() => _hasGoal = v),
                    activeColor: AppTheme.primary,
                  ),
                ],
              ),
              if (_hasGoal) ...[
                const SizedBox(height: 14),
                TextField(
                  controller: _goalAmountController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    hintText: 'e.g. 50 000',
                    suffixText: _currency,
                    suffixStyle: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppTheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 28),

        // Action buttons
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _saving ? null : () => _handleSaveObligation(),
            child: _saving
                ? const SizedBox(
                    width: 18, height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Finish & Save'),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed:
                _saving ? null : () => _handleSaveObligation(addAnother: true),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(54),
              backgroundColor: AppTheme.surfaceContainer,
              side: BorderSide.none,
              shape: const StadiumBorder(),
              foregroundColor: AppTheme.primary,
            ),
            child: const Text(
              'Save & Add Another',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Type pill button ─────────────────────────────────────────────────────────
class _TypePill extends StatelessWidget {
  const _TypePill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primary : AppTheme.surfaceContainer,
          borderRadius: BorderRadius.circular(UiTokens.radiusMd),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: selected ? Colors.white : AppTheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

// ─── Label widget used inside the wizard ─────────────────────────────────────
class _WizardLabel extends StatelessWidget {
  const _WizardLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w900,
        color: AppTheme.onSurfaceVariant.withValues(alpha: 0.6),
        letterSpacing: 1.3,
      ),
    );
  }
}
