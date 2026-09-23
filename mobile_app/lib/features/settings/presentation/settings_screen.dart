import 'package:finpat_mobile/app/app_scope.dart';
import 'package:finpat_mobile/app/app_state.dart';
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
        OutlinedButton.icon(
          onPressed: () => _deleteAccount(context, app),
          icon: const Icon(Icons.person_remove_outlined),
          label: const Text('Delete Account'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(56),
            foregroundColor: AppTheme.critical,
            side: const BorderSide(color: AppTheme.critical),
          ),
        ),
        const SizedBox(height: UiTokens.itemGap),
        const Text(
          'Deleting your account permanently erases your profile and all your '
          'centers, obligations, remittances, and savings.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppTheme.onSurfaceVariant,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: UiTokens.sectionGap),
        Text(
          userName,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 12, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }

  /// Two-step, irreversible. The typed confirmation is deliberate: unlike
  /// "Reset All Data" this also destroys the account itself.
  Future<void> _deleteAccount(BuildContext context, AppStateController app) async {
    final input = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setState) {
          final canDelete = input.text.trim().toUpperCase() == 'DELETE';
          return AlertDialog(
            title: const Text('Delete account?'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'This permanently erases your account, profile, centers, '
                  'obligations, remittances, and savings.\n\n'
                  'This cannot be undone.',
                ),
                const SizedBox(height: UiTokens.blockGap),
                const Text(
                  'Type DELETE to confirm',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                    color: AppTheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: UiTokens.itemGap),
                TextField(
                  controller: input,
                  autofocus: true,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(hintText: 'DELETE'),
                  onChanged: (_) => setState(() {}),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed:
                    canDelete ? () => Navigator.pop(dialogContext, true) : null,
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.critical,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Delete Account'),
              ),
            ],
          );
        },
      ),
    );
    input.dispose();
    if (confirmed != true || !context.mounted) return;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    final error = await app.deleteAccount();
    if (!context.mounted) return;
    Navigator.of(context, rootNavigator: true).pop(); // dismiss the spinner

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: AppTheme.critical),
      );
    }
    // On success the auth listener swaps the tree back to the sign-in screen.
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
