/// Supabase connection details, supplied at build time.
///
/// Deliberately has no fallback values. A compiled-in default would mean a
/// build that forgot `--dart-define-from-file` silently talked to production,
/// and it would commit the project URL and anon key to the repo. With no
/// default the app shows [MissingConfigScreen] instead, which is the loud,
/// obvious failure we want.
///
/// Run and build with:
///   flutter run   --dart-define-from-file=.env.prod.json
///   flutter build appbundle --release --dart-define-from-file=.env.prod.json
class AppEnv {
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  static bool get _hasPlaceholderValues {
    final upperUrl = supabaseUrl.toUpperCase();
    final upperKey = supabaseAnonKey.toUpperCase();
    return upperUrl.contains('YOUR_URL') ||
        upperKey.contains('YOUR_KEY') ||
        upperUrl.contains('SUPABASE_URL') ||
        upperKey.contains('SUPABASE_ANON_KEY');
  }

  static bool get isConfigured =>
      supabaseUrl.isNotEmpty &&
      supabaseAnonKey.isNotEmpty &&
      !_hasPlaceholderValues;
}
