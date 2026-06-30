import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/models/models.dart';
import '../providers/project_providers.dart';

class CajaGeneralScreen extends ConsumerWidget {
  final ProyectoModel proyecto;
  final String monedaSimbolo;

  const CajaGeneralScreen({
    super.key,
    required this.proyecto,
    this.monedaSimbolo = 'S/',
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transaccionesAsync = ref.watch(transaccionesProyectoProvider(proyecto.id));

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 16),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Caja General'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showNuevaTransaccionSheet(context, ref),
        backgroundColor: AppColors.cream,
        icon: const Icon(Icons.add, color: AppColors.background),
        label: const Text(
          'Transacción',
          style: TextStyle(color: AppColors.background, fontWeight: FontWeight.bold),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(transaccionesProyectoProvider(proyecto.id));
        },
        child: transaccionesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (transacciones) {
            double totalIngresos = 0;
            double totalGastos = 0;
            for (var t in transacciones) {
              if (t.tipo == 'ingreso') totalIngresos += t.monto;
              if (t.tipo == 'gasto') totalGastos += t.monto;
            }
            final saldo = totalIngresos - totalGastos;

            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _buildResumenCard(saldo, totalIngresos, totalGastos),
                const SizedBox(height: 24),
                const Text(
                  'Historial de Movimientos',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 16),
                if (transacciones.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20.0),
                      child: Text(
                        'No hay movimientos en la caja general.',
                        style: TextStyle(color: AppColors.textMuted),
                      ),
                    ),
                  )
                else
                  ...transacciones.map((t) => _buildTransaccionRow(context, ref, t)),
                const SizedBox(height: 80),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildResumenCard(double saldo, double ingresos, double gastos) {
    final esPositivo = saldo >= 0;
    
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
                    'Saldo Neto (General)',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${esPositivo ? '+' : ''}$monedaSimbolo ${saldo.toStringAsFixed(2)}',
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
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.account_balance_wallet, color: AppColors.cream, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              _resumenStat('Ingresos', '+$monedaSimbolo ${ingresos.toStringAsFixed(2)}', AppColors.positive),
              const SizedBox(width: 24),
              _resumenStat('Gastos', '-$monedaSimbolo ${gastos.toStringAsFixed(2)}', AppColors.negative),
            ],
          ),
        ],
      ),
    );
  }

  Widget _resumenStat(String label, String value, Color color) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransaccionRow(BuildContext context, WidgetRef ref, TransaccionGeneralModel t) {
    final esIngreso = t.tipo == 'ingreso';
    return GestureDetector(
      onLongPress: () {
        _confirmDeleteTransaccion(context, ref, t);
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: esIngreso ? AppColors.positiveSubtle : AppColors.negativeSubtle,
                shape: BoxShape.circle,
              ),
              child: Icon(
                esIngreso ? Icons.arrow_downward : Icons.arrow_upward,
                color: esIngreso ? AppColors.positive : AppColors.negative,
                size: 16,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.descripcion,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${DateFormat('dd MMM yyyy', 'es').format(t.fechaTransaccion)} • ${t.registradoPorNombre}',
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '${esIngreso ? '+' : '-'}$monedaSimbolo ${t.monto.toStringAsFixed(2)}',
              style: TextStyle(
                color: esIngreso ? AppColors.positive : AppColors.negative,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteTransaccion(BuildContext context, WidgetRef ref, TransaccionGeneralModel t) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Eliminar Transacción', style: TextStyle(color: AppColors.textPrimary)),
        content: Text(
          '¿Estás seguro de eliminar "${t.descripcion}" de $monedaSimbolo${t.monto}?',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar', style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ref.read(proyectoRepositoryProvider).deleteTransaccion(t.id);
                ref.invalidate(transaccionesProyectoProvider(proyecto.id));
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.negative),
                  );
                }
              }
            },
            child: const Text('Eliminar', style: TextStyle(color: AppColors.negative)),
          ),
        ],
      ),
    );
  }

  void _showNuevaTransaccionSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _NuevaTransaccionForm(proyectoId: proyecto.id),
    );
  }
}

class _NuevaTransaccionForm extends ConsumerStatefulWidget {
  final String proyectoId;
  const _NuevaTransaccionForm({required this.proyectoId});

  @override
  ConsumerState<_NuevaTransaccionForm> createState() => _NuevaTransaccionFormState();
}

class _NuevaTransaccionFormState extends ConsumerState<_NuevaTransaccionForm> {
  final _formKey = GlobalKey<FormState>();
  final _descController = TextEditingController();
  final _montoController = TextEditingController();
  String _tipo = 'ingreso';
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final keyboard = MediaQuery.of(context).viewInsets.bottom;
    
    return Container(
      margin: EdgeInsets.only(bottom: keyboard),
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Nueva Transacción',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _tipo = 'ingreso'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _tipo == 'ingreso' ? AppColors.positiveSubtle : AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _tipo == 'ingreso' ? AppColors.positive : AppColors.border,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          'Ingreso',
                          style: TextStyle(
                            color: _tipo == 'ingreso' ? AppColors.positive : AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _tipo = 'gasto'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _tipo == 'gasto' ? AppColors.negativeSubtle : AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _tipo == 'gasto' ? AppColors.negative : AppColors.border,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          'Gasto',
                          style: TextStyle(
                            color: _tipo == 'gasto' ? AppColors.negative : AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descController,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: _inputDecoration('Descripción (Ej: Préstamo, Alquiler)'),
              validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _montoController,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: _inputDecoration('Monto'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Requerido';
                if (double.tryParse(v) == null) return 'Monto inválido';
                return null;
              },
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.cream,
                foregroundColor: AppColors.background,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isLoading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Guardar Transacción', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: AppColors.textSecondary),
      filled: true,
      fillColor: AppColors.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.cream),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      await ref.read(proyectoRepositoryProvider).addTransaccion(
            widget.proyectoId,
            _tipo,
            _descController.text.trim(),
            double.parse(_montoController.text.trim()),
            DateTime.now(),
          );
      ref.invalidate(transaccionesProyectoProvider(widget.proyectoId));
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.negative),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _descController.dispose();
    _montoController.dispose();
    super.dispose();
  }
}
