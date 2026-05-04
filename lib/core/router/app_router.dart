import 'package:go_router/go_router.dart';
import 'package:cuentas_claras/presentation/screens/auth/login_screen.dart';
import 'package:cuentas_claras/presentation/screens/auth/reset_password_screen.dart';
import 'package:cuentas_claras/presentation/screens/main_shell.dart';
import 'package:cuentas_claras/data/services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final appRouter = GoRouter(
  initialLocation: '/login',
  redirect: (context, state) {
    final isSignedIn = SupabaseService.instance.isSignedIn;
    final loc = state.matchedLocation;

    if (loc == '/reset-password') return null;
    if (!isSignedIn && loc == '/dashboard') return '/login';
    if (isSignedIn && loc == '/login') return '/dashboard';

    return null;
  },
  routes: [
    GoRoute(
      path: '/login',
      builder: (ctx, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/dashboard',
      builder: (ctx, state) => const MainShell(),
    ),
    GoRoute(
      path: '/reset-password',
      builder: (ctx, state) => const ResetPasswordScreen(),
    ),
  ],
);