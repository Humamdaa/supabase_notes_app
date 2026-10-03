import 'package:myapp/core/errors/app_exception.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/utils/safe_call.dart';

class DataNotes {
  final supa = Supabase.instance.client;

  // CREATE
  Future<Result<void>> create(String title, String content) {
    return safeCall<void>(() async {
      final user = supa.auth.currentUser;

      if (user == null) {
        throw const AppException('Please log in first.');
      }

      await supa.from('notes').insert({
        'title': title,
        'content': content,
        'user_id': user.id,
      });
    });
  }

  // READ
  Future<Result<List<Map<String, dynamic>>>> read() {
    return safeCall<List<Map<String, dynamic>>>(() async {
      final user = supa.auth.currentUser;

      if (user == null) {
        throw const AppException('Please log in first.');
      }

      final notes = await supa.from('notes').select().eq('user_id', user.id);

      return notes;
    });
  }

  // UPDATE
  Future<Result<void>> update(String id, String title, String content) {
    return safeCall<void>(() async {
      final user = supa.auth.currentUser;

      if (user == null) {
        throw const AppException('Please log in first.');
      }

      await supa
          .from('notes')
          .update({'title': title, 'content': content})
          .eq('id', id)
          .eq('user_id', user.id);
    });
  }

  // DELETE
  Future<Result<void>> delete(String id) {
    return safeCall<void>(() async {
      final user = supa.auth.currentUser;

      if (user == null) {
        throw const AppException('Please log in first.');
      }

      await supa.from('notes').delete().eq('id', id).eq('user_id', user.id);
    });
  }
}
