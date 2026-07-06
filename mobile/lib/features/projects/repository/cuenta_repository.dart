import '../../../core/models/models.dart';
import '../../../core/network/api_client.dart';

class CuentaRepository {
  final ApiClient _api;

  CuentaRepository(this._api);

  Future<List<CuentaResumenModel>> getCuentas(String proyectoId) async {
    final res = await _api.client.get('/cuentas/proyecto/$proyectoId');
    return (res.data as List).map((e) => CuentaResumenModel.fromJson(e)).toList();
  }

  Future<CuentaResumenModel> getCuentaById(String cuentaId) async {
    final res = await _api.client.get('/cuentas/$cuentaId');
    return CuentaResumenModel.fromJson(res.data);
  }

  Future<CuentaModel> crearCuenta({
    required String proyectoId,
    required String nombre,
    required String producto,
    required String tipoUnidad,
    required String unidadMedida,
    required double cantidadUnidades,
    required double cantidadPorUnidad,
    required double inversionTotal,
    required double precioUnitario,
    required String creadoPor,
    required DateTime fechaApertura,
  }) async {
    final res = await _api.client.post('/cuentas/', data: {
      'proyecto_id': proyectoId,
      'nombre': nombre.trim(),
      'producto': producto.trim(),
      'tipo_unidad': tipoUnidad.trim(),
      'unidad_medida': unidadMedida,
      'cantidad_unidades': cantidadUnidades,
      'cantidad_por_unidad': cantidadPorUnidad,
      'inversion_total': inversionTotal,
      'precio_unitario': precioUnitario,
      'fecha_apertura': fechaApertura.toIso8601String().substring(0, 10),
    });
    return CuentaModel.fromJson(res.data);
  }

  Future<void> cerrarCuenta(String cuentaId, String cerradoPor) async {
    await _api.client.put('/cuentas/$cuentaId/cerrar');
  }

  Future<void> reabrirCuenta(String cuentaId) async {
    await _api.client.put('/cuentas/$cuentaId/reabrir');
  }

  Future<List<AbonoDetalleModel>> getAbonosCuenta(String cuentaId) async {
    final res = await _api.client.get('/cuentas/$cuentaId/abonos');
    return (res.data as List).map((j) => AbonoDetalleModel.fromJson(j)).toList();
  }

  Future<void> actualizarCuenta(
    String id, {
    String? nombre,
    String? producto,
    String? tipoUnidad,
    String? unidadMedida,
    double? cantidadUnidades,
    double? cantidadPorUnidad,
    double? inversionTotal,
    double? precioUnitario,
    DateTime? fechaApertura,
  }) async {
    final updates = <String, dynamic>{};
    if (nombre != null) updates['nombre'] = nombre.trim();
    if (producto != null) updates['producto'] = producto.trim();
    if (tipoUnidad != null) updates['tipo_unidad'] = tipoUnidad.trim();
    if (unidadMedida != null) updates['unidad_medida'] = unidadMedida;
    if (cantidadUnidades != null) updates['cantidad_unidades'] = cantidadUnidades;
    if (cantidadPorUnidad != null) updates['cantidad_por_unidad'] = cantidadPorUnidad;
    if (inversionTotal != null) updates['inversion_total'] = inversionTotal;
    if (precioUnitario != null) updates['precio_unitario'] = precioUnitario;
    if (fechaApertura != null) updates['fecha_apertura'] = fechaApertura.toIso8601String().substring(0, 10);
    if (updates.isEmpty) return;
    await _api.client.put('/cuentas/$id', data: updates);
  }
}

class VentaRepository {
  final ApiClient _api;

  VentaRepository(this._api);

  Future<List<VentaModel>> getVentas(String cuentaId) async {
    final res = await _api.client.get('/ventas/cuenta/$cuentaId');
    return (res.data as List).map((e) => VentaModel.fromJson(e)).toList();
  }

  Future<List<AbonoModel>> getAbonos(String ventaId) async {
    final res = await _api.client.get('/ventas/$ventaId/abonos');
    return (res.data as List).map((e) => AbonoModel.fromJson(e)).toList();
  }

