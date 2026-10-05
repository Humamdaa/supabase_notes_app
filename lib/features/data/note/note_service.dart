import 'dart:io';

import 'package:myapp/core/errors/app_exception.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/utils/safe_call.dart';

import 'package:uuid/uuid.dart';

class DataNotes {
  final supa = Supabase.instance.client;

  // CREATE  (now accepts an optional image path)
  Future<Result<void>> create(
    String title,
    String content, {
    String? imagePath,
  }) {
    return safeCall<void>(() async {
      final user = supa.auth.currentUser;

      if (user == null) {
        throw const AppException('Please log in first.');
      }

      await supa.from('notes').insert({
        'title': title,
        'content': content,
        'image_path': imagePath,
        'user_id': user.id,
      });
    });
  }

  // READ  (newest first)
  Future<Result<List<Map<String, dynamic>>>> read() {
    return safeCall<List<Map<String, dynamic>>>(() async {
      final user = supa.auth.currentUser;

      if (user == null) {
        throw const AppException('Please log in first.');
      }

      final notes = await supa
          .from('notes')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      return notes;
    });
  }

  // UPDATE  (pass imagePath = null to remove the image)
  Future<Result<void>> update(
    String id,
    String title,
    String content, {
    String? imagePath,
  }) {
    return safeCall<void>(() async {
      final user = supa.auth.currentUser;

      if (user == null) {
        throw const AppException('Please log in first.');
      }

      await supa
          .from('notes')
          .update({
            'title': title,
            'content': content,
            'image_path': imagePath,
          })
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

  // UPLOAD IMAGE
  Future<Result<String>> uploadImage(File file) {
    return safeCall<String>(() async {
      final user = supa.auth.currentUser;

      if (user == null) {
        throw const AppException('Please log in first.');
      }

      final uuid = const Uuid().v4();
      final ext = file.path.split('.').last.toLowerCase();

      final path = '${user.id}/$uuid.$ext';

      await supa.storage.from('notes').upload(path, file);

      return path;
    });
  }

  // DELETE IMAGE (new: cleans up storage when a note/image is removed)
  Future<Result<void>> deleteImage(String imagePath) {
    return safeCall<void>(() async {
      await supa.storage.from('notes').remove([imagePath]);
    });
  }

  String getImageUrl(String imagePath) {
    return supa.storage.from('notes').getPublicUrl(imagePath);
  }
}