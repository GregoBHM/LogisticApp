class PerfilModel {
  final String id;
  final String nombre;
  final String email;
  final DateTime createdAt;

  const PerfilModel({
    required this.id,
    required this.nombre,
    required this.email,
    required this.createdAt,
  });

  factory PerfilModel.fromJson(Map<String, dynamic> json) => PerfilModel(
        id: json['id'] as String,
        nombre: json['nombre'] as String,
        email: json['email'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'nombre': nombre,
        'email': email,
      };
}

class ProyectoModel {
  final String id;
  final String nombre;
  final String? descripcion;
  final String monedaSimbolo;
  final String monedaCodigo;
  final String? productoDefault;
  final String? tipoUnidadDefault;
  final String? unidadMedidaDefault;
  final double? cantidadPorUnidadDefault;
  final String creadoPor;
  final String tipoPlantilla;
  final DateTime createdAt;

  const ProyectoModel({
    required this.id,
    required this.nombre,
    this.descripcion,
    required this.monedaSimbolo,
    required this.monedaCodigo,
    this.productoDefault,
    this.tipoUnidadDefault,
    this.unidadMedidaDefault,
    this.cantidadPorUnidadDefault,
    required this.creadoPor,
    this.tipoPlantilla = 'COMERCIO',
    required this.createdAt,
  });

  factory ProyectoModel.fromJson(Map<String, dynamic> json) => ProyectoModel(
        id: json['id'] as String,
        nombre: json['nombre'] as String,
        descripcion: json['descripcion'] as String?,
        monedaSimbolo: json['moneda_simbolo'] as String,
        monedaCodigo: json['moneda_codigo'] as String,
        productoDefault: json['producto_default'] as String?,
        tipoUnidadDefault: json['tipo_unidad_default'] as String?,
        unidadMedidaDefault: json['unidad_medida_default'] as String?,
        cantidadPorUnidadDefault: json['cantidad_por_unidad_default'] != null
            ? (json['cantidad_por_unidad_default'] as num).toDouble()
            : null,
        creadoPor: json['creado_por'] as String,
        tipoPlantilla: json['tipo_plantilla'] as String? ?? 'COMERCIO',
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'nombre': nombre,
        'descripcion': descripcion,
        'moneda_simbolo': monedaSimbolo,
        'moneda_codigo': monedaCodigo,
        'producto_default': productoDefault,
        'tipo_unidad_default': tipoUnidadDefault,
        'unidad_medida_default': unidadMedidaDefault,
        'cantidad_por_unidad_default': cantidadPorUnidadDefault,
        'tipo_plantilla': tipoPlantilla,
        'creado_por': creadoPor,
      };
}

class EmpaqueModel {
  final String id;
  final String proyectoId;
  final String nombre;
  final String unidadMedida;
  final double cantidadPorUnidad;
  final String? descripcion;
  final DateTime createdAt;

  const EmpaqueModel({
    required this.id,
    required this.proyectoId,
    required this.nombre,
    required this.unidadMedida,
    required this.cantidadPorUnidad,
    this.descripcion,
    required this.createdAt,
  });

  factory EmpaqueModel.fromJson(Map<String, dynamic> json) => EmpaqueModel(
        id: json['id'] as String,
        proyectoId: json['proyecto_id'] as String,
        nombre: json['nombre'] as String,
        unidadMedida: json['unidad_medida'] as String,
        cantidadPorUnidad: (json['cantidad_por_unidad'] as num).toDouble(),
        descripcion: json['descripcion'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'nombre': nombre,
        'unidad_medida': unidadMedida,
        'cantidad_por_unidad': cantidadPorUnidad,
        if (descripcion != null) 'descripcion': descripcion,
      };
}

class CuentaModel {
  final String id;
  final String proyectoId;
  final String nombre;
  final String producto;
  final String tipoUnidad;
  final String unidadMedida;
  final double cantidadUnidades;
  final double cantidadPorUnidad;
  final double stockTotal;
  final double inversionTotal;
  final double precioUnitario;
  final String estado;
  final String creadoPor;
  final String? cerradoPor;
  final DateTime fechaApertura;
  final DateTime? fechaCierre;
  final DateTime createdAt;

  const CuentaModel({
    required this.id,
    required this.proyectoId,
    required this.nombre,
    required this.producto,
    required this.tipoUnidad,
    required this.unidadMedida,
    required this.cantidadUnidades,
    required this.cantidadPorUnidad,
    required this.stockTotal,
    required this.inversionTotal,
    required this.precioUnitario,
    required this.estado,
    required this.creadoPor,
    this.cerradoPor,
    required this.fechaApertura,
    this.fechaCierre,
    required this.createdAt,
  });

  factory CuentaModel.fromJson(Map<String, dynamic> json) => CuentaModel(
        id: json['id'] as String,
        proyectoId: json['proyecto_id'] as String,
        nombre: json['nombre'] as String,
        producto: json['producto'] as String,
        tipoUnidad: json['tipo_unidad'] as String,
        unidadMedida: json['unidad_medida'] as String? ?? 'und',
        cantidadUnidades: (json['cantidad_unidades'] as num).toDouble(),
        cantidadPorUnidad: (json['cantidad_por_unidad'] as num).toDouble(),
        stockTotal: (json['stock_total'] as num).toDouble(),
        inversionTotal: (json['inversion_total'] as num).toDouble(),
        precioUnitario: (json['precio_unitario'] as num).toDouble(),
        estado: json['estado'] as String,
        creadoPor: json['creado_por'] as String,
        cerradoPor: json['cerrado_por'] as String?,
        fechaApertura: DateTime.parse(json['fecha_apertura'] as String),
        fechaCierre: json['fecha_cierre'] != null
            ? DateTime.parse(json['fecha_cierre'] as String)
            : null,
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'proyecto_id': proyectoId,
        'nombre': nombre,
        'producto': producto,
        'tipo_unidad': tipoUnidad,
        'unidad_medida': unidadMedida,
        'cantidad_unidades': cantidadUnidades,
        'cantidad_por_unidad': cantidadPorUnidad,
        'inversion_total': inversionTotal,
        'precio_unitario': precioUnitario,
        'creado_por': creadoPor,
        'fecha_apertura': fechaApertura.toIso8601String().substring(0, 10),
      };

  double get ingresosEstimados => stockTotal * precioUnitario;
  double get gananciaEstimada => ingresosEstimados - inversionTotal;
  bool get estaAbierta => estado == 'abierta';
}

class VentaModel {
  final String id;
  final String cuentaId;
  final String registradoPor;
  final String registradoPorNombre;
  final String cliente;
  final double cantidadVendida;
  final double precioUnitario;
  final double totalVenta;
  final double totalAbonado;
  final double saldoPendiente;
  final String estadoPago;
  final DateTime fechaVenta;
  final DateTime createdAt;

  const VentaModel({
    required this.id,
    required this.cuentaId,
    required this.registradoPor,
    required this.registradoPorNombre,
    required this.cliente,
    required this.cantidadVendida,
    required this.precioUnitario,
    required this.totalVenta,
    required this.totalAbonado,
    required this.saldoPendiente,
    required this.estadoPago,
    required this.fechaVenta,
    required this.createdAt,
  });

  factory VentaModel.fromJson(Map<String, dynamic> json) => VentaModel(
        id: json['id'] as String,
        cuentaId: json['cuenta_id'] as String,
        registradoPor: json['registrado_por'] as String,
        registradoPorNombre: json['registrado_por_nombre'] as String? ?? '',
        cliente: json['cliente'] as String,
        cantidadVendida: (json['cantidad_vendida'] as num).toDouble(),
        precioUnitario: (json['precio_unitario'] as num).toDouble(),
        totalVenta: (json['total_venta'] as num).toDouble(),
        totalAbonado: (json['total_abonado'] as num).toDouble(),
        saldoPendiente: (json['saldo_pendiente'] as num).toDouble(),
        estadoPago: json['estado_pago'] as String,
        fechaVenta: DateTime.parse(json['fecha_venta'] as String),
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'cuenta_id': cuentaId,
        'registrado_por': registradoPor,
        'cliente': cliente,
        'cantidad_vendida': cantidadVendida,
        'precio_unitario': precioUnitario,
        'fecha_venta': fechaVenta.toIso8601String().substring(0, 10),
      };

  bool get isPagado => estadoPago == 'Pagado';
  bool get isPendiente => estadoPago == 'Pendiente';
  bool get isParcial => estadoPago == 'Parcial';
}

class AbonoModel {
  final String id;
  final String ventaId;
  final String registradoPor;
  final double monto;
  final String? nota;
  final DateTime fechaAbono;
  final DateTime createdAt;

  const AbonoModel({
    required this.id,
    required this.ventaId,
    required this.registradoPor,
    required this.monto,
    this.nota,
    required this.fechaAbono,
    required this.createdAt,
  });

  factory AbonoModel.fromJson(Map<String, dynamic> json) => AbonoModel(
        id: json['id'] as String,
        ventaId: json['venta_id'] as String,
        registradoPor: json['registrado_por'] as String,
        monto: (json['monto'] as num).toDouble(),
        nota: json['nota'] as String?,
        fechaAbono: DateTime.parse(json['fecha_abono'] as String),
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'venta_id': ventaId,
        'registrado_por': registradoPor,
        'monto': monto,
        'nota': nota,
        'fecha_abono': fechaAbono.toIso8601String().substring(0, 10),
      };
}

class AbonoDetalleModel extends AbonoModel {
  final String cliente;
  final String? registradoPorNombre;

  const AbonoDetalleModel({
    required super.id,
    required super.ventaId,
    required super.registradoPor,
    required super.monto,
    super.nota,
    required super.fechaAbono,
    required super.createdAt,
    required this.cliente,
    this.registradoPorNombre,
  });

  factory AbonoDetalleModel.fromJson(Map<String, dynamic> json) =>
      AbonoDetalleModel(
        id: json['id'] as String,
        ventaId: json['venta_id'] as String,
        registradoPor: json['registrado_por'] as String,
        monto: (json['monto'] as num).toDouble(),
        nota: json['nota'] as String?,
        fechaAbono: DateTime.parse(json['fecha_abono'] as String),
        createdAt: DateTime.parse(json['created_at'] as String),
        cliente: json['cliente'] as String,
        registradoPorNombre: json['registrado_por_nombre'] as String?,
      );
}

class GastoModel {
  final String id;
  final String cuentaId;
  final String registradoPor;
  final String registradoPorNombre;
  final String descripcion;
  final String? categoria;
  final double monto;
  final DateTime fechaGasto;
  final DateTime createdAt;

  const GastoModel({
    required this.id,
    required this.cuentaId,
    required this.registradoPor,
    required this.registradoPorNombre,
    required this.descripcion,
    this.categoria,
    required this.monto,
    required this.fechaGasto,
    required this.createdAt,
  });

  factory GastoModel.fromJson(Map<String, dynamic> json) => GastoModel(
        id: json['id'] as String,
        cuentaId: json['cuenta_id'] as String,
        registradoPor: json['registrado_por'] as String,
        registradoPorNombre: json['registrado_por_nombre'] as String? ?? '',
        descripcion: json['descripcion'] as String,
        categoria: json['categoria'] as String?,
        monto: (json['monto'] as num).toDouble(),
        fechaGasto: DateTime.parse(json['fecha_gasto'] as String),
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'cuenta_id': cuentaId,
        'registrado_por': registradoPor,
        'descripcion': descripcion,
        'categoria': categoria,
        'monto': monto,
        'fecha_gasto': fechaGasto.toIso8601String().substring(0, 10),
      };
}

class CuentaResumenModel {
  final String id;
  final String proyectoId;
  final String nombre;
  final String producto;
  final String tipoUnidad;
  final String unidadMedida;
  final double cantidadUnidades;
  final double cantidadPorUnidad;
  final double stockTotal;
  final double inversionTotal;
  final double precioUnitario;
  final String estado;
  final DateTime fechaApertura;
  final DateTime? fechaCierre;
  final double ingresosBrutos;
  final double cantidadVendida;
  final double stockRestante;
  final double totalCobrado;
  final double totalGastos;
  final double gananciaReal;

  const CuentaResumenModel({
    required this.id,
    required this.proyectoId,
    required this.nombre,
    required this.producto,
    required this.tipoUnidad,
    required this.unidadMedida,
    required this.cantidadUnidades,
    required this.cantidadPorUnidad,
    required this.stockTotal,
    required this.inversionTotal,
    required this.precioUnitario,
    required this.estado,
    required this.fechaApertura,
    this.fechaCierre,
    required this.ingresosBrutos,
    required this.cantidadVendida,
    required this.stockRestante,
    required this.totalCobrado,
    required this.totalGastos,
    required this.gananciaReal,
  });

  factory CuentaResumenModel.fromJson(Map<String, dynamic> json) =>
      CuentaResumenModel(
        id: json['id'] as String,
        proyectoId: json['proyecto_id'] as String,
        nombre: json['nombre'] as String,
        producto: json['producto'] as String,
        tipoUnidad: json['tipo_unidad'] as String,
        unidadMedida: json['unidad_medida'] as String? ?? 'und',
        cantidadUnidades: (json['cantidad_unidades'] as num).toDouble(),
        cantidadPorUnidad: (json['cantidad_por_unidad'] as num).toDouble(),
        stockTotal: (json['stock_total'] as num).toDouble(),
        inversionTotal: (json['inversion_total'] as num).toDouble(),
        precioUnitario: (json['precio_unitario'] as num).toDouble(),
        estado: json['estado'] as String,
        fechaApertura: DateTime.parse(json['fecha_apertura'] as String),
        fechaCierre: json['fecha_cierre'] != null
            ? DateTime.parse(json['fecha_cierre'] as String)
            : null,
        ingresosBrutos: (json['ingresos_brutos'] as num).toDouble(),
        cantidadVendida: (json['cantidad_vendida'] as num).toDouble(),
        stockRestante: (json['stock_restante'] as num).toDouble(),
        totalCobrado: (json['total_cobrado'] as num).toDouble(),
        totalGastos: (json['total_gastos'] as num).toDouble(),
        gananciaReal: (json['ganancia_real'] as num).toDouble(),
      );

  bool get estaAbierta => estado == 'abierta';
  double get porcentajeVendido =>
      stockTotal > 0 ? (cantidadVendida / stockTotal).clamp(0.0, 1.0) : 0.0;
  double get ingresosEstimados => stockTotal * precioUnitario;
  double get gananciaEstimada => ingresosEstimados - inversionTotal;
}

class TransaccionGeneralModel {
  final String id;
  final String proyectoId;
  final String registradoPor;
  final String registradoPorNombre;
  final String tipo;
  final String descripcion;
  final double monto;
  final DateTime fechaTransaccion;
  final DateTime createdAt;

  const TransaccionGeneralModel({
    required this.id,
    required this.proyectoId,
    required this.registradoPor,
    required this.registradoPorNombre,
    required this.tipo,
    required this.descripcion,
    required this.monto,
    required this.fechaTransaccion,
    required this.createdAt,
  });

  factory TransaccionGeneralModel.fromJson(Map<String, dynamic> json) =>
      TransaccionGeneralModel(
        id: json['id'] as String,
        proyectoId: json['proyecto_id'] as String,
        registradoPor: json['registrado_por'] as String,
        registradoPorNombre:
            json['registrado_por_nombre'] as String? ?? 'Desconocido',
        tipo: json['tipo'] as String,
        descripcion: json['descripcion'] as String,
        monto: (json['monto'] as num).toDouble(),
        fechaTransaccion:
            DateTime.parse(json['fecha_transaccion'] as String),
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}

class VentaReporteItemModel extends VentaModel {
  final String cuentaNombre;

  const VentaReporteItemModel({
    required super.id,
    required super.cuentaId,
    required super.registradoPor,
    required super.registradoPorNombre,
    required super.cliente,
    required super.cantidadVendida,
    required super.precioUnitario,
    required super.totalVenta,
    required super.totalAbonado,
    required super.saldoPendiente,
    required super.estadoPago,
    required super.fechaVenta,
    required super.createdAt,
    required this.cuentaNombre,
  });

  factory VentaReporteItemModel.fromJson(Map<String, dynamic> json) =>
      VentaReporteItemModel(
        id: json['id'] as String,
        cuentaId: json['cuenta_id'] as String,
        registradoPor: json['registrado_por'] as String,
        registradoPorNombre:
            json['registrado_por_nombre'] as String? ?? 'Desconocido',
        cliente: json['cliente'] as String,
        cantidadVendida: (json['cantidad_vendida'] as num).toDouble(),
        precioUnitario: (json['precio_unitario'] as num).toDouble(),
        totalVenta: (json['total_venta'] as num).toDouble(),
        totalAbonado: (json['total_abonado'] as num).toDouble(),
        saldoPendiente: (json['saldo_pendiente'] as num).toDouble(),
        estadoPago: json['estado_pago'] as String,
        fechaVenta: DateTime.parse(json['fecha_venta'] as String),
        createdAt: DateTime.parse(json['created_at'] as String),
        cuentaNombre: json['cuenta_nombre'] as String,
      );
}

class GastoReporteItemModel extends GastoModel {
  final String cuentaNombre;

  const GastoReporteItemModel({
    required super.id,
    required super.cuentaId,
    required super.registradoPor,
    required super.registradoPorNombre,
    required super.descripcion,
    super.categoria,
    required super.monto,
    required super.fechaGasto,
    required super.createdAt,
    required this.cuentaNombre,
  });

  factory GastoReporteItemModel.fromJson(Map<String, dynamic> json) =>
      GastoReporteItemModel(
        id: json['id'] as String,
        cuentaId: json['cuenta_id'] as String,
        registradoPor: json['registrado_por'] as String,
        registradoPorNombre:
            json['registrado_por_nombre'] as String? ?? 'Desconocido',
        descripcion: json['descripcion'] as String,
        categoria: json['categoria'] as String?,
        monto: (json['monto'] as num).toDouble(),
        fechaGasto: DateTime.parse(json['fecha_gasto'] as String),
        createdAt: DateTime.parse(json['created_at'] as String),
        cuentaNombre: json['cuenta_nombre'] as String,
      );
}

class AbonoReporteItemModel extends AbonoModel {
  final String cuentaNombre;
  final String? cliente;
  final String registradoPorNombre;

  const AbonoReporteItemModel({
    required super.id,
    required super.ventaId,
    required super.registradoPor,
    required this.registradoPorNombre,
    required super.monto,
    required super.fechaAbono,
    super.nota,
    required super.createdAt,
    required this.cuentaNombre,
    this.cliente,
  });

  factory AbonoReporteItemModel.fromJson(Map<String, dynamic> json) =>
      AbonoReporteItemModel(
        id: json['id'] as String,
        ventaId: json['venta_id'] as String,
        registradoPor: json['registrado_por'] as String,
        registradoPorNombre:
            json['registrado_por_nombre'] as String? ?? 'Desconocido',
        monto: (json['monto'] as num).toDouble(),
        fechaAbono: DateTime.parse(json['fecha_abono'] as String),
        nota: json['nota'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
        cuentaNombre: json['cuenta_nombre'] as String,
        cliente: json['cliente'] as String?,
      );
}

class ProyectoReporteData {
  final String proyectoId;
  final String proyectoNombre;
  final double inversionTotal;
  final double ingresosBrutos;
  final double totalCobrado;
  final double totalGastos;
  final double gananciaReal;
  final double stockTotal;
  final double cantidadVendida;
  final double stockRestante;
  final List<VentaReporteItemModel> ventas;
  final List<GastoReporteItemModel> gastos;
  final List<AbonoReporteItemModel> abonos;

  const ProyectoReporteData({
    required this.proyectoId,
    required this.proyectoNombre,
    required this.inversionTotal,
    required this.ingresosBrutos,
    required this.totalCobrado,
    required this.totalGastos,
    required this.gananciaReal,
    required this.stockTotal,
    required this.cantidadVendida,
    required this.stockRestante,
    required this.ventas,
    required this.gastos,
    required this.abonos,
  });

  factory ProyectoReporteData.fromJson(Map<String, dynamic> json) =>
      ProyectoReporteData(
        proyectoId: json['proyecto_id'] as String,
        proyectoNombre: json['proyecto_nombre'] as String,
        inversionTotal: (json['inversion_total'] as num).toDouble(),
        ingresosBrutos: (json['ingresos_brutos'] as num).toDouble(),
        totalCobrado: (json['total_cobrado'] as num).toDouble(),
        totalGastos: (json['total_gastos'] as num).toDouble(),
        gananciaReal: (json['ganancia_real'] as num).toDouble(),
        stockTotal: (json['stock_total'] as num).toDouble(),
        cantidadVendida: (json['cantidad_vendida'] as num).toDouble(),
        stockRestante: (json['stock_restante'] as num).toDouble(),
        ventas: (json['ventas'] as List)
            .map((v) => VentaReporteItemModel.fromJson(v))
            .toList(),
        gastos: (json['gastos'] as List)
            .map((g) => GastoReporteItemModel.fromJson(g))
            .toList(),
        abonos: (json['abonos'] as List)
            .map((a) => AbonoReporteItemModel.fromJson(a))
            .toList(),
      );
}
