import 'package:finpat_mobile/app/app_scope.dart';
import 'package:finpat_mobile/core/theme/app_theme.dart';
import 'package:finpat_mobile/core/theme/ui_tokens.dart';
import 'package:flutter/material.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _signupMode = false;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final app = AppScope.of(context);
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final name = _nameController.text.trim();
    if (email.isEmpty || password.length < 6 || (_signupMode && name.isEmpty)) {
      setState(() => _error = 'Please complete all required fields.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    final err = _signupMode
        ? await app.signUp(name, email, password)
        : await app.signIn(email, password);
    if (!mounted) return;
    setState(() {
      _error = err;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppTheme.primary,
                    borderRadius: BorderRadius.circular(UiTokens.radiusLg - 4),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x33004D60),
                        blurRadius: 20,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    'FP',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(height: UiTokens.sectionGap),
                Text(
                  _signupMode ? 'Create Account' : 'Welcome Back',
                  style: textTheme.displaySmall?.copyWith(color: AppTheme.primary, fontSize: UiTokens.titleSize),
                ),
                const SizedBox(height: 8),
                Text(
                  _signupMode
                      ? 'Start building your financial clarity today.'
                      : 'Your financial architect is ready to continue the journey.',
                  style: textTheme.bodyMedium?.copyWith(color: AppTheme.onSurfaceVariant),
                ),
                const SizedBox(height: 28),
                if (_signupMode) ...[
                  const _FieldLabel('FULL NAME'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _nameController,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(hintText: 'John Doe'),
                  ),
                  const SizedBox(height: 16),
                ],
                const _FieldLabel('EMAIL ADDRESS'),
                const SizedBox(height: 8),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(hintText: 'name@example.com', prefixIcon: Icon(Icons.mail_outline)),
                ),
                const SizedBox(height: 16),
                const _FieldLabel('PASSWORD'),
                const SizedBox(height: 8),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(hintText: '••••••••', prefixIcon: Icon(Icons.lock_outline)),
                ),
                const SizedBox(height: 16),
                if (_error != null)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.errorContainer,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                  ),
                ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  child: _loading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text(_signupMode ? 'Create Account' : 'Sign In'),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    const Expanded(child: Divider(color: AppTheme.surfaceContainer)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Text(
                        'OR CONTINUE WITH',
                        style: textTheme.labelSmall?.copyWith(
                          color: AppTheme.onSurfaceVariant.withValues(alpha: 0.7),
                          fontSize: 10,
                        ),
                      ),
                    ),
                    const Expanded(child: Divider(color: AppTheme.surfaceContainer)),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.tonal(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(56),
                      backgroundColor: AppTheme.surfaceContainer,
                      foregroundColor: AppTheme.onSurface,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(UiTokens.radiusMd)),
                    ),
                    onPressed: _loading ? null : _submit,
                    child: const Text('Google', style: TextStyle(fontWeight: FontWeight.w800)),
                  ),
                ),
                const SizedBox(height: 14),
                Center(
                  child: TextButton(
                    onPressed: _loading
                        ? null
                        : () => setState(() {
                              _signupMode = !_signupMode;
                              _error = null;
                            }),
                    child: Text(
                      _signupMode ? 'Already have an account? Sign In' : "Don't have an account? Sign Up",
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.4,
        color: AppTheme.onSurfaceVariant,
      ),
    );
  }
}
