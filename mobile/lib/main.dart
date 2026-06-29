import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/providers/auth_providers.dart';
import 'features/projects/screens/dashboard_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es', null);
  runApp(const ProviderScope(child: StackMoviApp()));
}

class StackMoviApp extends StatelessWidget {
  const StackMoviApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'StackMovi',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: const _AuthGate(),
    );
  }
}

class _AuthGate extends ConsumerWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      data: (state) {
        if (state.isAuthenticated) return const DashboardScreen();
        return const LoginScreen();
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => const LoginScreen(),
    );
  }
}
