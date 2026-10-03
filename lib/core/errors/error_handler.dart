import 'dart:async';
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'app_exception.dart';

class ErrorHandler {
  static String handle(Object error) {
    if (error is AppException) {
      return error.message;
    }

    if (error is AuthException) {
      return _handleAuthException(error);
    }

    if (error is PostgrestException) {
      return _handleDatabaseException(error);
    }

    if (error is SocketException) {
      return 'No internet connection.';
    }

    if (error is TimeoutException) {
      return 'Connection timed out. Please try again.';
    }

    return 'Something went wrong. Please try again.';
  }

  static String _handleAuthException(AuthException error) {
    final message = error.message.toLowerCase();

    if (message.contains('invalid login credentials')) {
      return 'Email or password is incorrect.';
    }

    if (message.contains('user already registered')) {
      return 'This email is already registered.';
    }

    if (message.contains('email not confirmed')) {
      return 'Please confirm your email first.';
    }

    return error.message;
  }

  static String _handleDatabaseException(PostgrestException error) {
    switch (error.code) {
      case '23505':
        return 'This record already exists.';

      case '23503':
        return 'The referenced record does not exist.';

      case '23502':
        return 'A required field is missing.';

      case '42501':
        return 'You do not have permission to perform this action.';

      default:
        return 'Database operation failed. Please try again.';
    }
  }
}
