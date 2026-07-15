import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/models.dart';
import '../../../core/network/api_client.dart';
import '../repository/proyecto_repository.dart';
import '../repository/cuenta_repository.dart';
import '../repository/empaque_repository.dart';

final proyectoRepositoryProvider = Provider<ProyectoRepository>(
  (ref) => ProyectoRepository(apiClient),
);

final proyectosProvider = FutureProvider<List<ProyectoModel>>((ref) async {
  final timer = Timer(const Duration(seconds: 3), () => ref.invalidateSelf());
  ref.onDispose(timer.cancel);
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
  (ref, proyectoId) async {
    final timer = Timer(const Duration(seconds: 3), () => ref.invalidateSelf());
    ref.onDispose(timer.cancel);
    return ref.watch(cuentaRepositoryProvider).getCuentas(proyectoId);
  },
);

final ventasProvider = FutureProvider.family<List<VentaModel>, String>(
  (ref, cuentaId) async {
    final timer = Timer(const Duration(seconds: 3), () => ref.invalidateSelf());
    ref.onDispose(timer.cancel);
    return ref.watch(ventaRepositoryProvider).getVentas(cuentaId);
  },
);

final abonosCuentaProvider = FutureProvider.family<List<AbonoDetalleModel>, String>(
  (ref, cuentaId) async {
    final timer = Timer(const Duration(seconds: 3), () => ref.invalidateSelf());
    ref.onDispose(timer.cancel);
    return ref.watch(cuentaRepositoryProvider).getAbonosCuenta(cuentaId);
  },
);

final gastosFamilyProvider = FutureProvider.family<List<GastoModel>, String>(
  (ref, cuentaId) async {
    final timer = Timer(const Duration(seconds: 3), () => ref.invalidateSelf());
    ref.onDispose(timer.cancel);
    return ref.watch(gastoRepositoryProvider).getGastos(cuentaId);
  },
);

final miembrosProvider = FutureProvider.family<List<Map<String, dynamic>>, String>(
  (ref, proyectoId) async {
    final timer = Timer(const Duration(seconds: 3), () => ref.invalidateSelf());
    ref.onDispose(timer.cancel);
    return ref.watch(proyectoRepositoryProvider).getMiembros(proyectoId);
  },
);

final transaccionesProyectoProvider = FutureProvider.family<List<TransaccionGeneralModel>, String>(
  (ref, proyectoId) async {
    final timer = Timer(const Duration(seconds: 3), () => ref.invalidateSelf());
    ref.onDispose(timer.cancel);
    return ref.watch(proyectoRepositoryProvider).getTransacciones(proyectoId);
  },
);

final abonosProvider = FutureProvider.family<List<AbonoModel>, String>(
  (ref, ventaId) async {
    final timer = Timer(const Duration(seconds: 3), () => ref.invalidateSelf());
    ref.onDispose(timer.cancel);
    return ref.watch(ventaRepositoryProvider).getAbonos(ventaId);
  },
);

final proyectoReporteProvider = FutureProvider.family<ProyectoReporteData, String>(
  (ref, proyectoId) async {
    // No timer for report, we want to fetch it fresh when requested
    return ref.watch(proyectoRepositoryProvider).getReporteDatos(proyectoId);
  },
);

final empaqueRepositoryProvider = Provider<EmpaqueRepository>(
  (ref) => EmpaqueRepository(apiClient),
);

final empaquesProvider = FutureProvider.family<List<EmpaqueModel>, String>(
  (ref, proyectoId) async {
    return ref.watch(empaqueRepositoryProvider).getEmpaques(proyectoId);
  },
);

final historialSugerenciasProvider = FutureProvider.family<HistorialSugerenciasModel, String>(
  (ref, proyectoId) async {
    return ref.watch(proyectoRepositoryProvider).getHistorialSugerencias(proyectoId);
  },
);
