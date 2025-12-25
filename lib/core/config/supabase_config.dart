import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Configuration class for Supabase client initialization and management.
/// 
/// This class handles loading environment variables and initializing the
/// Supabase client with credentials from the .env file.
class SupabaseConfig {
  static SupabaseClient? _client;

  /// Get the Supabase client instance.
  /// Throws an exception if the client has not been initialized.
  static SupabaseClient get client {
    if (_client == null) {
      throw Exception(
        'Supabase has not been initialized. Call SupabaseConfig.initialize() first.',
      );
    }
    return _client!;
  }

  /// Initialize Supabase with credentials from .env file.
  /// 
  /// This should be called once at app startup before any Supabase
  /// operations are performed.
  /// 
  /// Throws an exception if environment variables are missing or invalid.
  static Future<void> initialize() async {
    try {
      // Load environment variables from .env file
      await dotenv.load(fileName: '.env');

      final supabaseUrl = dotenv.env['SUPABASE_URL'];
      final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'];

      // Validate that credentials are present
      if (supabaseUrl == null || supabaseUrl.isEmpty) {
        throw Exception(
          'SUPABASE_URL is not set in .env file. Please add your Supabase project URL.',
        );
      }

      if (supabaseAnonKey == null || supabaseAnonKey.isEmpty) {
        throw Exception(
          'SUPABASE_ANON_KEY is not set in .env file. Please add your Supabase anon key.',
        );
      }

      // Check if values are still placeholders
      if (supabaseUrl.contains('your_project_url_here')) {
        throw Exception(
          'Please replace the placeholder SUPABASE_URL in .env with your actual Supabase project URL.',
        );
      }

      if (supabaseAnonKey.contains('your_anon_key_here')) {
        throw Exception(
          'Please replace the placeholder SUPABASE_ANON_KEY in .env with your actual Supabase anon key.',
        );
      }

      // Initialize Supabase Flutter
      await Supabase.initialize(
        url: supabaseUrl,
        anonKey: supabaseAnonKey,
        authOptions: const FlutterAuthClientOptions(
          authFlowType: AuthFlowType.pkce,
        ),
      );

      _client = Supabase.instance.client;
    } catch (e) {
      throw Exception('Failed to initialize Supabase: $e');
    }
  }

  /// Check if Supabase has been initialized.
  static bool get isInitialized => _client != null;

  /// Get the current auth state.
  static Stream<AuthState> get authStateChanges =>
      client.auth.onAuthStateChange;

  /// Get the current user.
  static User? get currentUser => client.auth.currentUser;

  /// Get the current session.
  static Session? get currentSession => client.auth.currentSession;
}

/// Convenience getter for accessing Supabase client.
SupabaseClient get supabase => SupabaseConfig.client;
