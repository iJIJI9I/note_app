import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import 'features/auth/presentation/screens/auth_screen.dart';
import 'features/notes/presentation/screens/notes_list_screen.dart';
import 'firebase_options.dart';

const _background = Color(0xFFF7F5F0);
const _surface = Color(0xFFFFFEFB);
const _primary = Color(0xFF315C4B);
const _ink = Color(0xFF242923);

Future<FirebaseApp> _initializeFirebase() async {
  final app = Firebase.apps.isNotEmpty
      ? Firebase.app()
      : await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );

  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  return app;
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(NotesApp(firebaseInitialization: _initializeFirebase()));
}

class NotesApp extends StatelessWidget {
  const NotesApp({required this.firebaseInitialization, super.key});

  final Future<FirebaseApp> firebaseInitialization;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Notes',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: _background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _primary,
          primary: _primary,
          surface: _surface,
          onSurface: _ink,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: _background,
          foregroundColor: _ink,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            color: _ink,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: _surface,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFE9E6DE)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: _primary, width: 1.5),
          ),
        ),
        cardTheme: CardThemeData(
          color: _surface,
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Color(0xFFECE9E1)),
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: _primary,
          foregroundColor: Colors.white,
          elevation: 3,
        ),
      ),
      home: FirebaseStartupGate(initialization: firebaseInitialization),
    );
  }
}

class FirebaseStartupGate extends StatefulWidget {
  const FirebaseStartupGate({required this.initialization, super.key});

  final Future<FirebaseApp> initialization;

  @override
  State<FirebaseStartupGate> createState() => _FirebaseStartupGateState();
}

class _FirebaseStartupGateState extends State<FirebaseStartupGate> {
  late Future<FirebaseApp> _initialization = widget.initialization;

  void _retryInitialization() {
    setState(() => _initialization = _initializeFirebase());
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<FirebaseApp>(
      future: _initialization,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _StartupMessage(
            icon: LucideIcons.cloud_off,
            title: 'Connection failed',
            message: 'Check your connection and try launching the app again.',
            actionLabel: 'Try again',
            onAction: _retryInitialization,
          );
        }

        if (snapshot.connectionState != ConnectionState.done) {
          return const _StartupMessage(
            icon: LucideIcons.notebook_pen,
            title: 'Notes',
            message: 'Preparing your space…',
            isLoading: true,
          );
        }

        return const AuthGate();
      },
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _StartupMessage(
            icon: LucideIcons.notebook_pen,
            title: 'Notes',
            message: 'Checking your account…',
            isLoading: true,
          );
        }
        if (snapshot.hasError) {
          return _StartupMessage(
            icon: LucideIcons.circle_alert,
            title: 'Authentication error',
            message:
                'Could not verify your account. '
                'Restart the app and try again.',
          );
        }
        if (snapshot.hasData) {
          return const NotesListScreen();
        }
        return const AuthScreen();
      },
    );
  }
}

class _StartupMessage extends StatelessWidget {
  const _StartupMessage({
    required this.icon,
    required this.title,
    required this.message,
    this.isLoading = false,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final bool isLoading;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8EFEA),
                  borderRadius: BorderRadius.circular(26),
                ),
                child: Icon(icon, size: 38, color: _primary),
              ),
              const SizedBox(height: 22),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(color: const Color(0xFF747A73), height: 1.5),
              ),
              if (isLoading) ...[
                const SizedBox(height: 24),
                const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                ),
              ],
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: 22),
                FilledButton(onPressed: onAction, child: Text(actionLabel!)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
