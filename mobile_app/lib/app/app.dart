import 'dart:async';

import 'package:finpat_mobile/app/app_scope.dart';
import 'package:finpat_mobile/app/app_state.dart';
import 'package:finpat_mobile/core/theme/app_theme.dart';
import 'package:finpat_mobile/features/auth/presentation/sign_in_screen.dart';
import 'package:finpat_mobile/features/home/presentation/home_shell.dart';
import 'package:finpat_mobile/features/onboarding/presentation/onboarding_screen.dart';
import 'package:finpat_mobile/features/splash/presentation/missing_config_screen.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FinPatApp extends StatelessWidget {
  const FinPatApp({super.key, required this.isConfigured});

  final bool isConfigured;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'FinPat',
      theme: AppTheme.buildTheme(),
      home: isConfigured ? const AuthGate() : const MissingConfigScreen(),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late final AppStateController _controller;
  StreamSubscription<AuthState>? _authSubscription;

  @override
  void initState() {
    super.initState();
    _controller = AppStateController(Supabase.instance.client);
    _controller.bootstrap();
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((_) {
      _controller.bootstrap();
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScope(
      controller: _controller,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          if (_controller.initializing) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          if (!_controller.isLoggedIn) {
            return const SignInScreen();
          }
          if (!_controller.isOnboarded) {
            return const OnboardingScreen();
          }
          return const HomeShell();
        },
      ),
    );
  }
}
