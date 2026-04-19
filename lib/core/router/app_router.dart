import 'package:go_router/go_router.dart';
import 'package:cuentas_claras/presentation/screens/auth/login_screen.dart';
import 'package:cuentas_claras/presentation/screens/main_shell.dart';

final appRouter = GoRouter(
  initialLocation: '/login',
  routes: [
    GoRoute(
      path: '/login',
      builder: (ctx, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/dashboard',
      builder: (ctx, state) => const MainShell(),
    ),
  ],
);