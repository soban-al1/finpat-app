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
