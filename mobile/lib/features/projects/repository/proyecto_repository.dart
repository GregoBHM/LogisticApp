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
  }) async {
    final res = await _api.client.post('/proyectos', data: {
      'nombre': nombre.trim(),
      'descripcion': descripcion?.trim(),
      'moneda_simbolo': monedaSimbolo,
      'moneda_codigo': monedaCodigo,
    });
    return ProyectoModel.fromJson(res.data);
  }

  Future<void> actualizarProyecto(
    String id, {
    String? nombre,
    String? descripcion,
  }) async {
    final updates = <String, dynamic>{};
    if (nombre != null) updates['nombre'] = nombre.trim();
    if (descripcion != null) updates['descripcion'] = descripcion.trim();
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

  Future<void> invitarMiembro(String proyectoId, String email) async {
    await _api.client.post('/proyectos/$proyectoId/invitar', data: {'email': email});
  }
}
