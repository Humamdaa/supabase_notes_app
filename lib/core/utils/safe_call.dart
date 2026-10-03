import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../errors/error_handler.dart';

class Result<T> {
  final T? data;
  final String? error;

  const Result._({this.data, this.error});

  factory Result.success(T data) {
    return Result._(data: data);
  }

  factory Result.failure(String message) {
    return Result._(error: message);
  }

  bool get isSuccess => error == null;
  bool get isFailure => !isSuccess;
}

Future<Result<T>> safeCall<T>(Future<T> Function() operation) async {
  try {
    final data = await operation();

    return Result.success(data);
  } catch (error, stackTrace) {
    // Print technical details only in debug mode.
    if (kDebugMode) {
      debugPrint('Original error: $error');

      if (error is PostgrestException) {
        debugPrint('Code: ${error.code}');
        debugPrint('Message: ${error.message}');
        debugPrint('Details: ${error.details}');
        debugPrint('Hint: ${error.hint}');
      }

      debugPrintStack(stackTrace: stackTrace);
    }

    return Result.failure(ErrorHandler.handle(error));
  }
}
