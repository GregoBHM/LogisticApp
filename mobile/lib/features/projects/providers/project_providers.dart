import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/models.dart';
import '../../../core/network/api_client.dart';
import '../repository/proyecto_repository.dart';
import '../repository/cuenta_repository.dart';

final proyectoRepositoryProvider = Provider<ProyectoRepository>(
  (ref) => ProyectoRepository(apiClient),
);

final proyectosProvider = FutureProvider<List<ProyectoModel>>((ref) {
  return ref.watch(proyectoRepositoryProvider).getProyectos();
});

final cuentaRepositoryProvider = Provider<CuentaRepository>(
  (ref) => CuentaRepository(apiClient),
);

final ventaRepositoryProvider = Provider<VentaRepository>(
  (ref) => VentaRepository(apiClient),
);

final gastoRepositoryProvider = Provider<GastoRepository>(
  (ref) => GastoRepository(apiClient),
);

final cuentasProvider = FutureProvider.family<List<CuentaResumenModel>, String>(
  (ref, proyectoId) => ref.watch(cuentaRepositoryProvider).getCuentas(proyectoId),
);

final ventasProvider = FutureProvider.family<List<VentaModel>, String>(
  (ref, cuentaId) => ref.watch(ventaRepositoryProvider).getVentas(cuentaId),
);

final gastosFamilyProvider = FutureProvider.family<List<GastoModel>, String>(
  (ref, cuentaId) => ref.watch(gastoRepositoryProvider).getGastos(cuentaId),
);

final miembrosProvider = FutureProvider.family<List<Map<String, dynamic>>, String>(
  (ref, proyectoId) => ref.watch(proyectoRepositoryProvider).getMiembros(proyectoId),
);
