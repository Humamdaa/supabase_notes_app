import 'package:flutter/material.dart';
import 'package:myapp/features/data/note/note_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:myapp/features/auth/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");

  final supabaseUrl = dotenv.env['SUPABASE_URL'];
  final supabaseKey = dotenv.env['SUPABASE_KEY'];

  if (supabaseUrl == null || supabaseKey == null) {
    throw Exception('Supabase environment variables are missing');
  }

  await Supabase.initialize(url: supabaseUrl, publishableKey: supabaseKey);
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final authService = AuthService();
  final noteService = DataNotes();

  User? currentUser = Supabase.instance.client.auth.currentUser;
  String? noteId;

  Future<void> login() async {
    final result = await authService.login(
      email: "a@g.com",
      password: "12345678",
    );

    debugPrint(result.message);

    if (result.success && mounted) {
      setState(() {
        currentUser = Supabase.instance.client.auth.currentUser;
      });
    }
  }

  // CREATE
  Future<void> createNote() async {
    final result = await noteService.create("Test Title", "Test Content");

    if (result.isSuccess) {
      debugPrint("Note created successfully!");
    } else {
      debugPrint("Error: ${result.error}");
    }
  }

  // READ
  Future<void> readNotes() async {
    final result = await noteService.read();

    if (result.isSuccess) {
      final notes = result.data!;

      for (final note in notes) {
        debugPrint("ID: ${note['id']}");
        debugPrint("Title: ${note['title']}");
        debugPrint("Content: ${note['content']}");
        debugPrint("--------------------");
      }

      // Save the first note ID for testing update and delete.
      if (notes.isNotEmpty) {
        setState(() {
          noteId = notes.first['id'].toString();
        });
      }
    } else {
      debugPrint("Error: ${result.error}");
    }
  }

  // UPDATE
  Future<void> updateNote() async {
    if (noteId == null) {
      debugPrint("Read notes first to get a note ID.");
      return;
    }

    final result = await noteService.update(
      noteId!,
      "Updated Title",
      "Updated Content",
    );

    if (result.isSuccess) {
      debugPrint("Note updated successfully!");
    } else {
      debugPrint("Error: ${result.error}");
    }
  }

  // DELETE
  Future<void> deleteNote() async {
    if (noteId == null) {
      debugPrint("Read notes first to get a note ID.");
      return;
    }

    final result = await noteService.delete(noteId!);

    if (result.isSuccess) {
      debugPrint("Note deleted successfully!");

      setState(() {
        noteId = null;
      });
    } else {
      debugPrint("Error: ${result.error}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(currentUser?.email ?? "No user logged in"),

              const SizedBox(height: 20),

              ElevatedButton(onPressed: login, child: const Text("Login")),

              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: currentUser == null ? null : createNote,
                child: const Text("Create Note"),
              ),

              const SizedBox(height: 10),

              ElevatedButton(
                onPressed: currentUser == null ? null : readNotes,
                child: const Text("Read Notes"),
              ),

              const SizedBox(height: 10),

              ElevatedButton(
                onPressed: noteId == null ? null : updateNote,
                child: const Text("Update Note"),
              ),

              const SizedBox(height: 10),

              ElevatedButton(
                onPressed: noteId == null ? null : deleteNote,
                child: const Text("Delete Note"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
