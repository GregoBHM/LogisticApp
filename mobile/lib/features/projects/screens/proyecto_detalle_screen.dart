import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/models/models.dart';
import '../providers/project_providers.dart';
import 'cuenta_detalle_screen.dart';

class ProyectoDetalleScreen extends ConsumerWidget {
  final ProyectoModel proyecto;
  const ProyectoDetalleScreen({super.key, required this.proyecto});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cuentasAsync = ref.watch(cuentasProvider(proyecto.id));
    final miembrosAsync = ref.watch(miembrosProvider(proyecto.id));

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, size: 16), onPressed: () => Navigator.pop(context)),
        title: Text(proyecto.nombre),
        actions: [
          IconButton(icon: const Icon(Icons.edit_outlined, size: 18), onPressed: () => _showEditarProyectoSheet(context, ref)),
          IconButton(icon: const Icon(Icons.person_add_outlined, size: 18), onPressed: () => _showInviteSheet(context, ref)),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(cuentasProvider(proyecto.id));
          ref.invalidate(miembrosProvider(proyecto.id));
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
          children: [
            const Text('Equipo', style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w500, letterSpacing: 0.5)),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: miembrosAsync.when(
                loading: () => const Padding(padding: EdgeInsets.all(20), child: Center(child: CircularProgressIndicator())),
                error: (e, _) => Padding(padding: const EdgeInsets.all(20), child: Text('Error: $e')),
                data: (miembros) => Column(
                  children: [
                    if (miembros.isEmpty)
                      const Padding(padding: EdgeInsets.all(20), child: Text('No hay miembros', style: TextStyle(color: AppColors.textMuted))),
                    for (int i = 0; i < miembros.length; i++) ...[
                      _buildMemberRow(miembros[i]),
                      if (i < miembros.length - 1) const Divider(color: AppColors.border, indent: 60),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text('Cuentas', style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w500, letterSpacing: 0.5)),
            const SizedBox(height: 10),
            cuentasAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (cuentas) {
                if (cuentas.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Center(child: Text('Sin cuentas aún', style: TextStyle(color: AppColors.textMuted, fontSize: 13))),
                  );
                }
                return Column(
                  children: cuentas.map((c) => _buildCuentaCard(context, ref, c, proyecto.monedaSimbolo)).toList(),
                );
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.small(
        onPressed: () => _showNuevaCuentaSheet(context, ref),
        backgroundColor: AppColors.cream,
        foregroundColor: AppColors.background,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: const Icon(Icons.add, size: 20),
      ),
    );
  }

  Widget _buildMemberRow(Map<String, dynamic> m) {
    String nombre = m['nombre'] ?? '';
    if (nombre.trim().isEmpty) {
      nombre = 'Usuario (${m['email'] ?? 'Sin correo'})';
    }
    final email = m['email'] ?? '';
    final rol = m['rol'] ?? 'miembro';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.background,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.border),
            ),
            child: Center(child: Text(nombre[0].toString().toUpperCase(), style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(nombre, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w500, fontSize: 13)),
                Text(email, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppColors.border),
            ),
            child: Text(rol, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
          ),
        ],
      ),
    );
  }

  Widget _buildCuentaCard(BuildContext context, WidgetRef ref, CuentaResumenModel cuenta, String sym) {
    final estaAbierta = cuenta.estado == 'abierta';
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CuentaDetalleScreen(cuenta: cuenta, proyectoNombre: proyecto.nombre, monedaSimbolo: sym))),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(cuenta.producto, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w500, fontSize: 14)),
                        const SizedBox(height: 2),
                        Text(cuenta.nombre, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: estaAbierta ? AppColors.positiveSubtle : AppColors.negativeSubtle,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: estaAbierta ? AppColors.positive.withValues(alpha: 0.15) : AppColors.negative.withValues(alpha: 0.15)),
                    ),
                    child: Text(
                      estaAbierta ? 'Abierta' : 'Cerrada',
                      style: TextStyle(color: estaAbierta ? AppColors.positive : AppColors.negative, fontSize: 11, fontWeight: FontWeight.w500),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _showEditarCuentaSheet(context, ref, cuenta),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: const Icon(Icons.edit_outlined, size: 14, color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(
                    '${cuenta.cantidadUnidades.toStringAsFixed(0)} ${cuenta.tipoUnidad}s · ${cuenta.kilosTotales.toStringAsFixed(0)} kg',
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                  ),
                  const Spacer(),
                  Text(DateFormat('dd MMM', 'es').format(cuenta.fechaApertura), style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _statCol('Inv. Total', '$sym ${cuenta.inversionTotal.toStringAsFixed(2)}'),
                  _statCol('Vendido', '${cuenta.kilosVendidos.toStringAsFixed(0)} kg'),
                  _statCol('Restante', '${cuenta.kilosRestantes.toStringAsFixed(0)} kg', align: CrossAxisAlignment.end),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _statCol(String label, String value, {CrossAxisAlignment align = CrossAxisAlignment.start}) {
    return Expanded(
      child: Column(
        crossAxisAlignment: align,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w500, fontSize: 13)),
        ],
      ),
    );
  }

  void _showInviteSheet(BuildContext context, WidgetRef ref) {
    final emailCtrl = TextEditingController();
    bool loading = false;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx2, setModal) => Padding(
          padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(ctx2).viewInsets.bottom + 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Invitar Miembro', style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 20),
              TextField(
                controller: emailCtrl,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                decoration: const InputDecoration(
                  hintText: 'Correo electrónico',
                  hintStyle: TextStyle(color: AppColors.textMuted),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: loading ? null : () async {
                    if (emailCtrl.text.isEmpty) return;
                    setModal(() => loading = true);
                    try {
                      await ref.read(proyectoRepositoryProvider).invitarMiembro(proyecto.id, emailCtrl.text.trim());
                      if (context.mounted) {
                        Navigator.pop(ctx);
                        ref.invalidate(miembrosProvider(proyecto.id));
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Usuario invitado con éxito', style: TextStyle(color: AppColors.textPrimary))));
                      }
                    } catch (e) {
                      if (context.mounted) {
                        setModal(() => loading = false);
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.cream,
                    foregroundColor: AppColors.background,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: loading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: AppColors.background, strokeWidth: 2))
                      : const Text('Enviar Invitación'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditarProyectoSheet(BuildContext context, WidgetRef ref) {
    final nombreCtrl = TextEditingController(text: proyecto.nombre);
    final descCtrl = TextEditingController(text: proyecto.descripcion ?? '');
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
              const Text('Editar Proyecto', style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 20),
              _sheetField(nombreCtrl, 'Nombre del proyecto', 'Ej: Exportación Mango 2024'),
              const SizedBox(height: 12),
              _sheetField(descCtrl, 'Descripción (Opcional)', 'Detalles del proyecto'),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: loading ? null : () async {
                    if (nombreCtrl.text.trim().isEmpty) return;
                    setModal(() => loading = true);
                    try {
                      final repo = ref.read(proyectoRepositoryProvider);
                      await repo.actualizarProyecto(
                        proyecto.id,
                        nombre: nombreCtrl.text.trim(),
                        descripcion: descCtrl.text.trim(),
                      );
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Proyecto actualizado. Regresa y vuelve a entrar para ver cambios en la barra.')));
                        ref.invalidate(proyectosProvider);
                      }
                    } catch (e) {
                      setModal(() => loading = false);
                      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.cream,
                    foregroundColor: AppColors.background,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: loading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: AppColors.background, strokeWidth: 2)) : const Text('Guardar Cambios'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditarCuentaSheet(BuildContext context, WidgetRef ref, CuentaResumenModel cuenta) {
    final nombreCtrl = TextEditingController(text: cuenta.nombre);
    final productoCtrl = TextEditingController(text: cuenta.producto);
    final cantidadCtrl = TextEditingController(text: cuenta.cantidadUnidades.toString());
    final kgCtrl = TextEditingController(text: cuenta.kgPorUnidad.toString());
    final inversionCtrl = TextEditingController(text: cuenta.inversionTotal.toString());
    final precioCtrl = TextEditingController(text: cuenta.precioVentaKg.toString());
    String tipoUnidad = cuenta.tipoUnidad;
    DateTime fechaApertura = cuenta.fechaApertura;
    bool loading = false;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx2, setModal) => Padding(
          padding: EdgeInsets.fromLTRB(24, 20, 24, MediaQuery.of(ctx2).viewInsets.bottom + 32),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: AppColors.borderLight, borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 20),
                const Text('Editar Cuenta', style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w600)),
                const SizedBox(height: 20),
                _sheetField(nombreCtrl, 'Nombre de la cuenta', 'Ej: Lote Papa Junio'),
                const SizedBox(height: 12),
                _sheetField(productoCtrl, 'Producto', 'Ej: Papa, Cebolla, Maíz'),
                const SizedBox(height: 12),
                const Text('Tipo de Unidad', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                const SizedBox(height: 6),
                Row(
                  children: ['Saco', 'Caja', 'Jaba', 'Costal'].map((t) {
                    final sel = tipoUnidad == t;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => setModal(() => tipoUnidad = t),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: sel ? AppColors.cream : AppColors.background,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: sel ? AppColors.cream : AppColors.border),
                          ),
                          child: Text(t, style: TextStyle(color: sel ? AppColors.background : AppColors.textSecondary, fontWeight: FontWeight.w500, fontSize: 13)),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _sheetField(cantidadCtrl, 'Cantidad', 'Ej: 200', keyboardType: TextInputType.number, onChanged: (_) {
                      setModal(() {
                        final cant = double.tryParse(cantidadCtrl.text) ?? 0;
                        final kgU = double.tryParse(kgCtrl.text) ?? 0;
                        final inv = double.tryParse(inversionCtrl.text) ?? 0;
                        final total = cant * kgU;
                        if (total > 0 && inv > 0) precioCtrl.text = (inv / total).toStringAsFixed(2);
                      });
                    })),
                    const SizedBox(width: 12),
                    Expanded(child: _sheetField(kgCtrl, 'Kg por unidad', 'Ej: 50', keyboardType: TextInputType.number, onChanged: (_) {
                      setModal(() {
                        final cant = double.tryParse(cantidadCtrl.text) ?? 0;
                        final kgU = double.tryParse(kgCtrl.text) ?? 0;
                        final inv = double.tryParse(inversionCtrl.text) ?? 0;
                        final total = cant * kgU;
                        if (total > 0 && inv > 0) precioCtrl.text = (inv / total).toStringAsFixed(2);
                      });
                    })),
                  ],
                ),
                if (cantidadCtrl.text.isNotEmpty && kgCtrl.text.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Total: ${((double.tryParse(cantidadCtrl.text) ?? 0) * (double.tryParse(kgCtrl.text) ?? 0)).toStringAsFixed(0)} kg',
                    style: const TextStyle(color: AppColors.cream, fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ],
                const SizedBox(height: 12),
                _sheetField(inversionCtrl, 'Inversión Total', 'Ej: 5000', keyboardType: TextInputType.number, onChanged: (_) {
                  setModal(() {
                    final cant = double.tryParse(cantidadCtrl.text) ?? 0;
                    final kgU = double.tryParse(kgCtrl.text) ?? 0;
                    final inv = double.tryParse(inversionCtrl.text) ?? 0;
                    final total = cant * kgU;
                    if (total > 0 && inv > 0) precioCtrl.text = (inv / total).toStringAsFixed(2);
                  });
                }),
                const SizedBox(height: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Precio de Venta /Kg', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: precioCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: '0.00',
                        hintStyle: const TextStyle(color: AppColors.textMuted),
                        filled: true,
                        fillColor: AppColors.background,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.cream)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: loading ? null : () async {
                      if (nombreCtrl.text.isEmpty || productoCtrl.text.isEmpty || cantidadCtrl.text.isEmpty || kgCtrl.text.isEmpty || inversionCtrl.text.isEmpty || precioCtrl.text.isEmpty) {
                        return;
                      }
                      setModal(() => loading = true);
                      try {
                        final repo = ref.read(cuentaRepositoryProvider);
                        await repo.actualizarCuenta(
                          cuenta.id,
                          nombre: nombreCtrl.text,
                          producto: productoCtrl.text,
                          tipoUnidad: tipoUnidad,
                          cantidadUnidades: double.parse(cantidadCtrl.text),
                          kgPorUnidad: double.parse(kgCtrl.text),
                          inversionTotal: double.parse(inversionCtrl.text),
                          precioVentaKg: double.parse(precioCtrl.text),
                          fechaApertura: fechaApertura,
                        );
                        if (context.mounted) {
                          Navigator.pop(context);
                          ref.invalidate(cuentasProvider(proyecto.id));
                        }
                      } catch (e) {
                        setModal(() => loading = false);
                        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.cream,
                      foregroundColor: AppColors.background,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: loading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: AppColors.background, strokeWidth: 2)) : const Text('Guardar Cambios'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showNuevaCuentaSheet(BuildContext context, WidgetRef ref) {
    final nombreCtrl = TextEditingController();
    final productoCtrl = TextEditingController();
    final cantidadCtrl = TextEditingController();
    final kgCtrl = TextEditingController();
    final inversionCtrl = TextEditingController();
    final precioCtrl = TextEditingController();
    String tipoUnidad = 'Saco';
    DateTime fechaApertura = DateTime.now();
    bool loading = false;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx2, setModal) => Padding(
          padding: EdgeInsets.fromLTRB(24, 20, 24, MediaQuery.of(ctx2).viewInsets.bottom + 32),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: AppColors.borderLight, borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 20),
                const Text('Nueva Cuenta', style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w600)),
                const SizedBox(height: 20),
                _sheetField(nombreCtrl, 'Nombre de la cuenta', 'Ej: Lote Papa Junio'),
                const SizedBox(height: 12),
                _sheetField(productoCtrl, 'Producto', 'Ej: Papa, Cebolla, Maíz'),
                const SizedBox(height: 12),
                const Text('Tipo de Unidad', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                const SizedBox(height: 6),
                Row(
                  children: ['Saco', 'Caja', 'Jaba', 'Costal'].map((t) {
                    final sel = tipoUnidad == t;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => setModal(() => tipoUnidad = t),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: sel ? AppColors.cream : AppColors.background,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: sel ? AppColors.cream : AppColors.border),
                          ),
                          child: Text(t, style: TextStyle(color: sel ? AppColors.background : AppColors.textSecondary, fontWeight: FontWeight.w500, fontSize: 13)),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _sheetField(cantidadCtrl, 'Cantidad', 'Ej: 200', keyboardType: TextInputType.number, onChanged: (_) {
                      setModal(() {
                        final cant = double.tryParse(cantidadCtrl.text) ?? 0;
                        final kgU = double.tryParse(kgCtrl.text) ?? 0;
                        final inv = double.tryParse(inversionCtrl.text) ?? 0;
                        final total = cant * kgU;
                        if (total > 0 && inv > 0) precioCtrl.text = (inv / total).toStringAsFixed(2);
                      });
                    })),
                    const SizedBox(width: 12),
                    Expanded(child: _sheetField(kgCtrl, 'Kg por unidad', 'Ej: 50', keyboardType: TextInputType.number, onChanged: (_) {
                      setModal(() {
                        final cant = double.tryParse(cantidadCtrl.text) ?? 0;
                        final kgU = double.tryParse(kgCtrl.text) ?? 0;
                        final inv = double.tryParse(inversionCtrl.text) ?? 0;
                        final total = cant * kgU;
                        if (total > 0 && inv > 0) precioCtrl.text = (inv / total).toStringAsFixed(2);
                      });
                    })),
                  ],
                ),
                if (cantidadCtrl.text.isNotEmpty && kgCtrl.text.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Total: ${((double.tryParse(cantidadCtrl.text) ?? 0) * (double.tryParse(kgCtrl.text) ?? 0)).toStringAsFixed(0)} kg',
                    style: const TextStyle(color: AppColors.cream, fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ],
                const SizedBox(height: 12),
                _sheetField(inversionCtrl, 'Inversión Total', 'Ej: 5000', keyboardType: TextInputType.number, onChanged: (_) {
                  setModal(() {
                    final cant = double.tryParse(cantidadCtrl.text) ?? 0;
                    final kgU = double.tryParse(kgCtrl.text) ?? 0;
                    final inv = double.tryParse(inversionCtrl.text) ?? 0;
                    final total = cant * kgU;
                    if (total > 0 && inv > 0) precioCtrl.text = (inv / total).toStringAsFixed(2);
                  });
                }),
                const SizedBox(height: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text('Precio de Venta /Kg', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: AppColors.cream.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4)),
                          child: const Text('Sugerido', style: TextStyle(color: AppColors.cream, fontSize: 10, fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: precioCtrl,
                      keyboardType: TextInputType.number,
                      onChanged: (_) => setModal(() {}),
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Se calcula automáticamente',
                        hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                        filled: true,
                        fillColor: AppColors.background,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.cream)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                    if (precioCtrl.text.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        'A este precio recuperas exactamente tu inversión. Sube el precio para obtener ganancia.',
                        style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: ctx2,
                      initialDate: fechaApertura,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                      builder: (c, child) => Theme(data: ThemeData.dark(), child: child!),
                    );
                    if (picked != null) setModal(() => fechaApertura = picked);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Fecha de apertura', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                        Row(
                          children: [
                            Text(
                              DateFormat('dd MMM yyyy', 'es').format(fechaApertura),
                              style: const TextStyle(color: AppColors.cream, fontWeight: FontWeight.w500, fontSize: 13),
                            ),
                            const SizedBox(width: 6),
                            const Icon(Icons.calendar_today_outlined, size: 14, color: AppColors.cream),
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
                    onPressed: loading ? null : () async {
                      final nombre = nombreCtrl.text.trim();
                      final producto = productoCtrl.text.trim();
                      final cantidad = double.tryParse(cantidadCtrl.text);
                      final kg = double.tryParse(kgCtrl.text);
                      final inversion = double.tryParse(inversionCtrl.text);
                      final precio = double.tryParse(precioCtrl.text);

                      if (nombre.isEmpty || producto.isEmpty || cantidad == null || kg == null || inversion == null || precio == null) {
                        ScaffoldMessenger.of(ctx2).showSnackBar(const SnackBar(content: Text('Completa todos los campos')));
                        return;
                      }
                      if (inversion < 0 || precio <= 0) {
                        ScaffoldMessenger.of(ctx2).showSnackBar(const SnackBar(content: Text('La inversión no puede ser negativa y el precio debe ser mayor a 0')));
                        return;
                      }

                      setModal(() => loading = true);
                      try {
                        await ref.read(cuentaRepositoryProvider).crearCuenta(
                          proyectoId: proyecto.id,
                          nombre: nombre,
                          producto: producto,
                          tipoUnidad: tipoUnidad,
                          cantidadUnidades: cantidad,
                          kgPorUnidad: kg,
                          inversionTotal: inversion,
                          precioVentaKg: precio,
                          creadoPor: '',
                          fechaApertura: fechaApertura,
                        );
                        ref.invalidate(cuentasProvider(proyecto.id));
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
                    child: loading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Crear Cuenta', style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
        ),
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

