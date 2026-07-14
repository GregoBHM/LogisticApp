import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/models/models.dart';
import '../providers/project_providers.dart';
import '../../../core/network/error_handler.dart';

class CuentaDetalleScreen extends ConsumerWidget {
  final CuentaResumenModel cuenta;
  final String proyectoNombre;
  final String monedaSimbolo;
  final String tipoPlantilla;

  const CuentaDetalleScreen({
    super.key,
    required this.cuenta,
    required this.proyectoNombre,
    this.monedaSimbolo = 'S/',
    this.tipoPlantilla = 'COMERCIO',
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cuentasAsync = ref.watch(cuentasProvider(cuenta.proyectoId));
    final liveCuenta =
        cuentasAsync.value?.firstWhere(
          (c) => c.id == cuenta.id,
          orElse: () => cuenta,
        ) ??
        cuenta;

    final ventasAsync = ref.watch(ventasProvider(liveCuenta.id));
    final gastosAsync = ref.watch(gastosFamilyProvider(liveCuenta.id));

    final estaAbierta = liveCuenta.estado == 'abierta';

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 16),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(tipoPlantilla == 'TRANSPORTE' ? cuenta.nombre : cuenta.producto),
        actions: [
          if (estaAbierta)
            IconButton(
              icon: const Icon(Icons.lock_outline, size: 18),
              onPressed: () => _cerrarCuenta(context, ref),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(ventasProvider(cuenta.id));
          ref.invalidate(gastosFamilyProvider(cuenta.id));
          ref.invalidate(abonosCuentaProvider(cuenta.id));
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
          children: [
            _buildResumenCard(context, liveCuenta),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  tipoPlantilla == 'TRANSPORTE' ? 'Fletes / Ingresos' : 'Ventas',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.5,
                  ),
                ),
                if (estaAbierta)
                  GestureDetector(
                    onTap: () => _showNuevaVentaSheet(context, ref, liveCuenta),
                    child: Text(
                      tipoPlantilla == 'TRANSPORTE' ? '+ Registrar Flete' : '+ Nueva Venta',
                      style: const TextStyle(
                        color: AppColors.cream,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            ventasAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text(ErrorHandler.parse(e)),
              data: (ventas) {
                if (ventas.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(
                      child: Text(
                        'No hay ventas registradas',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  );
                }
                return Column(
                  children: ventas
                      .map((v) => _buildVentaRow(context, ref, v, liveCuenta))
                      .toList(),
                );
              },
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  tipoPlantilla == 'TRANSPORTE' ? 'Gastos del Vehículo' : 'Gastos Operativos',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.5,
                  ),
                ),
                if (estaAbierta)
                  GestureDetector(
                    onTap: () => _showNuevoGastoSheet(context, ref, liveCuenta),
                    child: const Text(
                      '+ Añadir Gasto',
                      style: TextStyle(
                        color: AppColors.cream,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            gastosAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text(ErrorHandler.parse(e)),
              data: (gastos) {
                if (gastos.isEmpty) {
                  return const Text(
                    'No hay gastos registrados.',
                    style: TextStyle(color: AppColors.textMuted),
                  );
                }
                return Column(
                  children: gastos
                      .map((g) => _buildGastoRow(context, ref, g, liveCuenta))
                      .toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResumenCard(
    BuildContext context,
    CuentaResumenModel liveCuenta,
  ) {
    final ganancia = liveCuenta.gananciaReal;
    final esPositivo = ganancia >= 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Balance Real',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${esPositivo ? '+' : ''}${ganancia.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: esPositivo
                          ? AppColors.positive
                          : AppColors.negative,
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: liveCuenta.estado == 'abierta'
                      ? AppColors.positiveSubtle
                      : AppColors.negativeSubtle,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  liveCuenta.estado == 'abierta' ? 'En Curso' : 'Finalizado',
                  style: TextStyle(
                    color: liveCuenta.estado == 'abierta'
                        ? AppColors.positive
                        : AppColors.negative,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              _resumenStat(
                tipoPlantilla == 'TRANSPORTE' ? 'Inv. Inicial' : 'Inversión',
                liveCuenta.inversionTotal.toStringAsFixed(2),
                Icons.arrow_upward,
                AppColors.negative,
              ),
              _resumenStat(
                tipoPlantilla == 'TRANSPORTE' ? 'Cobrado' : 'Ingresos',
                liveCuenta.totalCobrado.toStringAsFixed(2),
                Icons.arrow_downward,
                AppColors.positive,
              ),
              _resumenStat(
                tipoPlantilla == 'TRANSPORTE' ? 'Viajes' : 'Stock',
                tipoPlantilla == 'TRANSPORTE'
                    ? '${liveCuenta.stockRestante.toStringAsFixed(0)} realizados'
                    : '${liveCuenta.stockRestante.toStringAsFixed(0)} ${liveCuenta.unidadMedida}',
                tipoPlantilla == 'TRANSPORTE' ? Icons.local_shipping_rounded : Icons.inventory_2_outlined,
                AppColors.cream,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _resumenStat(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVentaRow(
    BuildContext context,
    WidgetRef ref,
    VentaModel v,
    CuentaResumenModel liveCuenta,
  ) {
    final pagado = v.estadoPago == 'Cancelado' || v.estadoPago == 'Pagado';
    return GestureDetector(
      onTap: () {
        _showOpcionesVentaSheet(context, ref, v, liveCuenta);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.person_outline,
                color: AppColors.textSecondary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    v.cliente,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${DateFormat('dd MMM yyyy', 'es').format(v.fechaVenta)} • ${v.cantidadVendida.toStringAsFixed(1)} ${liveCuenta.unidadMedida} a ${v.precioUnitario.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  v.totalVenta.toStringAsFixed(2),
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: pagado
                        ? AppColors.positiveSubtle
                        : AppColors.cream.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    pagado ? 'Cancelado' : v.estadoPago,
                    style: TextStyle(
                      color: pagado ? AppColors.positive : AppColors.cream,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGastoRow(
    BuildContext context,
    WidgetRef ref,
    GastoModel g,
    CuentaResumenModel liveCuenta,
  ) {
    return GestureDetector(
      onTap: () {
        _showOpcionesGastoSheet(context, ref, g, liveCuenta);
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.negativeSubtle,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.money_off,
                color: AppColors.negative,
                size: 14,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    g.descripcion,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    DateFormat('dd MMM yyyy', 'es').format(g.fechaGasto),
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '-${g.monto.toStringAsFixed(2)}',
              style: const TextStyle(
                color: AppColors.negative,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showOpcionesVentaSheet(
    BuildContext context,
    WidgetRef ref,
    VentaModel v,
    CuentaResumenModel liveCuenta,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.borderLight,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Opciones de Venta',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                v.cliente,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 20),
              if (v.estadoPago != 'Cancelado' && v.estadoPago != 'Pagado')
                ListTile(
                  leading: const Icon(
                    Icons.attach_money,
                    color: AppColors.positive,
                  ),
                  title: const Text(
                    'Registrar Pago',
                    style: TextStyle(color: AppColors.textPrimary),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _showAbonoSheet(context, ref, v, liveCuenta);
                  },
                ),
              ListTile(
                leading: const Icon(
                  Icons.history,
                  color: AppColors.textSecondary,
                ),
                title: const Text(
                  'Historial de Pagos',
                  style: TextStyle(color: AppColors.textPrimary),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _showAbonosHistorySheet(context, ref, v, liveCuenta);
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.edit_outlined,
                  color: AppColors.cream,
                ),
                title: const Text(
                  'Editar Venta',
                  style: TextStyle(color: AppColors.textPrimary),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _showEditarVentaSheet(context, ref, v, liveCuenta);
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.delete_outline,
                  color: AppColors.negative,
                ),
                title: const Text(
                  'Eliminar Venta',
                  style: TextStyle(color: AppColors.textPrimary),
                ),
                onTap: () async {
                  Navigator.pop(ctx);
                  final confirmar = await showDialog<bool>(
                    context: context,
                    builder: (c) => AlertDialog(
                      backgroundColor: AppColors.surface,
                      title: const Text(
                        '¿Eliminar venta?',
                        style: TextStyle(color: AppColors.textPrimary),
                      ),
                      content: const Text(
                        'El stock se restaurará a la cuenta.',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(c, false),
                          child: const Text(
                            'Cancelar',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(c, true),
                          child: const Text(
                            'Eliminar',
                            style: TextStyle(color: AppColors.negative),
                          ),
                        ),
                      ],
                    ),
                  );
                  if (confirmar == true) {
                    try {
                      await ref
                          .read(ventaRepositoryProvider)
                          .eliminarVenta(v.id);
                      if (context.mounted) {
                        ref.invalidate(ventasProvider(liveCuenta.id));
                        ref.invalidate(cuentasProvider(liveCuenta.proyectoId));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Venta eliminada')),
                        );
                      }
                    } catch (e) {
                      if (context.mounted)
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(ErrorHandler.parse(e))),
                        );
                    }
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showOpcionesGastoSheet(
    BuildContext context,
    WidgetRef ref,
    GastoModel g,
    CuentaResumenModel liveCuenta,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.borderLight,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Opciones de Gasto',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(
                  Icons.edit_outlined,
                  color: AppColors.cream,
                ),
                title: const Text(
                  'Editar Gasto',
                  style: TextStyle(color: AppColors.textPrimary),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _showEditarGastoSheet(context, ref, g, liveCuenta);
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.delete_outline,
                  color: AppColors.negative,
                ),
                title: const Text(
                  'Eliminar Gasto',
                  style: TextStyle(color: AppColors.textPrimary),
                ),
                onTap: () async {
                  Navigator.pop(ctx);
                  final confirmar = await showDialog<bool>(
                    context: context,
                    builder: (c) => AlertDialog(
                      backgroundColor: AppColors.surface,
                      title: const Text(
                        '¿Eliminar gasto?',
                        style: TextStyle(color: AppColors.textPrimary),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(c, false),
                          child: const Text(
                            'Cancelar',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(c, true),
                          child: const Text(
                            'Eliminar',
                            style: TextStyle(color: AppColors.negative),
                          ),
                        ),
                      ],
                    ),
                  );
                  if (confirmar == true) {
                    try {
                      await ref
                          .read(gastoRepositoryProvider)
                          .eliminarGasto(g.id);
                      if (context.mounted) {
                        ref.invalidate(gastosFamilyProvider(liveCuenta.id));
                        ref.invalidate(cuentasProvider(liveCuenta.proyectoId));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Gasto eliminado')),
                        );
                      }
                    } catch (e) {
                      if (context.mounted)
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(ErrorHandler.parse(e))),
                        );
                    }
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditarVentaSheet(
    BuildContext context,
    WidgetRef ref,
    VentaModel v,
    CuentaResumenModel liveCuenta,
  ) {
    final clienteCtrl = TextEditingController(text: v.cliente);
    final cantidadCtrl = TextEditingController(
      text: v.cantidadVendida.toString(),
    );
    final precioCtrl = TextEditingController(text: v.precioUnitario.toString());
    final totalCtrl = TextEditingController(text: v.totalVenta.toString());
    bool loading = false;

    void recalcTotal(void Function(void Function()) setModal) {
      setModal(() {
        final k = double.tryParse(cantidadCtrl.text) ?? 0;
        final p = double.tryParse(precioCtrl.text) ?? 0;
        if (k > 0 && p > 0) totalCtrl.text = (k * p).toStringAsFixed(2);
      });
    }

    void recalcPrecio(void Function(void Function()) setModal) {
      setModal(() {
        final k = double.tryParse(cantidadCtrl.text) ?? 0;
        final t = double.tryParse(totalCtrl.text) ?? 0;
        if (k > 0 && t > 0) precioCtrl.text = (t / k).toStringAsFixed(2);
      });
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx2, setModal) => Padding(
          padding: EdgeInsets.fromLTRB(
            24,
            20,
            24,
            MediaQuery.of(ctx2).viewInsets.bottom + 32,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.borderLight,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Editar Venta',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 20),
                _sheetField(clienteCtrl, 'Cliente', 'Nombre del comprador'),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _sheetField(
                        cantidadCtrl,
                        'Cantidad',
                        'Ej: 29.8',
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                        ],
                        onChanged: (_) {
                          recalcTotal(setModal);
                          recalcPrecio(setModal);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _sheetField(
                        precioCtrl,
                        'Precio unitario',
                        'Ej: 3.50',
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                        ],
                        onChanged: (_) => recalcTotal(setModal),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _sheetField(
                  totalCtrl,
                  'Total',
                  'Ej: 104.30',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                  ],
                  onChanged: (_) => recalcPrecio(setModal),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: loading
                        ? null
                        : () async {
                            if (clienteCtrl.text.isEmpty ||
                                cantidadCtrl.text.isEmpty ||
                                precioCtrl.text.isEmpty)
                              return;
                            setModal(() => loading = true);
                            try {
                              await ref
                                  .read(ventaRepositoryProvider)
                                  .actualizarVenta(
                                    v.id,
                                    cliente: clienteCtrl.text,
                                    cantidadVendida: double.parse(
                                      cantidadCtrl.text,
                                    ),
                                    precioUnitario: double.parse(
                                      precioCtrl.text,
                                    ),
                                    totalVenta: double.tryParse(totalCtrl.text),
                                  );
                              if (context.mounted) {
                                Navigator.pop(context);
                                ref.invalidate(ventasProvider(liveCuenta.id));
                                ref.invalidate(
                                  cuentasProvider(liveCuenta.proyectoId),
                                );
                              }
                            } catch (e) {
                              setModal(() => loading = false);
                              if (context.mounted)
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(ErrorHandler.parse(e)),
                                  ),
                                );
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.cream,
                      foregroundColor: AppColors.background,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: loading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: AppColors.background,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text('Guardar Cambios'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAbonosHistorySheet(
    BuildContext context,
    WidgetRef ref,
    VentaModel v,
    CuentaResumenModel liveCuenta,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (ctx2, scrollController) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.borderLight,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Historial de Pagos',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                v.cliente,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: Consumer(
                  builder: (context, ref, child) {
                    final abonosAsync = ref.watch(abonosProvider(v.id));
                    return abonosAsync.when(
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (e, _) =>
                          Center(child: Text(ErrorHandler.parse(e))),
                      data: (abonos) {
                        if (abonos.isEmpty) {
                          return const Center(
                            child: Text(
                              'No hay pagos registrados',
                              style: TextStyle(color: AppColors.textMuted),
                            ),
                          );
                        }
                        return ListView.builder(
                          controller: scrollController,
                          itemCount: abonos.length,
                          itemBuilder: (context, index) {
                            final abono = abonos[index];
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(
                                'S/ ${abono.monto.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  color: AppColors.positive,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Text(
                                '${DateFormat('dd MMM yyyy').format(abono.fechaAbono)} - ${abono.nota ?? ''}',
                                style: const TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 12,
                                ),
                              ),
                              trailing: IconButton(
                                icon: const Icon(
                                  Icons.more_vert,
                                  color: AppColors.textSecondary,
                                ),
                                onPressed: () {
                                  _showOpcionesAbonoSheet(
                                    context,
                                    ref,
                                    abono,
                                    v,
                                    liveCuenta,
                                  );
                                },
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showOpcionesAbonoSheet(
    BuildContext context,
    WidgetRef ref,
    AbonoModel abono,
    VentaModel v,
    CuentaResumenModel liveCuenta,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.borderLight,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Opciones de Pago',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(
                  Icons.edit_outlined,
                  color: AppColors.cream,
                ),
                title: const Text(
                  'Editar Pago',
                  style: TextStyle(color: AppColors.textPrimary),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _showEditarAbonoSheet(context, ref, abono, v, liveCuenta);
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.delete_outline,
                  color: AppColors.negative,
                ),
                title: const Text(
                  'Eliminar Pago',
                  style: TextStyle(color: AppColors.textPrimary),
                ),
                onTap: () async {
                  Navigator.pop(ctx);
                  final confirmar = await showDialog<bool>(
                    context: context,
                    builder: (c) => AlertDialog(
                      backgroundColor: AppColors.surface,
                      title: const Text(
                        '¿Eliminar pago?',
                        style: TextStyle(color: AppColors.textPrimary),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(c, false),
                          child: const Text(
                            'Cancelar',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(c, true),
                          child: const Text(
                            'Eliminar',
                            style: TextStyle(color: AppColors.negative),
                          ),
                        ),
                      ],
                    ),
                  );
                  if (confirmar == true) {
                    try {
                      await ref
                          .read(ventaRepositoryProvider)
                          .eliminarAbono(abono.id);
                      if (context.mounted) {
                        ref.invalidate(abonosProvider(v.id));
                        ref.invalidate(ventasProvider(liveCuenta.id));
                        ref.invalidate(cuentasProvider(liveCuenta.proyectoId));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Pago eliminado')),
                        );
                      }
                    } catch (e) {
                      if (context.mounted)
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(ErrorHandler.parse(e))),
                        );
                    }
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditarAbonoSheet(
    BuildContext context,
    WidgetRef ref,
    AbonoModel abono,
    VentaModel v,
    CuentaResumenModel liveCuenta,
  ) {
    final montoCtrl = TextEditingController(text: abono.monto.toString());
    final notaCtrl = TextEditingController(text: abono.nota ?? '');
    bool loading = false;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx2, setModal) => Padding(
          padding: EdgeInsets.fromLTRB(
            24,
            20,
            24,
            MediaQuery.of(ctx2).viewInsets.bottom + 32,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.borderLight,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Editar Pago',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 20),
              _sheetField(
                montoCtrl,
                'Monto',
                'Ej: 50.00',
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                ],
              ),
              const SizedBox(height: 12),
              _sheetField(
                notaCtrl,
                'Nota (Opcional)',
                'Ej: Transferencia Yape',
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: loading
                      ? null
                      : () async {
                          if (montoCtrl.text.isEmpty) return;
                          setModal(() => loading = true);
                          try {
                            await ref
                                .read(ventaRepositoryProvider)
                                .actualizarAbono(
                                  abono.id,
                                  monto: double.parse(montoCtrl.text),
                                  nota: notaCtrl.text.trim(),
                                );
                            if (context.mounted) {
                              Navigator.pop(context);
                              ref.invalidate(abonosProvider(v.id));
                              ref.invalidate(ventasProvider(liveCuenta.id));
                              ref.invalidate(
                                cuentasProvider(liveCuenta.proyectoId),
                              );
                            }
                          } catch (e) {
                            setModal(() => loading = false);
                            if (context.mounted)
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(ErrorHandler.parse(e))),
                              );
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.cream,
                    foregroundColor: AppColors.background,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: AppColors.background,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Guardar Cambios'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditarGastoSheet(
    BuildContext context,
    WidgetRef ref,
    GastoModel g,
    CuentaResumenModel liveCuenta,
  ) {
    final descCtrl = TextEditingController(text: g.descripcion);
    final montoCtrl = TextEditingController(text: g.monto.toString());
    bool loading = false;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx2, setModal) => Padding(
          padding: EdgeInsets.fromLTRB(
            24,
            20,
            24,
            MediaQuery.of(ctx2).viewInsets.bottom + 32,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.borderLight,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Editar Gasto',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 20),
              _sheetField(descCtrl, 'Descripción', 'Ej: Pasajes, Estibador...'),
              const SizedBox(height: 12),
              _sheetField(
                montoCtrl,
                'Monto',
                'Ej: 15.50',
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: loading
                      ? null
                      : () async {
                          if (descCtrl.text.isEmpty || montoCtrl.text.isEmpty)
                            return;
                          setModal(() => loading = true);
                          try {
                            await ref
                                .read(gastoRepositoryProvider)
                                .actualizarGasto(
                                  g.id,
                                  descripcion: descCtrl.text,
                                  monto: double.parse(montoCtrl.text),
                                );
                            if (context.mounted) {
                              Navigator.pop(context);
                              ref.invalidate(
                                gastosFamilyProvider(liveCuenta.id),
                              );
                              ref.invalidate(
                                cuentasProvider(liveCuenta.proyectoId),
                              );
                            }
                          } catch (e) {
                            setModal(() => loading = false);
                            if (context.mounted)
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(ErrorHandler.parse(e))),
                              );
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.cream,
                    foregroundColor: AppColors.background,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: AppColors.background,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Guardar Cambios'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showNuevaVentaSheet(
    BuildContext context,
    WidgetRef ref,
    CuentaResumenModel liveCuenta,
  ) {
    final clienteCtrl = TextEditingController();
    final cantidadCtrl = TextEditingController();
    final precioCtrl = TextEditingController(
      text: liveCuenta.precioUnitario.toStringAsFixed(2),
    );
    final totalCtrl = TextEditingController();
    final abonoCtrl = TextEditingController();
    DateTime fechaVenta = DateTime.now();
    bool cobrarAhora = true;
    bool loading = false;
    bool ventaPorMonto = false;

    void recalcTotal(void Function(void Function()) setModal) {
      setModal(() {
        final k = double.tryParse(cantidadCtrl.text) ?? 0;
        final p = double.tryParse(precioCtrl.text) ?? 0;
        if (k > 0 && p > 0) {
          totalCtrl.text = (k * p).toStringAsFixed(2);
        }
      });
    }

    void recalcPrecio(void Function(void Function()) setModal) {
      setModal(() {
        final k = double.tryParse(cantidadCtrl.text) ?? 0;
        final t = double.tryParse(totalCtrl.text) ?? 0;
        if (k > 0 && t > 0) {
          precioCtrl.text = (t / k).toStringAsFixed(2);
        }
      });
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx2, setModal) {
          final total = double.tryParse(totalCtrl.text) ?? 0;
          final abono = cobrarAhora
              ? (double.tryParse(abonoCtrl.text) ?? 0)
              : 0.0;
          final saldo = (total - abono).clamp(0.0, double.infinity);

          return Padding(
            padding: EdgeInsets.fromLTRB(
              24,
              20,
              24,
              MediaQuery.of(ctx2).viewInsets.bottom + 32,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.borderLight,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        tipoPlantilla == 'TRANSPORTE' ? 'Registrar Flete' : 'Nueva Venta',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    tipoPlantilla == 'TRANSPORTE'
                        ? 'Empresa/cliente del flete'
                        : 'Stock disponible: ${liveCuenta.stockRestante.toStringAsFixed(0)} ${liveCuenta.unidadMedida}',
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 14),
                  // TOGGLE: Venta por Monto (Público)
                  GestureDetector(
                    onTap: () {
                      setModal(() {
                        ventaPorMonto = !ventaPorMonto;
                        if (ventaPorMonto) {
                          clienteCtrl.text = 'Público';
                          cantidadCtrl.clear();
                        } else {
                          clienteCtrl.clear();
                          totalCtrl.clear();
                        }
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: ventaPorMonto
                            ? AppColors.cream.withValues(alpha: 0.15)
                            : AppColors.background,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: ventaPorMonto
                              ? AppColors.cream
                              : AppColors.border,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            ventaPorMonto
                                ? Icons.toggle_on_rounded
                                : Icons.toggle_off_rounded,
                            color: ventaPorMonto
                                ? AppColors.cream
                                : AppColors.textMuted,
                            size: 28,
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Venta rápida al Público',
                                style: TextStyle(
                                  color: ventaPorMonto
                                      ? AppColors.cream
                                      : AppColors.textSecondary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                              Text(
                                ventaPorMonto
                                    ? 'Solo ingresas cantidad y total'
                                    : 'Ingresas todos los detalles',
                                style: const TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  // CLIENTE
                  if (!ventaPorMonto) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Cliente',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: clienteCtrl,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Nombre del comprador',
                        hintStyle: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 14,
                        ),
                        filled: true,
                        fillColor: AppColors.background,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: AppColors.cream),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  // CAMPOS: Cantidad + Precio (modo normal) o solo Cantidad (modo público)
                  AnimatedSize(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                    child: !ventaPorMonto
                        ? Row(
                            children: [
                              Expanded(
                                child: _sheetField(
                                  cantidadCtrl,
                                  'Cantidad (${liveCuenta.unidadMedida})',
                                  'Ej: 29.8',
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(
                                      RegExp(r'[0-9.]'),
                                    ),
                                  ],
                                  onChanged: (_) {
                                    recalcTotal(setModal);
                                    recalcPrecio(setModal);
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _sheetField(
                                  precioCtrl,
                                  'Precio /${liveCuenta.unidadMedida}',
                                  'Ej: 4.00',
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(
                                      RegExp(r'[0-9.]'),
                                    ),
                                  ],
                                  onChanged: (_) => recalcTotal(setModal),
                                ),
                              ),
                            ],
                          )
                        : _sheetField(
                            precioCtrl,
                            'Precio /${liveCuenta.unidadMedida}',
                            'Ej: 4.00',
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'[0-9.]'),
                              ),
                            ],
                            onChanged: (_) => setModal(() {}),
                          ),
                  ),
                  const SizedBox(height: 12),
                  // TOTAL EDITABLE
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'Total a cobrar',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 6),
                          if (ventaPorMonto && double.tryParse(totalCtrl.text) != null && double.tryParse(precioCtrl.text) != null && double.tryParse(precioCtrl.text)! > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.cream.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'Equivale a: ${((double.tryParse(totalCtrl.text) ?? 0) / (double.tryParse(precioCtrl.text) ?? 1)).toStringAsFixed(2)} ${liveCuenta.unidadMedida}',
                                style: const TextStyle(
                                  color: AppColors.cream,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: totalCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                        ],
                        onChanged: (_) => recalcPrecio(setModal),
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Ej: 120.00',
                          hintStyle: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 14,
                          ),
                          filled: true,
                          fillColor: AppColors.background,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                              color: AppColors.border,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                              color: AppColors.border,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                              color: AppColors.cream,
                              width: 1.5,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // MODO COBRO
                  if (!ventaPorMonto) ...[
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setModal(() => cobrarAhora = true),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 11),
                              decoration: BoxDecoration(
                                color: cobrarAhora
                                    ? AppColors.cream
                                    : AppColors.background,
                                borderRadius: BorderRadius.circular(9),
                                border: Border.all(
                                  color: cobrarAhora
                                      ? AppColors.cream
                                      : AppColors.border,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  'Cobro al Instante',
                                  style: TextStyle(
                                    color: cobrarAhora
                                        ? AppColors.background
                                        : AppColors.textSecondary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setModal(() {
                              cobrarAhora = false;
                              abonoCtrl.clear();
                            }),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 11),
                              decoration: BoxDecoration(
                                color: !cobrarAhora
                                    ? AppColors.cream.withValues(alpha: 0.15)
                                    : AppColors.background,
                                borderRadius: BorderRadius.circular(9),
                                border: Border.all(
                                  color: !cobrarAhora
                                      ? AppColors.cream
                                      : AppColors.border,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  'A Crédito (Fiado)',
                                  style: TextStyle(
                                    color: !cobrarAhora
                                        ? AppColors.cream
                                        : AppColors.textSecondary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    AnimatedSize(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeInOut,
                      child: cobrarAhora
                          ? Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: _sheetField(
                                abonoCtrl,
                                'Monto recibido ahora',
                                '0.00',
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                    RegExp(r'[0-9.]'),
                                  ),
                                ],
                                onChanged: (_) => setModal(() {}),
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                    // RESUMEN SALDO
                    if (total > 0) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: saldo == 0
                              ? AppColors.positiveSubtle
                              : AppColors.negativeSubtle,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: saldo == 0
                                ? AppColors.positive.withValues(alpha: 0.3)
                                : AppColors.negative.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              saldo == 0 ? '✓ Cancelado' : 'Queda pendiente',
                              style: TextStyle(
                                color: saldo == 0
                                    ? AppColors.positive
                                    : AppColors.cream,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              saldo == 0
                                  ? 'S/ ${total.toStringAsFixed(2)}'
                                  : 'S/ ${saldo.toStringAsFixed(2)}',
                              style: TextStyle(
                                color: saldo == 0
                                    ? AppColors.positive
                                    : AppColors.cream,
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: ctx2,
                        initialDate: fechaVenta,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                        builder: (c, child) =>
                            Theme(data: ThemeData.dark(), child: child!),
                      );
                      if (picked != null) setModal(() => fechaVenta = picked);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Fecha de venta',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                          Row(
                            children: [
                              Text(
                                DateFormat(
                                  'dd MMM yyyy',
                                  'es',
                                ).format(fechaVenta),
                                style: const TextStyle(
                                  color: AppColors.cream,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Icon(
                                Icons.calendar_today_outlined,
                                size: 14,
                                color: AppColors.cream,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: loading
                          ? null
                          : () async {
                              final cliente = ventaPorMonto
                                  ? 'Público'
                                  : clienteCtrl.text.trim();
                              final total = double.tryParse(totalCtrl.text);
                              final precio = double.tryParse(precioCtrl.text);
                              final kilos = ventaPorMonto
                                  ? (total != null && precio != null && precio > 0
                                        ? total / precio
                                        : 0.0)
                                  : double.tryParse(cantidadCtrl.text);
                              final abono = ventaPorMonto
                                  ? (total ?? 0.0)
                                  : (double.tryParse(abonoCtrl.text) ?? 0.0);

                              // Validaciones
                              if (cliente.isEmpty) {
                                ScaffoldMessenger.of(ctx2).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Ingresa el nombre del cliente',
                                    ),
                                  ),
                                );
                                return;
                              }
                              if (kilos == null || kilos <= 0) {
                                ScaffoldMessenger.of(ctx2).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Ingresa una cantidad válida',
                                    ),
                                  ),
                                );
                                return;
                              }
                              if (total == null || total <= 0) {
                                ScaffoldMessenger.of(ctx2).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'El total debe ser mayor a 0',
                                    ),
                                  ),
                                );
                                return;
                              }
                              if (!ventaPorMonto &&
                                  (precio == null || precio <= 0)) {
                                ScaffoldMessenger.of(ctx2).showSnackBar(
                                  const SnackBar(
                                    content: Text('Ingresa el precio unitario'),
                                  ),
                                );
                                return;
                              }
                              if (kilos > liveCuenta.stockRestante) {
                                ScaffoldMessenger.of(ctx2).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'No tienes suficiente stock. Disponible: ${liveCuenta.stockRestante.toStringAsFixed(0)} ${liveCuenta.unidadMedida}',
                                    ),
                                  ),
                                );
                                return;
                              }

                              setModal(() => loading = true);
                              try {
                                await ref
                                    .read(ventaRepositoryProvider)
                                    .registrarVenta(
                                      cuentaId: liveCuenta.id,
                                      registradoPor: '',
                                      cliente: cliente,
                                      cantidadVendida: kilos,
                                      precioUnitario: precio ?? 0.0,
                                      totalVenta: total,
                                      fechaVenta: fechaVenta,
                                      montoInicialPagado: abono,
                                    );
                                ref.invalidate(ventasProvider(liveCuenta.id));
                                ref.invalidate(
                                  cuentasProvider(liveCuenta.proyectoId),
                                );
                                if (ctx2.mounted) Navigator.pop(ctx2);
                              } catch (e) {
                                setModal(() => loading = false);
                                if (ctx2.mounted) {
                                  ScaffoldMessenger.of(ctx2).showSnackBar(
                                    SnackBar(
                                      content: Text(ErrorHandler.parse(e)),
                                    ),
                                  );
                                }
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.cream,
                        foregroundColor: AppColors.background,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: loading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(
                              cobrarAhora
                                  ? 'Registrar Venta'
                                  : 'Registrar · Cobrar después',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showAbonoSheet(
    BuildContext context,
    WidgetRef ref,
    VentaModel venta,
    CuentaResumenModel liveCuenta,
  ) {
    final montoCtrl = TextEditingController(
      text: venta.saldoPendiente.toStringAsFixed(2),
    );
    final notaCtrl = TextEditingController();
    bool loading = false;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx2, setModal) => Padding(
          padding: EdgeInsets.fromLTRB(
            24,
            20,
            24,
            MediaQuery.of(ctx2).viewInsets.bottom + 32,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.borderLight,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Cobrar / Abonar',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Falta cobrar: ${venta.saldoPendiente.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: AppColors.cream,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 20),
              _sheetField(
                montoCtrl,
                'Cantidad a cobrar',
                'Ej: ${venta.saldoPendiente.toStringAsFixed(2)}',
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                ],
              ),
              const SizedBox(height: 12),
              _sheetField(
                notaCtrl,
                'Nota (opcional)',
                'Ej: Transferencia, Efectivo...',
              ),
              const SizedBox(height: 8),
              // ─── BOTONES RÁPIDOS DE MÉTODO DE PAGO ──────────────────
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ['Efectivo', 'Transferencia', 'Yape', 'Plin'].map((metodo) {
                  final sel = notaCtrl.text == metodo;
                  return GestureDetector(
                    onTap: () => setModal(() {
                      notaCtrl.text = sel ? '' : metodo;
                    }),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: sel ? AppColors.cream : AppColors.cream.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: sel ? AppColors.cream : AppColors.cream.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        metodo,
                        style: TextStyle(
                          color: sel ? AppColors.background : AppColors.cream,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: loading
                      ? null
                      : () async {
                          final monto = double.tryParse(montoCtrl.text);
                          if (monto == null || monto <= 0) {
                            ScaffoldMessenger.of(ctx2).showSnackBar(
                              const SnackBar(
                                content: Text('Ingresa una cantidad válida'),
                              ),
                            );
                            return;
                          }
                          if (monto > venta.saldoPendiente) {
                            ScaffoldMessenger.of(ctx2).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'El cobro no puede superar lo que falta (${venta.saldoPendiente.toStringAsFixed(2)})',
                                ),
                              ),
                            );
                            return;
                          }
                          setModal(() => loading = true);
                          try {
                            await ref
                                .read(ventaRepositoryProvider)
                                .registrarAbono(
                                  ventaId: venta.id,
                                  registradoPor: '',
                                  monto: monto,
                                  fechaAbono: DateTime.now(),
                                  nota: notaCtrl.text.trim().isEmpty
                                      ? null
                                      : notaCtrl.text.trim(),
                                );
                            ref.invalidate(ventasProvider(liveCuenta.id));
                            ref.invalidate(
                              cuentasProvider(liveCuenta.proyectoId),
                            );
                            if (ctx2.mounted) Navigator.pop(ctx2);
                          } catch (e) {
                            setModal(() => loading = false);
                            if (ctx2.mounted) {
                              ScaffoldMessenger.of(ctx2).showSnackBar(
                                SnackBar(content: Text(ErrorHandler.parse(e))),
                              );
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.cream,
                    foregroundColor: AppColors.background,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: loading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text(
                          'Registrar Pago',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showNuevoGastoSheet(
    BuildContext context,
    WidgetRef ref,
    CuentaResumenModel liveCuenta,
  ) {
    final conceptoCtrl = TextEditingController();
    final montoCtrl = TextEditingController();
    bool loading = false;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx2, setModal) => Padding(
          padding: EdgeInsets.fromLTRB(
            24,
            20,
            24,
            MediaQuery.of(ctx2).viewInsets.bottom + 32,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.borderLight,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Nuevo Gasto',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 20),
              _sheetField(
                conceptoCtrl,
                'Descripción',
                tipoPlantilla == 'TRANSPORTE' ? 'Ej: Llantas, Combustible, Chofer' : 'Ej: Estibadores, Flete, Mallas',
              ),
              const SizedBox(height: 8),
              // ─── BOTONES RÁPIDOS DE CONCEPTO DE GASTO ──────────────
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: (tipoPlantilla == 'TRANSPORTE'
                    ? ['Combustible', 'Chofer', 'Llantas', 'Mantenimiento', 'Peaje', 'Mecánico']
                    : ['Estibadores', 'Flete', 'Mallas', 'Pasajes', 'Comida']
                ).map((concepto) {
                  final sel = conceptoCtrl.text == concepto;
                  return GestureDetector(
                    onTap: () => setModal(() {
                      conceptoCtrl.text = sel ? '' : concepto;
                    }),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: sel ? AppColors.cream : AppColors.cream.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: sel ? AppColors.cream : AppColors.cream.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        concepto,
                        style: TextStyle(
                          color: sel ? AppColors.background : AppColors.cream,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              _sheetField(
                montoCtrl,
                'Monto',
                'Ej: 150.00',
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: loading
                      ? null
                      : () async {
                          final concepto = conceptoCtrl.text.trim();
                          final monto = double.tryParse(montoCtrl.text);
                          if (concepto.isEmpty || monto == null || monto <= 0) {
                            ScaffoldMessenger.of(ctx2).showSnackBar(
                              const SnackBar(
                                content: Text('Completa descripción y monto'),
                              ),
                            );
                            return;
                          }
                          setModal(() => loading = true);
                          try {
                            await ref
                                .read(gastoRepositoryProvider)
                                .registrarGasto(
                                  cuentaId: liveCuenta.id,
                                  registradoPor: '',
                                  descripcion: concepto,
                                  monto: monto,
                                  fechaGasto: DateTime.now(),
                                );
                            ref.invalidate(gastosFamilyProvider(liveCuenta.id));
                            ref.invalidate(
                              cuentasProvider(liveCuenta.proyectoId),
                            );
                            if (ctx2.mounted) Navigator.pop(ctx2);
                          } catch (e) {
                            setModal(() => loading = false);
                            if (ctx2.mounted) {
                              ScaffoldMessenger.of(ctx2).showSnackBar(
                                SnackBar(content: Text(ErrorHandler.parse(e))),
                              );
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.negative,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: loading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Registrar Gasto',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _cerrarCuenta(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          '¿Cerrar esta cuenta?',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: const Text(
          'Una cuenta cerrada ya no admitirá nuevas ventas ni gastos. Esta acción no se puede deshacer.',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ref
                    .read(cuentaRepositoryProvider)
                    .cerrarCuenta(cuenta.id, '');
                if (context.mounted) Navigator.pop(context);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error al cerrar: $e')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.negative,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Sí, cerrar'),
          ),
        ],
      ),
    );
  }

  Widget _sheetField(
    TextEditingController ctrl,
    String label,
    String hint, {
    TextInputType? keyboardType,
    Function(String)? onChanged,
    bool isProminent = false,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: isProminent ? AppColors.cream : AppColors.textSecondary,
            fontSize: isProminent ? 13 : 12,
            fontWeight: isProminent ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          onChanged: onChanged,
          style: TextStyle(
            color: isProminent ? AppColors.cream : AppColors.textPrimary,
            fontSize: isProminent ? 16 : 14,
            fontWeight: isProminent ? FontWeight.w600 : FontWeight.normal,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 14,
            ),
            filled: true,
            fillColor: isProminent
                ? AppColors.cream.withValues(alpha: 0.05)
                : AppColors.background,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: isProminent ? AppColors.cream : AppColors.border,
                width: isProminent ? 1.5 : 1.0,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: isProminent ? AppColors.cream : AppColors.border,
                width: isProminent ? 1.5 : 1.0,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.cream, width: 2.0),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 14,
              vertical: isProminent ? 14 : 12,
            ),
          ),
        ),
      ],
    );
  }
}
