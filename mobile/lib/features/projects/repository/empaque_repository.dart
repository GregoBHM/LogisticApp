import '../../../core/models/models.dart';
import '../../../core/network/api_client.dart';

class EmpaqueRepository {
  final ApiClient _api;

  EmpaqueRepository(this._api);

  Future<List<EmpaqueModel>> getEmpaques(String proyectoId) async {
    final res = await _api.client.get('/proyectos/$proyectoId/empaques');
    return (res.data as List).map((e) => EmpaqueModel.fromJson(e)).toList();
  }

  Future<EmpaqueModel> crearEmpaque({
    required String proyectoId,
    required String nombre,
    required String unidadMedida,
    required double cantidadPorUnidad,
    String? descripcion,
  }) async {
    final res = await _api.client.post(
      '/proyectos/$proyectoId/empaques',
      data: {
        'nombre': nombre.trim(),
        'unidad_medida': unidadMedida,
        'cantidad_por_unidad': cantidadPorUnidad,
        if (descripcion != null && descripcion.trim().isNotEmpty)
          'descripcion': descripcion.trim(),
      },
    );
    return EmpaqueModel.fromJson(res.data);
  }

  Future<void> eliminarEmpaque({
    required String proyectoId,
    required String empaqueId,
  }) async {
    await _api.client.delete('/proyectos/$proyectoId/empaques/$empaqueId');
  }
}
