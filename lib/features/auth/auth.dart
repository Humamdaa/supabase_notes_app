import 'package:supabase_flutter/supabase_flutter.dart';

class AuthSupa {
  final supaAuth = Supabase.instance.client.auth;

  signUp(String email, String password) async {
    final response = await supaAuth.signUp(email: email, password: password);
    return response;
  }

  login(String email, String password) async {
    final response = await supaAuth.signInWithPassword(
      email: email,
      password: password,
    );
    return response;
  }

  logout() async {
    await supaAuth.signOut();
  }
}
