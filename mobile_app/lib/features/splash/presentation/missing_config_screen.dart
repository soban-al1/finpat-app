import 'package:flutter/material.dart';

class MissingConfigScreen extends StatelessWidget {
  const MissingConfigScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('FinPat Setup')),
      body: const Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          'Missing SUPABASE_URL and/or SUPABASE_ANON_KEY.\n\n'
          'Run with:\n'
          'flutter run --dart-define=SUPABASE_URL=... '
          '--dart-define=SUPABASE_ANON_KEY=...',
        ),
      ),
    );
  }
}
