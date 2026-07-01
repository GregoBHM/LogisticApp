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
    required double cantidadUnidades,
    required double kgPorUnidad,
    required double inversionTotal,
    required double precioVentaKg,
    required String creadoPor,
    required DateTime fechaApertura,
  }) async {
    final res = await _api.client.post('/cuentas/', data: {
      'proyecto_id': proyectoId,
      'nombre': nombre.trim(),
      'producto': producto.trim(),
      'tipo_unidad': tipoUnidad.trim(),
      'cantidad_unidades': cantidadUnidades,
      'kg_por_unidad': kgPorUnidad,
      'inversion_total': inversionTotal,
      'precio_venta_kg': precioVentaKg,
      'fecha_apertura': fechaApertura.toIso8601String().substring(0, 10),
    });
    return CuentaModel.fromJson(res.data);
  }

  Future<void> cerrarCuenta(String cuentaId, String cerradoPor) async {
    await _api.client.put('/cuentas/$cuentaId/cerrar');
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
    double? cantidadUnidades,
    double? kgPorUnidad,
    double? inversionTotal,
    double? precioVentaKg,
    DateTime? fechaApertura,
  }) async {
    final updates = <String, dynamic>{};
    if (nombre != null) updates['nombre'] = nombre.trim();
    if (producto != null) updates['producto'] = producto.trim();
    if (tipoUnidad != null) updates['tipo_unidad'] = tipoUnidad.trim();
    if (cantidadUnidades != null) updates['cantidad_unidades'] = cantidadUnidades;
    if (kgPorUnidad != null) updates['kg_por_unidad'] = kgPorUnidad;
    if (inversionTotal != null) updates['inversion_total'] = inversionTotal;
    if (precioVentaKg != null) updates['precio_venta_kg'] = precioVentaKg;
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
    double? kilosVendidos,
    required double precioPorKg,
    required double totalVenta,
    required DateTime fechaVenta,
    double? montoInicialPagado,
  }) async {
    await _api.client.post('/ventas/', data: {
      'cuenta_id': cuentaId,
      'cliente': cliente.trim(),
      if (kilosVendidos != null) 'kilos_vendidos': kilosVendidos,
      'precio_por_kg': precioPorKg,
      'total_venta': totalVenta,
      'fecha_venta': fechaVenta.toIso8601String().substring(0, 10),
      if (montoInicialPagado != null) 'monto_inicial_pagado': montoInicialPagado,
    });
  }

  Future<void> actualizarVenta(
    String id, {
    String? cliente,
    double? kilosVendidos,
    double? precioPorKg,
    DateTime? fechaVenta,
  }) async {
    final updates = <String, dynamic>{};
    if (cliente != null) updates['cliente'] = cliente.trim();
    if (kilosVendidos != null) updates['kilos_vendidos'] = kilosVendidos;
    if (precioPorKg != null) updates['precio_por_kg'] = precioPorKg;
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
    required double monto,
    required DateTime fechaGasto,
  }) async {
    await _api.client.post('/gastos/', data: {
      'cuenta_id': cuentaId,
      'descripcion': descripcion.trim(),
      'monto': monto,
      'fecha_gasto': fechaGasto.toIso8601String().substring(0, 10),
    });
  }

  Future<void> actualizarGasto(
    String id, {
    String? descripcion,
    double? monto,
    DateTime? fechaGasto,
  }) async {
    final updates = <String, dynamic>{};
    if (descripcion != null) updates['descripcion'] = descripcion.trim();
    if (monto != null) updates['monto'] = monto;
    if (fechaGasto != null) updates['fecha_gasto'] = fechaGasto.toIso8601String().substring(0, 10);
    if (updates.isEmpty) return;

    await _api.client.put('/gastos/$id', data: updates);
  }

  Future<void> eliminarGasto(String id) async {
    await _api.client.delete('/gastos/$id');
  }
}
