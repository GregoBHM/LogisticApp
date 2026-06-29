import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/models/models.dart';
import '../providers/project_providers.dart';
import '../../reports/screens/reportes_screen.dart';

class CuentaDetalleScreen extends ConsumerWidget {
  final CuentaResumenModel cuenta;
  final String proyectoNombre;

  const CuentaDetalleScreen({
    super.key,
    required this.cuenta,
    required this.proyectoNombre,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ventasAsync = ref.watch(ventasProvider(cuenta.id));
    final gastosAsync = ref.watch(gastosFamilyProvider(cuenta.id));
    
    final estaAbierta = cuenta.estado == 'abierta';

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, size: 16), onPressed: () => Navigator.pop(context)),
        title: Text(cuenta.producto),
        actions: [
          IconButton(
            icon: const Icon(Icons.insert_chart_outlined, size: 20),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => ReportesScreen(cuenta: cuenta, proyectoNombre: proyectoNombre)));
            },
          ),
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
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
          children: [
            _buildResumenCard(context),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Ventas', style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w500, letterSpacing: 0.5)),
                if (estaAbierta)
                  GestureDetector(
                    onTap: () => _showNuevaVentaSheet(context, ref),
                    child: const Text('+ Nueva Venta', style: TextStyle(color: AppColors.cream, fontSize: 13, fontWeight: FontWeight.w600)),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            ventasAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Error: $e'),
              data: (ventas) {
                if (ventas.isEmpty) {
                  return const Text('No hay ventas registradas.', style: TextStyle(color: AppColors.textMuted));
                }
                return Column(
                  children: ventas.map((v) => _buildVentaRow(context, ref, v)).toList(),
                );
              },
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Gastos Operativos', style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w500, letterSpacing: 0.5)),
                if (estaAbierta)
                  GestureDetector(
                    onTap: () => _showNuevoGastoSheet(context, ref),
                    child: const Text('+ Añadir Gasto', style: TextStyle(color: AppColors.cream, fontSize: 13, fontWeight: FontWeight.w600)),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            gastosAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Error: $e'),
              data: (gastos) {
                if (gastos.isEmpty) {
                  return const Text('No hay gastos registrados.', style: TextStyle(color: AppColors.textMuted));
                }
                return Column(
                  children: gastos.map((g) => _buildGastoRow(g)).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResumenCard(BuildContext context) {
    final gananciaReal = cuenta.gananciaReal;
    final esPositivo = gananciaReal >= 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.surface, AppColors.surface.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Ganancia Real', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  const SizedBox(height: 4),
                  Text(
                    '${esPositivo ? '+' : ''}${gananciaReal.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: esPositivo ? AppColors.positive : AppColors.negative,
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: cuenta.estado == 'abierta' ? AppColors.positiveSubtle : AppColors.negativeSubtle,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  cuenta.estado == 'abierta' ? 'En Curso' : 'Finalizado',
                  style: TextStyle(
                    color: cuenta.estado == 'abierta' ? AppColors.positive : AppColors.negative,
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
              _resumenStat('Inversión', '${cuenta.inversionTotal.toStringAsFixed(2)}', Icons.arrow_upward, AppColors.negative),
              _resumenStat('Ingresos', '${cuenta.totalCobrado.toStringAsFixed(2)}', Icons.arrow_downward, AppColors.positive),
              _resumenStat('Stock', '${cuenta.kilosRestantes.toStringAsFixed(0)} kg', Icons.inventory_2_outlined, AppColors.cream),
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
              Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
            ],
          ),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildVentaRow(BuildContext context, WidgetRef ref, VentaModel v) {
    final pagado = v.estadoPago == 'Pagado';
    return GestureDetector(
      onTap: () {
        if (!pagado && cuenta.estado == 'abierta') {
          _showAbonoSheet(context, ref, v);
        }
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
              child: const Icon(Icons.person_outline, color: AppColors.textSecondary, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(v.cliente, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w500, fontSize: 14)),
                  const SizedBox(height: 2),
                  Text('${v.kilosVendidos.toStringAsFixed(1)} kg a ${v.precioPorKg.toStringAsFixed(2)}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(v.totalVenta.toStringAsFixed(2), style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: pagado ? AppColors.positiveSubtle : AppColors.cream.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    pagado ? 'Pagado' : 'Debe: ${v.saldoPendiente.toStringAsFixed(2)}',
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

  Widget _buildGastoRow(GastoModel g) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.negativeSubtle,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.money_off, color: AppColors.negative, size: 14),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(g.descripcion, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w500, fontSize: 13)),
                Text(DateFormat('dd MMM yyyy', 'es').format(g.fechaGasto), style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
              ],
            ),
          ),
          Text('-${g.monto.toStringAsFixed(2)}', style: const TextStyle(color: AppColors.negative, fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }

  void _showNuevaVentaSheet(BuildContext context, WidgetRef ref) {
    final clienteCtrl = TextEditingController();
    final kilosCtrl = TextEditingController();
    final precioCtrl = TextEditingController(text: cuenta.precioVentaKg.toStringAsFixed(2));
    final abonoCtrl = TextEditingController();
    bool loading = false;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx2, setModal) {
          final kilos = double.tryParse(kilosCtrl.text) ?? 0;
          final precio = double.tryParse(precioCtrl.text) ?? 0;
          final abono = double.tryParse(abonoCtrl.text) ?? 0;
          final total = kilos * precio;
          final saldo = (total - abono).clamp(0, double.infinity);

          return Padding(
            padding: EdgeInsets.fromLTRB(24, 20, 24, MediaQuery.of(ctx2).viewInsets.bottom + 32),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: AppColors.borderLight, borderRadius: BorderRadius.circular(2)))),
                  const SizedBox(height: 20),
                  const Text('Nueva Venta', style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Text('Stock disponible: ${cuenta.kilosRestantes.toStringAsFixed(0)} kg', style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
                  const SizedBox(height: 20),
                  _sheetField(clienteCtrl, 'Cliente', 'Nombre del comprador'),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _sheetField(kilosCtrl, 'Kilos a vender', 'Ej: 500', keyboardType: TextInputType.number, onChanged: (_) => setModal(() {}))),
                      const SizedBox(width: 12),
                      Expanded(child: _sheetField(precioCtrl, 'Precio /Kg', 'Ej: 1.80', keyboardType: TextInputType.number, onChanged: (_) => setModal(() {}))),
                    ],
                  ),
                  if (total > 0) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border)),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total Venta', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                          Text(total.toStringAsFixed(2), style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 15)),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  _sheetField(abonoCtrl, 'Monto inicial pagado (opcional)', '0.00', keyboardType: TextInputType.number, onChanged: (_) => setModal(() {})),
                  if (total > 0 && abono > 0) ...[
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(saldo == 0 ? '✓ Pagado completamente' : 'Saldo pendiente: ${saldo.toStringAsFixed(2)}',
                          style: TextStyle(color: saldo == 0 ? AppColors.positive : AppColors.cream, fontWeight: FontWeight.w600, fontSize: 13)),
                      ],
                    ),
                  ],
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: loading ? null : () async {
                        final cliente = clienteCtrl.text.trim();
                        final kilos = double.tryParse(kilosCtrl.text);
                        final precio = double.tryParse(precioCtrl.text);

                        if (cliente.isEmpty || kilos == null || precio == null) {
                          ScaffoldMessenger.of(ctx2).showSnackBar(const SnackBar(content: Text('Completa cliente, kilos y precio')));
                          return;
                        }
                        if (kilos > cuenta.kilosRestantes) {
                          ScaffoldMessenger.of(ctx2).showSnackBar(SnackBar(content: Text('No tienes suficiente stock. Disponible: ${cuenta.kilosRestantes.toStringAsFixed(0)} kg')));
                          return;
                        }

                        setModal(() => loading = true);
                        try {
                          await ref.read(ventaRepositoryProvider).registrarVenta(
                            cuentaId: cuenta.id,
                            registradoPor: '',
                            cliente: cliente,
                            kilosVendidos: kilos,
                            precioPorKg: precio,
                            fechaVenta: DateTime.now(),
                            montoInicialPagado: double.tryParse(abonoCtrl.text),
                          );
                          ref.invalidate(ventasProvider(cuenta.id));
                          if (ctx2.mounted) Navigator.pop(ctx2);
                        } catch (e) {
                          setModal(() => loading = false);
                          if (ctx2.mounted) ScaffoldMessenger.of(ctx2).showSnackBar(SnackBar(content: Text('Error: $e')));
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.cream,
                        foregroundColor: AppColors.background,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: loading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Registrar Venta', style: TextStyle(fontWeight: FontWeight.w600)),
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

  void _showAbonoSheet(BuildContext context, WidgetRef ref, VentaModel venta) {
    final montoCtrl = TextEditingController();
    final notaCtrl = TextEditingController();
    bool loading = false;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx2, setModal) => Padding(
          padding: EdgeInsets.fromLTRB(24, 20, 24, MediaQuery.of(ctx2).viewInsets.bottom + 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: AppColors.borderLight, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 20),
              const Text('Registrar Abono', style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              Text('Saldo pendiente: ${venta.saldoPendiente.toStringAsFixed(2)}', style: const TextStyle(color: AppColors.cream, fontSize: 13, fontWeight: FontWeight.w500)),
              const SizedBox(height: 20),
              _sheetField(montoCtrl, 'Monto del abono', 'Ej: ${venta.saldoPendiente.toStringAsFixed(2)}', keyboardType: TextInputType.number),
              const SizedBox(height: 12),
              _sheetField(notaCtrl, 'Nota (opcional)', 'Ej: Transferencia, Efectivo...'),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: loading ? null : () async {
                    final monto = double.tryParse(montoCtrl.text);
                    if (monto == null || monto <= 0) {
                      ScaffoldMessenger.of(ctx2).showSnackBar(const SnackBar(content: Text('Ingresa un monto válido')));
                      return;
                    }
                    if (monto > venta.saldoPendiente) {
                      ScaffoldMessenger.of(ctx2).showSnackBar(SnackBar(content: Text('El abono no puede superar el saldo pendiente (${venta.saldoPendiente.toStringAsFixed(2)})')));
                      return;
                    }
                    setModal(() => loading = true);
                    try {
                      await ref.read(ventaRepositoryProvider).registrarAbono(
                        ventaId: venta.id,
                        registradoPor: '',
                        monto: monto,
                        fechaAbono: DateTime.now(),
                        nota: notaCtrl.text.trim().isEmpty ? null : notaCtrl.text.trim(),
                      );
                      ref.invalidate(ventasProvider(cuenta.id));
                      if (ctx2.mounted) Navigator.pop(ctx2);
                    } catch (e) {
                      setModal(() => loading = false);
                      if (ctx2.mounted) ScaffoldMessenger.of(ctx2).showSnackBar(SnackBar(content: Text('Error: $e')));
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.cream,
                    foregroundColor: AppColors.background,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: loading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Registrar Abono', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showNuevoGastoSheet(BuildContext context, WidgetRef ref) {
    final descripcionCtrl = TextEditingController();
    final montoCtrl = TextEditingController();
    bool loading = false;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx2, setModal) => Padding(
          padding: EdgeInsets.fromLTRB(24, 20, 24, MediaQuery.of(ctx2).viewInsets.bottom + 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: AppColors.borderLight, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 20),
              const Text('Nuevo Gasto', style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 20),
              _sheetField(descripcionCtrl, 'Descripción', 'Ej: Estibadores, Flete, Mallas'),
              const SizedBox(height: 12),
              _sheetField(montoCtrl, 'Monto', 'Ej: 150.00', keyboardType: TextInputType.number),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: loading ? null : () async {
                    final descripcion = descripcionCtrl.text.trim();
                    final monto = double.tryParse(montoCtrl.text);
                    if (descripcion.isEmpty || monto == null || monto <= 0) {
                      ScaffoldMessenger.of(ctx2).showSnackBar(const SnackBar(content: Text('Completa descripción y monto')));
                      return;
                    }
                    setModal(() => loading = true);
                    try {
                      await ref.read(gastoRepositoryProvider).registrarGasto(
                        cuentaId: cuenta.id,
                        registradoPor: '',
                        descripcion: descripcion,
                        monto: monto,
                        fechaGasto: DateTime.now(),
                      );
                      ref.invalidate(gastosFamilyProvider(cuenta.id));
                      if (ctx2.mounted) Navigator.pop(ctx2);
                    } catch (e) {
                      setModal(() => loading = false);
                      if (ctx2.mounted) ScaffoldMessenger.of(ctx2).showSnackBar(SnackBar(content: Text('Error: $e')));
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.negative,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: loading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Registrar Gasto', style: TextStyle(fontWeight: FontWeight.w600)),
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
        title: const Text('¿Cerrar esta cuenta?', style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
        content: const Text('Una cuenta cerrada ya no admitirá nuevas ventas ni gastos. Esta acción no se puede deshacer.', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ref.read(cuentaRepositoryProvider).cerrarCuenta(cuenta.id, '');
                if (context.mounted) Navigator.pop(context);
              } catch (e) {
                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al cerrar: $e')));
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.negative,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Sí, cerrar'),
          ),
        ],
      ),
    );
  }

  Widget _sheetField(TextEditingController ctrl, String label, String hint, {TextInputType? keyboardType, Function(String)? onChanged}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          keyboardType: keyboardType,
          onChanged: onChanged,
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
            filled: true,
            fillColor: AppColors.background,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.cream)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
      ],
    );
  }
}

