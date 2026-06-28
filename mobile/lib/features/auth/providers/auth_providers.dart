import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/models.dart';
import '../../../core/network/api_client.dart';
import '../repository/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(apiClient),
);

final authStateProvider = StreamProvider<AuthState>(
  (ref) => ref.watch(authRepositoryProvider).authStateChanges,
);

final perfilProvider = FutureProvider<PerfilModel?>((ref) {
  ref.watch(authStateProvider);
  return ref.read(authRepositoryProvider).getPerfil();
});
