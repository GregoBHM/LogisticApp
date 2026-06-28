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
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nueva Venta - En desarrollo')));
  }

  void _showAbonoSheet(BuildContext context, WidgetRef ref, VentaModel venta) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Abono - En desarrollo')));
  }

  void _showNuevoGastoSheet(BuildContext context, WidgetRef ref) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nuevo Gasto - En desarrollo')));
  }

  void _cerrarCuenta(BuildContext context, WidgetRef ref) {
    // En desarrollo
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cerrar Cuenta - En desarrollo')));
  }
}
