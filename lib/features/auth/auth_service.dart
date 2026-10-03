import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/error_handler.dart';
import '../../../core/validators/auth_validator.dart';
import 'models/auth_result.dart';

class AuthService {
  final GoTrueClient _auth;

  AuthService({GoTrueClient? auth})
    : _auth = auth ?? Supabase.instance.client.auth;

  Future<AuthResult> signUp({
    required String email,
    required String password,
  }) async {
    final emailError = AuthValidator.validateEmail(email);

    if (emailError != null) {
      return AuthResult.failure(emailError);
    }

    final passwordError = AuthValidator.validatePassword(password);

    if (passwordError != null) {
      return AuthResult.failure(passwordError);
    }

    try {
      await _auth.signUp(email: email.trim(), password: password);

      return AuthResult.success('Account created successfully');
    } catch (error) {
      return AuthResult.failure(ErrorHandler.handle(error));
    }
  }

  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    final emailError = AuthValidator.validateEmail(email);

    if (emailError != null) {
      return AuthResult.failure(emailError);
    }

    final passwordError = AuthValidator.validatePassword(password);

    if (passwordError != null) {
      return AuthResult.failure(passwordError);
    }

    try {
      await _auth.signInWithPassword(email: email.trim(), password: password);

      return AuthResult.success('Logged in successfully');
    } catch (error) {
      return AuthResult.failure(ErrorHandler.handle(error));
    }
  }

  Future<AuthResult> logout() async {
    try {
      await _auth.signOut();

      return AuthResult.success('Logged out successfully');
    } catch (error) {
      return AuthResult.failure(ErrorHandler.handle(error));
    }
  }

  User? get currentUser => _auth.currentUser;

  bool get isLoggedIn => currentUser != null;
}
