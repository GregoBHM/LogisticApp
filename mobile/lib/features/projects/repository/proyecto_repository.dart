import '../../../core/models/models.dart';
import '../../../core/network/api_client.dart';

class ProyectoRepository {
  final ApiClient _api;

  ProyectoRepository(this._api);

  Future<List<ProyectoModel>> getProyectos() async {
    final res = await _api.client.get('/proyectos');
    return (res.data as List).map((e) => ProyectoModel.fromJson(e)).toList();
  }

  Future<ProyectoModel> crearProyecto({
    required String nombre,
    String? descripcion,
    required String monedaSimbolo,
    required String monedaCodigo,
    required String creadoPor,
    String? productoDefault,
    String? tipoUnidadDefault,
    String? unidadMedidaDefault,
    double? cantidadPorUnidadDefault,
    String tipoPlantilla = 'COMERCIO',
  }) async {
    final res = await _api.client.post('/proyectos', data: {
      'nombre': nombre.trim(),
      'descripcion': descripcion?.trim(),
      'moneda_simbolo': monedaSimbolo,
      'moneda_codigo': monedaCodigo,
      if (productoDefault != null) 'producto_default': productoDefault.trim(),
      if (tipoUnidadDefault != null) 'tipo_unidad_default': tipoUnidadDefault.trim(),
      if (unidadMedidaDefault != null) 'unidad_medida_default': unidadMedidaDefault,
      if (cantidadPorUnidadDefault != null) 'cantidad_por_unidad_default': cantidadPorUnidadDefault,
      'tipo_plantilla': tipoPlantilla,
    });
    return ProyectoModel.fromJson(res.data);
  }

  Future<void> actualizarProyecto(
    String id, {
    String? nombre,
    String? descripcion,
    String? productoDefault,
    String? tipoUnidadDefault,
    String? unidadMedidaDefault,
    double? cantidadPorUnidadDefault,
  }) async {
    final updates = <String, dynamic>{};
    if (nombre != null) updates['nombre'] = nombre.trim();
    if (descripcion != null) updates['descripcion'] = descripcion.trim();
    if (productoDefault != null) updates['producto_default'] = productoDefault.trim();
    if (tipoUnidadDefault != null) updates['tipo_unidad_default'] = tipoUnidadDefault.trim();
    if (unidadMedidaDefault != null) updates['unidad_medida_default'] = unidadMedidaDefault;
    if (cantidadPorUnidadDefault != null) updates['cantidad_por_unidad_default'] = cantidadPorUnidadDefault;
    if (updates.isEmpty) return;

    await _api.client.put('/proyectos/$id', data: updates);
  }

  Future<void> eliminarProyecto(String id) async {
    await _api.client.delete('/proyectos/$id');
  }

  Future<List<Map<String, dynamic>>> getMiembros(String proyectoId) async {
    final res = await _api.client.get('/proyectos/$proyectoId/miembros');
    return List<Map<String, dynamic>>.from(res.data);
  }

  Future<void> invitarMiembro(String id, String email) async {
    await _api.client.post('/proyectos/$id/invitar/', data: {'email': email});
  }

  Future<void> cambiarRolMiembro(String proyectoId, String usuarioId, String nuevoRol) async {
    await _api.client.put(
      '/proyectos/$proyectoId/miembros/$usuarioId',
      data: {'rol': nuevoRol},
    );
  }

  Future<void> expulsarMiembro(String proyectoId, String usuarioId) async {
    await _api.client.delete('/proyectos/$proyectoId/miembros/$usuarioId');
  }

  Future<List<TransaccionGeneralModel>> getTransacciones(String proyectoId) async {
    final res = await _api.client.get('/proyectos/$proyectoId/transacciones/');
    return (res.data as List).map((j) => TransaccionGeneralModel.fromJson(j)).toList();
  }

  Future<TransaccionGeneralModel> addTransaccion(
    String proyectoId,
    String tipo,
    String descripcion,
    double monto,
    DateTime fecha,
  ) async {
    final res = await _api.client.post('/proyectos/$proyectoId/transacciones/', data: {
      'proyecto_id': proyectoId,
      'tipo': tipo,
      'descripcion': descripcion,
      'monto': monto,
      'fecha_transaccion': fecha.toIso8601String().substring(0, 10),
    });
    return TransaccionGeneralModel.fromJson(res.data);
  }

  Future<void> deleteTransaccion(String id) async {
    await _api.client.delete('/proyectos/transacciones/$id');
  }

  Future<void> updateTransaccion(
    String id,
    String tipo,
    String descripcion,
    double monto,
    DateTime fecha,
  ) async {
    await _api.client.put('/proyectos/transacciones/$id', data: {
      'tipo': tipo,
      'descripcion': descripcion,
      'monto': monto,
      'fecha_transaccion': fecha.toIso8601String().substring(0, 10),
    });
  }

  Future<ProyectoReporteData> getReporteDatos(String proyectoId) async {
    final res = await _api.client.get('/proyectos/$proyectoId/reporte_datos');
    return ProyectoReporteData.fromJson(res.data);
  }

  Future<HistorialSugerenciasModel> getHistorialSugerencias(String proyectoId) async {
    final res = await _api.client.get('/proyectos/$proyectoId/historial_sugerencias');
    return HistorialSugerenciasModel.fromJson(res.data);
  }
}
