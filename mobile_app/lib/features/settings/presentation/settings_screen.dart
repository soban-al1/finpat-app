import 'package:finpat_mobile/app/app_scope.dart';
import 'package:finpat_mobile/core/theme/app_theme.dart';
import 'package:finpat_mobile/core/theme/ui_tokens.dart';
import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final workLocation = (app.profile?['work_location'] ?? 'Not set').toString();
    final salaryCurrency = (app.profile?['income_currency'] ?? 'USD').toString();
    final userName = (app.profile?['name'] ?? app.currentUser?.email ?? 'User').toString();
    return ListView(
      padding: const EdgeInsets.fromLTRB(UiTokens.pagePadding, 0, UiTokens.pagePadding, 16),
      children: [
        Text(
          'Settings',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: AppTheme.primary),
        ),
        const SizedBox(height: UiTokens.itemGap),
        const Text(
          'Manage your profile and app preferences.',
          style: TextStyle(color: AppTheme.onSurfaceVariant, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: UiTokens.sectionGap),
        _sectionLabel('PROFILE & ACCOUNT'),
        _itemCard(
          icon: Icons.person_outline,
          title: 'Personal Info',
          subtitle: 'Working in $workLocation',
        ),
        const SizedBox(height: UiTokens.itemGap),
        _itemCard(
          icon: Icons.public_outlined,
          title: 'Salary Currency',
          subtitle: salaryCurrency,
        ),
        const SizedBox(height: UiTokens.sectionGap),
        _sectionLabel('ACTIONS'),
        const SizedBox(height: UiTokens.itemGap),
        FilledButton.tonalIcon(
          onPressed: () => app.signOut(),
          icon: const Icon(Icons.logout_rounded),
          label: const Text('Sign Out'),
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(56),
            backgroundColor: AppTheme.surfaceContainer,
            foregroundColor: AppTheme.onSurface,
          ),
        ),
        const SizedBox(height: UiTokens.itemGap),
        FilledButton.tonalIcon(
          onPressed: () async {
            final ok = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Reset all data?'),
                content: const Text('This removes centers, obligations, remittances, and savings.'),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                  FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Reset')),
                ],
              ),
            );
            if (ok != true) return;
            await app.resetAllData();
          },
          icon: const Icon(Icons.delete_outline),
          label: const Text('Reset All Data'),
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(56),
            backgroundColor: AppTheme.errorContainer,
            foregroundColor: AppTheme.critical,
          ),
        ),
        const SizedBox(height: UiTokens.itemGap),
        Text(
          userName,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 12, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.4,
          color: AppTheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _itemCard({required IconData icon, required String title, required String subtitle}) {
    return Card(
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppTheme.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(UiTokens.radiusSm),
          ),
          child: Icon(icon, color: AppTheme.primary),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Text(
          subtitle.toUpperCase(),
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.1),
        ),
      ),
    );
  }
}
