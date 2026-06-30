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
  final String creadoPor;
  final DateTime createdAt;

  const ProyectoModel({
    required this.id,
    required this.nombre,
    this.descripcion,
    required this.monedaSimbolo,
    required this.monedaCodigo,
    required this.creadoPor,
    required this.createdAt,
  });

  factory ProyectoModel.fromJson(Map<String, dynamic> json) => ProyectoModel(
        id: json['id'] as String,
        nombre: json['nombre'] as String,
        descripcion: json['descripcion'] as String?,
        monedaSimbolo: json['moneda_simbolo'] as String,
        monedaCodigo: json['moneda_codigo'] as String,
        creadoPor: json['creado_por'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'nombre': nombre,
        'descripcion': descripcion,
        'moneda_simbolo': monedaSimbolo,
        'moneda_codigo': monedaCodigo,
        'creado_por': creadoPor,
      };
}

class CuentaModel {
  final String id;
  final String proyectoId;
  final String nombre;
  final String producto;
  final String tipoUnidad;
  final double cantidadUnidades;
  final double kgPorUnidad;
  final double kilosTotales;
  final double inversionTotal;
  final double precioVentaKg;
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
    required this.cantidadUnidades,
    required this.kgPorUnidad,
    required this.kilosTotales,
    required this.inversionTotal,
    required this.precioVentaKg,
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
        cantidadUnidades: (json['cantidad_unidades'] as num).toDouble(),
        kgPorUnidad: (json['kg_por_unidad'] as num).toDouble(),
        kilosTotales: (json['kilos_totales'] as num).toDouble(),
        inversionTotal: (json['inversion_total'] as num).toDouble(),
        precioVentaKg: (json['precio_venta_kg'] as num).toDouble(),
        estado: json['estado'] as String,
        creadoPor: json['creado_por'] as String,
        cerradoPor: json['cerrado_por'] as String?,
        fechaApertura: DateTime.parse(json['fecha_apertura'] as String),
        fechaCierre: json['fecha_cierre'] != null ? DateTime.parse(json['fecha_cierre'] as String) : null,
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'proyecto_id': proyectoId,
        'nombre': nombre,
        'producto': producto,
        'tipo_unidad': tipoUnidad,
        'cantidad_unidades': cantidadUnidades,
        'kg_por_unidad': kgPorUnidad,
        'inversion_total': inversionTotal,
        'precio_venta_kg': precioVentaKg,
        'creado_por': creadoPor,
        'fecha_apertura': fechaApertura.toIso8601String().substring(0, 10),
      };

  double get ingresosEstimados => kilosTotales * precioVentaKg;
  double get gananciaEstimada => ingresosEstimados - inversionTotal;
  bool get estaAbierta => estado == 'abierta';
}

class VentaModel {
  final String id;
  final String cuentaId;
  final String registradoPor;
  final String registradoPorNombre;
  final String cliente;
  final double kilosVendidos;
  final double precioPorKg;
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
    required this.kilosVendidos,
    required this.precioPorKg,
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
        kilosVendidos: (json['kilos_vendidos'] as num).toDouble(),
        precioPorKg: (json['precio_por_kg'] as num).toDouble(),
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
        'kilos_vendidos': kilosVendidos,
        'precio_por_kg': precioPorKg,
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

  factory AbonoDetalleModel.fromJson(Map<String, dynamic> json) => AbonoDetalleModel(
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
  final double monto;
  final DateTime fechaGasto;
  final DateTime createdAt;

  const GastoModel({
    required this.id,
    required this.cuentaId,
    required this.registradoPor,
    required this.registradoPorNombre,
    required this.descripcion,
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
        monto: (json['monto'] as num).toDouble(),
        fechaGasto: DateTime.parse(json['fecha_gasto'] as String),
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'cuenta_id': cuentaId,
        'registrado_por': registradoPor,
        'descripcion': descripcion,
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
  final double cantidadUnidades;
  final double kgPorUnidad;
  final double kilosTotales;
  final double inversionTotal;
  final double precioVentaKg;
  final String estado;
  final DateTime fechaApertura;
  final DateTime? fechaCierre;
  final double ingresosBrutos;
  final double kilosVendidos;
  final double kilosRestantes;
  final double totalCobrado;
  final double totalGastos;
  final double gananciaReal;

  const CuentaResumenModel({
    required this.id,
    required this.proyectoId,
    required this.nombre,
    required this.producto,
    required this.tipoUnidad,
    required this.cantidadUnidades,
    required this.kgPorUnidad,
    required this.kilosTotales,
    required this.inversionTotal,
    required this.precioVentaKg,
    required this.estado,
    required this.fechaApertura,
    this.fechaCierre,
    required this.ingresosBrutos,
    required this.kilosVendidos,
    required this.kilosRestantes,
    required this.totalCobrado,
    required this.totalGastos,
    required this.gananciaReal,
  });

  factory CuentaResumenModel.fromJson(Map<String, dynamic> json) => CuentaResumenModel(
        id: json['id'] as String,
        proyectoId: json['proyecto_id'] as String,
        nombre: json['nombre'] as String,
        producto: json['producto'] as String,
        tipoUnidad: json['tipo_unidad'] as String,
        cantidadUnidades: (json['cantidad_unidades'] as num).toDouble(),
        kgPorUnidad: (json['kg_por_unidad'] as num).toDouble(),
        kilosTotales: (json['kilos_totales'] as num).toDouble(),
        inversionTotal: (json['inversion_total'] as num).toDouble(),
        precioVentaKg: (json['precio_venta_kg'] as num).toDouble(),
        estado: json['estado'] as String,
        fechaApertura: DateTime.parse(json['fecha_apertura'] as String),
        fechaCierre: json['fecha_cierre'] != null ? DateTime.parse(json['fecha_cierre'] as String) : null,
        ingresosBrutos: (json['ingresos_brutos'] as num).toDouble(),
        kilosVendidos: (json['kilos_vendidos'] as num).toDouble(),
        kilosRestantes: (json['kilos_restantes'] as num).toDouble(),
        totalCobrado: (json['total_cobrado'] as num).toDouble(),
        totalGastos: (json['total_gastos'] as num).toDouble(),
        gananciaReal: (json['ganancia_real'] as num).toDouble(),
      );

  bool get estaAbierta => estado == 'abierta';
  double get porcentajeVendido => kilosTotales > 0 ? (kilosVendidos / kilosTotales).clamp(0.0, 1.0) : 0.0;
  double get ingresosEstimados => kilosTotales * precioVentaKg;
  double get gananciaEstimada => ingresosEstimados - inversionTotal;
}
