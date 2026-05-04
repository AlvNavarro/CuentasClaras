import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/app_constants.dart';
import 'package:flutter/foundation.dart';

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

  String get userRole =>
      currentUser?.userMetadata?['role'] as String? ?? 'employee';
  bool get isAdmin => userRole == 'admin';

  String get ownerId {
    if (isAdmin) return currentUserId ?? '';
    return currentUser?.userMetadata?['owner_id'] as String? ??
        currentUserId ?? '';
  }

  Future<AuthResponse> signInWithEmail(String email, String password) =>
      auth.signInWithPassword(email: email, password: password);

  Future<AuthResponse> signUpWithEmail(
    String email,
    String password,
    String businessName,
    String fullName,
  ) =>
      auth.signUp(
        email: email,
        password: password,
        data: {
          'role': 'admin',
          'full_name': fullName,
          'business_name': businessName,
        },
      );

  Future<void> resetPassword(String email) =>
    auth.resetPasswordForEmail(
      email,
      redirectTo: 'http://localhost:8080/#/reset-password',
    );

  Future<void> signOut() => auth.signOut();

  Stream<AuthState> get authChanges => auth.onAuthStateChange;

  // ─── EMPLEADOS ───────────────────────────────────────────────

  Future<void> createEmployee(
      String email, String password, String fullName) async {
    final response = await auth.signUp(
      email: email,
      password: password,
      data: {
        'role': 'employee',
        'full_name': fullName,
        'owner_id': currentUserId,
      },
    );
    if (response.user == null) throw Exception('Error al crear empleado');
  }

  Future<List<Map<String, dynamic>>> getEmployees() async {
    final data = await client
        .from('employee_profiles')
        .select()
        .eq('owner_id', currentUserId ?? '');
    return List<Map<String, dynamic>>.from(data as List);
  }

  Future<void> deleteEmployee(String employeeId) async {
  final session = auth.currentSession;
  if (session == null) throw Exception('No hay sesión activa');

  final response = await client.functions.invoke(
    'delete-employee',
    body: {'employeeId': employeeId},
    headers: {'Authorization': 'Bearer ${session.accessToken}'},
  );

  if (response.status != 200) {
    throw Exception('Error al eliminar empleado');
  }
}
}