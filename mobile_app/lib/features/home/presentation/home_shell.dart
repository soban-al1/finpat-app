import 'package:finpat_mobile/app/app_scope.dart';
import 'package:finpat_mobile/core/theme/app_theme.dart';
import 'package:finpat_mobile/core/theme/ui_tokens.dart';
import 'package:finpat_mobile/features/centers/presentation/centers_screen.dart';
import 'package:finpat_mobile/features/dashboard/presentation/dashboard_screen.dart';
import 'package:finpat_mobile/features/finance/presentation/finance_screen.dart';
import 'package:finpat_mobile/features/forecast/presentation/forecast_screen.dart';
import 'package:finpat_mobile/features/settings/presentation/settings_screen.dart';
import 'package:flutter/material.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;
  bool _showSettings = false;

  static const _titles = ['Home', 'Commitments', 'Spent', 'Savings', 'Forecast'];

  final List<Widget> _screens = const [
    DashboardScreen(),
    CentersScreen(),
    FinanceScreen(initialTab: 0, showTabs: false),
    FinanceScreen(initialTab: 1, showTabs: false),
    ForecastScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, UiTokens.itemGap),
              child: Row(
                children: [
                  InkWell(
                    borderRadius: BorderRadius.circular(UiTokens.radiusPill),
                    onTap: () => setState(() => _showSettings = true),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(Icons.person_outline, color: AppTheme.primary),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _titles[_index],
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                color: AppTheme.primary,
                                fontSize: 30,
                              ),
                        ),
                        Text(
                          (AppScope.of(context).profile?['name'] ?? 'Architect').toString(),
                          style: const TextStyle(
                            color: AppTheme.onSurfaceVariant,
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppTheme.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      'FP',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      switchInCurve: Curves.easeOut,
                      switchOutCurve: Curves.easeIn,
                      child: KeyedSubtree(
                        key: ValueKey(_index),
                        child: _screens[_index],
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: IgnorePointer(
                      ignoring: !_showSettings,
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 180),
                        opacity: _showSettings ? 1 : 0,
                        child: GestureDetector(
                          onTap: () => setState(() => _showSettings = false),
                          child: Container(color: Colors.black.withValues(alpha: 0.18)),
                        ),
                      ),
                    ),
                  ),
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 260),
                    curve: Curves.easeOutCubic,
                    left: _showSettings ? 0 : -320,
                    top: 0,
                    bottom: 0,
                    child: Container(
                      width: 300,
                      height: double.infinity,
                      color: AppTheme.surface,
                      padding: const EdgeInsets.only(top: 20),
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: UiTokens.pagePadding),
                            child: Row(
                              children: [
                                const Expanded(
                                  child: Text(
                                    'Account',
                                    style: TextStyle(
                                      color: AppTheme.primary,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 22,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  onPressed: () => setState(() => _showSettings = false),
                                  icon: const Icon(Icons.close),
                                ),
                              ],
                            ),
                          ),
                          const Expanded(child: SettingsScreen()),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        height: 72,
        backgroundColor: AppTheme.surfaceContainerLowest,
        indicatorColor: AppTheme.primary.withValues(alpha: 0.15),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_tree_outlined),
            selectedIcon: Icon(Icons.account_tree),
            label: 'Commitments',
          ),
          NavigationDestination(
            icon: Icon(Icons.payments_outlined),
            selectedIcon: Icon(Icons.payments),
            label: 'Spent',
          ),
          NavigationDestination(
            icon: Icon(Icons.savings_outlined),
            selectedIcon: Icon(Icons.savings),
            label: 'Savings',
          ),
          NavigationDestination(
            icon: Icon(Icons.query_stats_outlined),
            selectedIcon: Icon(Icons.query_stats),
            label: 'Forecast',
          ),
        ],
      ),
    );
  }
}
