import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_manager.dart';
import 'core/database/database_helper.dart';
import 'package:notes_app/features/notes/presentation/pages/home_page.dart';

void main() async {
  // Ensure Flutter is properly initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Run the app with error boundary
  runApp(const AppInitializer());
}

class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  bool _isInitialized = false;
  String? _initError;
  ThemeManager? _themeManager;
  List<String> _initSteps = [];

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  void _addInitStep(String step) {
    setState(() {
      _initSteps.add(step);
    });
    print('Init step: $step');
  }

  Future<void> _initializeApp() async {
    try {
      setState(() {
        _isInitialized = false;
        _initError = null;
        _initSteps.clear();
      });

      _addInitStep('Starting initialization...');

      // Initialize theme manager first (it's less likely to fail)
      _addInitStep('Initializing theme manager...');
      _themeManager = ThemeManager();
      await _themeManager!.init();
      _addInitStep('Theme manager initialized successfully');

      // Initialize database with more detailed error handling
      _addInitStep('Initializing database...');
      try {
        // First, try to get a database instance
        final db = await DatabaseHelper.instance.database;
        _addInitStep('Database instance created');

        // Test basic connection
        final testResult = await DatabaseHelper.instance.testConnection();
        if (!testResult) {
          throw Exception('Database connection test failed');
        }
        _addInitStep('Database connection test passed');

        // Try to get categories to ensure everything is working
        final categories = await DatabaseHelper.instance.getCategories();
        _addInitStep('Categories loaded: ${categories.length} found');
      } catch (dbError) {
        _addInitStep('Database error: $dbError');

        // Try to reset database as a last resort
        try {
          _addInitStep('Attempting database reset...');
          await DatabaseHelper.instance.resetDatabase();
          _addInitStep('Database reset successful');

          // Test again after reset
          final testResult = await DatabaseHelper.instance.testConnection();
          if (!testResult) {
            throw Exception('Database still not working after reset');
          }
          _addInitStep('Database working after reset');
        } catch (resetError) {
          _addInitStep('Database reset failed: $resetError');
          throw Exception(
            'Database initialization failed: $dbError. Reset attempt failed: $resetError',
          );
        }
      }

      _addInitStep('Initialization completed successfully');
      setState(() {
        _isInitialized = true;
        _initError = null;
      });
    } catch (e) {
      _addInitStep('Initialization failed: $e');
      setState(() {
        _isInitialized = false;
        _initError = e.toString();
      });

      // Create a basic theme manager if initialization failed
      _themeManager ??= ThemeManager();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitialized && _themeManager != null) {
      return LuxeNotesApp(themeManager: _themeManager!);
    }

    // Show error screen or loading
    return MaterialApp(
      title: 'Luxe Notes',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      home:
          _initError != null
              ? ErrorScreen(
                error: _initError!,
                initSteps: _initSteps,
                onRetry: _initializeApp,
              )
              : LoadingScreen(steps: _initSteps),
    );
  }
}

class LoadingScreen extends StatelessWidget {
  final List<String> steps;

  const LoadingScreen({super.key, required this.steps});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.note_alt_rounded,
                    size: 40,
                    color: Colors.blue.shade600,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Luxe Notes',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Initializing...',
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.blue.shade600,
                    ),
                  ),
                ),
                if (steps.isNotEmpty) ...[
                  const SizedBox(height: 32),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Initialization Progress:',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...steps
                            .take(5)
                            .map(
                              (step) => Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Text(
                                  '• $step',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ),
                            ),
                        if (steps.length > 5)
                          Text(
                            '... and ${steps.length - 5} more steps',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ErrorScreen extends StatelessWidget {
  final String error;
  final List<String> initSteps;
  final VoidCallback onRetry;

  const ErrorScreen({
    super.key,
    required this.error,
    required this.initSteps,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.error_outline,
                    size: 40,
                    color: Colors.red.shade600,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Initialization Error',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Error Details:',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        error,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
                if (initSteps.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Initialization Steps:',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.blue.shade700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...initSteps.map(
                          (step) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              '• $step',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blue.shade600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onRetry,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Retry Initialization',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () async {
                      // Try to reset database
                      try {
                        await DatabaseHelper.instance.resetDatabase();
                        onRetry();
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Reset failed: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.orange.shade600,
                      side: BorderSide(color: Colors.orange.shade600),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Reset Database & Retry',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    // Launch with minimal setup
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder:
                            (_) => LuxeNotesApp(themeManager: ThemeManager()),
                      ),
                    );
                  },
                  child: Text(
                    'Continue with basic setup',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class LuxeNotesApp extends StatelessWidget {
  final ThemeManager themeManager;

  const LuxeNotesApp({super.key, required this.themeManager});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ThemeManager>(
      create: (_) => themeManager,
      child: Consumer<ThemeManager>(
        builder: (context, themeManager, child) {
          return MaterialApp(
            title: 'Luxe Notes',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeManager.themeMode,
            home: const HomePage(),
            builder: (context, child) {
              // Add error boundary and responsive text scaling
              return MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaleFactor: MediaQuery.of(
                    context,
                  ).textScaleFactor.clamp(0.8, 1.2),
                ),
                child: child ?? const SizedBox(),
              );
            },
          );
        },
      ),
    );
  }
}
