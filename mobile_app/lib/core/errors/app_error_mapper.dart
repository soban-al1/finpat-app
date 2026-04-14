import 'package:supabase_flutter/supabase_flutter.dart';

class AppErrorMapper {
  static String toMessage(Object error) {
    if (error is AuthException) {
      final code = error.statusCode;
      if (code == '400' && error.message.toLowerCase().contains('invalid login')) {
        return 'Invalid login credentials.';
      }
      if (code == '429') {
        return 'Too many attempts. Please try again shortly.';
      }
      return error.message;
    }
    if (error is PostgrestException) {
      if (error.code == 'invalid_token') {
        return 'Your session expired. Please sign in again.';
      }
      return error.message;
    }
    return 'Something went wrong. Please try again.';
  }
}
