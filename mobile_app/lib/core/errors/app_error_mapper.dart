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
    if (error is FunctionException) {
      // Extract the actual message the edge function returned.
      final details = error.details;
      if (details is Map) {
        final msg = details['message'] ?? details['error'] ?? details['msg'];
        if (msg != null) return msg.toString();
      }
      if (details is String && details.isNotEmpty) return details;
      return 'Edge function error (HTTP ${error.reasonPhrase ?? "unknown"}).';
    }
    return 'Something went wrong. Please try again.';
  }
}
