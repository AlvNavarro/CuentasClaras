import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/app_constants.dart';

class SupabaseService {
  SupabaseService._();
  static final SupabaseService instance = SupabaseService._();

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: AppConstants.supabaseUrl,
      anonKey: AppConstants.supabaseAnonKey,
      debug: false,
    );
  }

  SupabaseClient get client => Supabase.instance.client;
  GoTrueClient get auth => client.auth;
  User? get currentUser => auth.currentUser;
  bool get isSignedIn => currentUser != null;
  String? get currentUserId => currentUser?.id;

  Future<AuthResponse> signInWithEmail(String email, String password) =>
      auth.signInWithPassword(email: email, password: password);

  Future<AuthResponse> signUpWithEmail(String email, String password) =>
      auth.signUp(email: email, password: password);

  Future<void> signOut() => auth.signOut();

  Stream<AuthState> get authChanges => auth.onAuthStateChange;
}