import 'package:supabase_flutter/supabase_flutter.dart';

class ErrorHandler {
  static String handle(Object error) {
    if (error is AuthException) {
      return _handleAuthException(error);
    }

    return 'Something went wrong. Please try again.';
  }

  static String _handleAuthException(AuthException error) {
    final message = error.message.toLowerCase();

    if (message.contains('invalid login credentials')) {
      return 'Email or password is incorrect';
    }

    if (message.contains('user already registered')) {
      return 'This email is already registered';
    }

    if (message.contains('email not confirmed')) {
      return 'Please confirm your email first';
    }

    if (message.contains('password')) {
      return 'Invalid password';
    }

    return error.message;
  }
}