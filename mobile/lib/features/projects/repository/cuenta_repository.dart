import 'package:dio/dio.dart';
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
    final res = await _api.client.post('/cuentas', data: {
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
}

class VentaRepository {
  final ApiClient _api;

  VentaRepository(this._api);

  Future<List<VentaModel>> getVentas(String cuentaId) async {
    final res = await _api.client.get('/ventas/cuenta/$cuentaId');
    return (res.data as List).map((e) => VentaModel.fromJson(e)).toList();
  }

  Future<void> registrarVenta({
    required String cuentaId,
    required String registradoPor,
    required String cliente,
    required double kilosVendidos,
    required double precioPorKg,
    required DateTime fechaVenta,
    double? montoInicialPagado,
  }) async {
    await _api.client.post('/ventas', data: {
      'cuenta_id': cuentaId,
      'cliente': cliente.trim(),
      'kilos_vendidos': kilosVendidos,
      'precio_por_kg': precioPorKg,
      'fecha_venta': fechaVenta.toIso8601String().substring(0, 10),
      'monto_inicial_pagado': montoInicialPagado,
    });
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
    await _api.client.post('/gastos', data: {
      'cuenta_id': cuentaId,
      'descripcion': descripcion.trim(),
      'monto': monto,
      'fecha_gasto': fechaGasto.toIso8601String().substring(0, 10),
    });
  }
}