  Future<void> registrarVenta({
    required String cuentaId,
    required String registradoPor,
    required String cliente,
    double? cantidadVendida,
    required double precioUnitario,
    required double totalVenta,
    required DateTime fechaVenta,
    double? montoInicialPagado,
  }) async {
    await _api.client.post('/ventas/', data: {
      'cuenta_id': cuentaId,
      'cliente': cliente.trim(),
      if (cantidadVendida != null) 'cantidad_vendida': cantidadVendida,
      'precio_unitario': precioUnitario,
      'total_venta': totalVenta,
      'fecha_venta': fechaVenta.toIso8601String().substring(0, 10),
      if (montoInicialPagado != null) 'monto_inicial_pagado': montoInicialPagado,
    });
  }

  Future<void> actualizarVenta(
    String id, {
    String? cliente,
    double? cantidadVendida,
    double? precioUnitario,
    double? totalVenta,
    DateTime? fechaVenta,
  }) async {
    final updates = <String, dynamic>{};
    if (cliente != null) updates['cliente'] = cliente.trim();
    if (cantidadVendida != null) updates['cantidad_vendida'] = cantidadVendida;
    if (precioUnitario != null) updates['precio_unitario'] = precioUnitario;
    if (totalVenta != null) updates['total_venta'] = totalVenta;
    if (fechaVenta != null) updates['fecha_venta'] = fechaVenta.toIso8601String().substring(0, 10);
    if (updates.isEmpty) return;
    await _api.client.put('/ventas/$id', data: updates);
  }

  Future<void> eliminarVenta(String id) async {
    await _api.client.delete('/ventas/$id');
  }

  Future<void> registrarAbono({
    required String ventaId,
    required String registradoPor,
    required double monto,
    required DateTime fechaAbono,
    String? nota,
  }) async {
    await _api.client.post('/ventas/abonos', data: {
      'venta_id': ventaId,
      'monto': monto,
      'fecha_abono': fechaAbono.toIso8601String().substring(0, 10),
      'nota': nota?.trim(),
    });
  }

  Future<void> actualizarAbono(
    String id, {
    double? monto,
    String? nota,
    DateTime? fechaAbono,
  }) async {
    final updates = <String, dynamic>{};
    if (monto != null) updates['monto'] = monto;
    if (nota != null) updates['nota'] = nota.trim();
    if (fechaAbono != null) updates['fecha_abono'] = fechaAbono.toIso8601String().substring(0, 10);
    if (updates.isEmpty) return;
    await _api.client.put('/ventas/abonos/$id', data: updates);
  }

  Future<void> eliminarAbono(String id) async {
    await _api.client.delete('/ventas/abonos/$id');
  }
}

class GastoRepository {
  final ApiClient _api;

  GastoRepository(this._api);

  Future<List<GastoModel>> getGastos(String cuentaId) async {
    final res = await _api.client.get('/gastos/cuenta/$cuentaId');
    return (res.data as List).map((e) => GastoModel.fromJson(e)).toList();
  }

  Future<void> registrarGasto({
    required String cuentaId,
    required String registradoPor,
    required String descripcion,
    String? categoria,
    required double monto,
    required DateTime fechaGasto,
  }) async {
    await _api.client.post('/gastos/', data: {
      'cuenta_id': cuentaId,
      'descripcion': descripcion.trim(),
      if (categoria != null) 'categoria': categoria,
      'monto': monto,
      'fecha_gasto': fechaGasto.toIso8601String().substring(0, 10),
    });
  }

  Future<void> actualizarGasto(
    String id, {
    String? descripcion,
    String? categoria,
    double? monto,
    DateTime? fechaGasto,
  }) async {
    final updates = <String, dynamic>{};
    if (descripcion != null) updates['descripcion'] = descripcion.trim();
    if (categoria != null) updates['categoria'] = categoria;
    if (monto != null) updates['monto'] = monto;
    if (fechaGasto != null) updates['fecha_gasto'] = fechaGasto.toIso8601String().substring(0, 10);
    if (updates.isEmpty) return;
    await _api.client.put('/gastos/$id', data: updates);
  }

  Future<void> eliminarGasto(String id) async {
    await _api.client.delete('/gastos/$id');
  }
}
