import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/models/models.dart';
import '../providers/project_providers.dart';
import 'cuenta_detalle_screen.dart';
import 'caja_general_screen.dart';
import '../../reports/screens/reportes_screen.dart';
import '../../../core/network/error_handler.dart';

class ProyectoDetalleScreen extends ConsumerWidget {
  final ProyectoModel proyecto;
  const ProyectoDetalleScreen({super.key, required this.proyecto});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cuentasAsync = ref.watch(cuentasProvider(proyecto.id));
    final miembrosAsync = ref.watch(miembrosProvider(proyecto.id));

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 16),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(proyecto.nombre),
        actions: [
          IconButton(
            icon: const Icon(Icons.insert_chart_outlined, size: 20),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ReportesScreen(
                    proyectoId: proyecto.id,
                    proyectoNombre: proyecto.nombre,
                    monedaSimbolo: proyecto.monedaSimbolo,
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 18),
            onPressed: () => _showEditarProyectoSheet(context, ref),
          ),
          IconButton(
            icon: const Icon(Icons.person_add_outlined, size: 18),
            onPressed: () => _showInviteSheet(context, ref),
          ),
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
            const Text(
              'Equipo',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: miembrosAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) => Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(ErrorHandler.parse(e)),
                ),
                data: (miembros) => Column(
                  children: [
                    if (miembros.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(20),
                        child: Text(
                          'No hay miembros',
                          style: TextStyle(color: AppColors.textMuted),
                        ),
                      ),
                    for (int i = 0; i < miembros.length; i++) ...[
                      _buildMemberRow(context, ref, miembros[i]),
                      if (i < miembros.length - 1)
                        const Divider(color: AppColors.border, indent: 60),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CajaGeneralScreen(
                    proyecto: proyecto,
                    monedaSimbolo: proyecto.monedaSimbolo,
                  ),
                ),
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.cream.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.cream.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.account_balance_wallet,
                        color: AppColors.cream,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Caja General',
                            style: TextStyle(
                              color: AppColors.cream,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Ingresos y gastos independientes',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right,
                      color: AppColors.textSecondary,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // ─── MIS EMPAQUES ────────────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Mis Empaques',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.5,
                  ),
                ),
                GestureDetector(
                  onTap: () => _showNuevoEmpaqueSheet(context, ref),
                  child: const Text(
                    '+ Añadir',
                    style: TextStyle(
                      color: AppColors.cream,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ref.watch(empaquesProvider(proyecto.id)).when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => const SizedBox.shrink(),
              data: (empaques) {
                if (empaques.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border, style: BorderStyle.solid),
                    ),
                    child: const Center(
                      child: Text(
                        'Sin empaques configurados.\nToca "+ Añadir" para crear el primero.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.textMuted, fontSize: 12, height: 1.6),
                      ),
                    ),
                  );
                }
                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: empaques.map((e) {
                    return GestureDetector(
                      onLongPress: () => _confirmDeleteEmpaque(context, ref, e),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.cream.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.cream.withValues(alpha: 0.4)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              e.nombre,
                              style: const TextStyle(
                                color: AppColors.cream,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              '${e.cantidadPorUnidad.toStringAsFixed(1)} ${e.unidadMedida}',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 11,
                              ),
                            ),
                            if (e.descripcion != null && e.descripcion!.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  e.descripcion!,
                                  style: const TextStyle(
                                    color: AppColors.textMuted,
                                    fontSize: 10,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
            const SizedBox(height: 24),
            const Text(
              'Cuentas',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 10),
            cuentasAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text(ErrorHandler.parse(e))),
              data: (cuentas) {
                if (cuentas.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Center(
                      child: Text(
                        'Sin cuentas aún',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  );
                }
                return Column(
                  children: cuentas
                      .map(
                        (c) => _buildCuentaCard(
                          context,
                          ref,
                          c,
                          proyecto.monedaSimbolo,
                        ),
                      )
                      .toList(),
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

  Widget _buildMemberRow(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> m,
  ) {
    String nombre = m['nombre'] ?? '';
    if (nombre.trim().isEmpty) {
      nombre = 'Usuario (${m['email'] ?? 'Sin correo'})';
    }
    final email = m['email'] ?? '';
    final rawRol = m['rol']?.toString().toLowerCase() ?? 'miembro';
    String displayRol = 'Equipo';
    if (rawRol == 'dueño') displayRol = 'Dueño';
    if (rawRol == 'admin') displayRol = 'Admin';

    final usuarioId =
        m['id'] ??
        m['usuario_id']; // Depending on what backend returns for user ID

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
            child: Center(
              child: Text(
                nombre[0].toString().toUpperCase(),
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nombre,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
                Text(
                  email,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: displayRol == 'Dueño'
                    ? AppColors.cream.withOpacity(0.5)
                    : AppColors.border,
              ),
            ),
            child: Text(
              displayRol,
              style: TextStyle(
                color: displayRol == 'Dueño'
                    ? AppColors.cream
                    : AppColors.textSecondary,
                fontSize: 11,
                fontWeight: displayRol == 'Dueño'
                    ? FontWeight.w600
                    : FontWeight.normal,
              ),
            ),
          ),
          if (usuarioId != null && rawRol != 'dueño')
            IconButton(
              icon: const Icon(
                Icons.more_vert,
                color: AppColors.textSecondary,
                size: 18,
              ),
              onPressed: () => _showOpcionesMiembroSheet(context, ref, m),
            ),
        ],
      ),
    );
  }

  void _showOpcionesMiembroSheet(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> m,
  ) {
    final usuarioId = m['id'] ?? m['usuario_id'];
    if (usuarioId == null) return;

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
                'Opciones de Miembro',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                m['email'] ?? '',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(
                  Icons.admin_panel_settings_outlined,
                  color: AppColors.cream,
                ),
                title: const Text(
                  'Cambiar Rol',
                  style: TextStyle(color: AppColors.textPrimary),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _showCambiarRolSheet(context, ref, m);
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.person_remove_outlined,
                  color: AppColors.negative,
                ),
                title: const Text(
                  'Expulsar Miembro',
                  style: TextStyle(color: AppColors.textPrimary),
                ),
                onTap: () async {
                  Navigator.pop(ctx);
                  final confirmar = await showDialog<bool>(
                    context: context,
                    builder: (c) => AlertDialog(
                      backgroundColor: AppColors.surface,
                      title: const Text(
                        '¿Expulsar miembro?',
                        style: TextStyle(color: AppColors.textPrimary),
                      ),
                      content: const Text(
                        'Este usuario ya no tendrá acceso al proyecto.',
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
                            'Expulsar',
                            style: TextStyle(color: AppColors.negative),
                          ),
                        ),
                      ],
                    ),
                  );
                  if (confirmar == true) {
                    try {
                      await ref
                          .read(proyectoRepositoryProvider)
                          .expulsarMiembro(proyecto.id, usuarioId.toString());
                      if (context.mounted) {
                        ref.invalidate(miembrosProvider(proyecto.id));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Miembro expulsado')),
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

  void _showCambiarRolSheet(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> m,
  ) {
    String rolActual = m['rol'] ?? 'miembro';
    final usuarioId = m['id'] ?? m['usuario_id'];
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
                'Seleccionar Rol',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 20),
              Column(
                children: ['admin', 'miembro'].map((r) {
                  final isSel =
                      rolActual == r ||
                      (r == 'miembro' && rolActual == 'vendedor');
                  final displayR = r == 'admin' ? 'Administrador' : 'Equipo';
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      isSel
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                      color: isSel ? AppColors.cream : AppColors.textSecondary,
                    ),
                    title: Text(
                      displayR,
                      style: TextStyle(
                        color: isSel
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                      ),
                    ),
                    onTap: () => setModal(() => rolActual = r),
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
                          setModal(() => loading = true);
                          try {
                            await ref
                                .read(proyectoRepositoryProvider)
                                .cambiarRolMiembro(
                                  proyecto.id,
                                  usuarioId.toString(),
                                  rolActual,
                                );
                            if (context.mounted) {
                              Navigator.pop(ctx);
                              ref.invalidate(miembrosProvider(proyecto.id));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Rol actualizado'),
                                ),
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
                      : const Text('Guardar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCuentaCard(
    BuildContext context,
    WidgetRef ref,
    CuentaResumenModel cuenta,
    String sym,
  ) {
    final estaAbierta = cuenta.estado == 'abierta';
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CuentaDetalleScreen(
              cuenta: cuenta,
              proyectoNombre: proyecto.nombre,
              monedaSimbolo: sym,
              tipoPlantilla: proyecto.tipoPlantilla,
            ),
          ),
        ),
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
                        Text(
                          cuenta.producto,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          cuenta.nombre,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: estaAbierta
                          ? AppColors.positiveSubtle
                          : AppColors.negativeSubtle,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: estaAbierta
                            ? AppColors.positive.withValues(alpha: 0.15)
                            : AppColors.negative.withValues(alpha: 0.15),
                      ),
                    ),
                    child: Text(
                      estaAbierta ? 'Abierta' : 'Cerrada',
                      style: TextStyle(
                        color: estaAbierta
                            ? AppColors.positive
                            : AppColors.negative,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
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
                      child: const Icon(
                        Icons.edit_outlined,
                        size: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(
                    '${cuenta.cantidadUnidades.toStringAsFixed(0)} ${cuenta.tipoUnidad} · ${cuenta.stockTotal.toStringAsFixed(0)} ${cuenta.unidadMedida}',
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    DateFormat('dd MMM', 'es').format(cuenta.fechaApertura),
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _statCol(
                    'Inv. Total',
                    '$sym ${cuenta.inversionTotal.toStringAsFixed(2)}',
                  ),
                  _statCol(
                    'Vendido',
                    '${cuenta.cantidadVendida.toStringAsFixed(0)} ${cuenta.unidadMedida}',
                  ),
                  _statCol(
                    'Restante',
                    '${cuenta.stockRestante.toStringAsFixed(0)} ${cuenta.unidadMedida}',
                    align: CrossAxisAlignment.end,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statCol(
    String label,
    String value, {
    CrossAxisAlignment align = CrossAxisAlignment.start,
  }) {
    return Expanded(
      child: Column(
        crossAxisAlignment: align,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w500,
              fontSize: 13,
            ),
          ),
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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx2, setModal) => Padding(
          padding: EdgeInsets.fromLTRB(
            24,
            24,
            24,
            MediaQuery.of(ctx2).viewInsets.bottom + 32,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Invitar Miembro',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: emailCtrl,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                ),
                decoration: const InputDecoration(
                  hintText: 'Correo electrónico',
                  hintStyle: TextStyle(color: AppColors.textMuted),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: loading
                      ? null
                      : () async {
                          if (emailCtrl.text.isEmpty) return;
                          setModal(() => loading = true);
                          try {
                            await ref
                                .read(proyectoRepositoryProvider)
                                .invitarMiembro(
                                  proyecto.id,
                                  emailCtrl.text.trim(),
                                );
                            if (context.mounted) {
                              Navigator.pop(ctx);
                              ref.invalidate(miembrosProvider(proyecto.id));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Usuario invitado con éxito',
                                    style: TextStyle(
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              setModal(() => loading = false);
                              ScaffoldMessenger.of(context).showSnackBar(
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
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: AppColors.background,
                            strokeWidth: 2,
                          ),
                        )
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
    final productoCtrl = TextEditingController(
      text: proyecto.productoDefault ?? '',
    );
    final tipoUnidadCtrl = TextEditingController(
      text: proyecto.tipoUnidadDefault ?? '',
    );
    final cantPorUnidadCtrl = TextEditingController(
      text: proyecto.cantidadPorUnidadDefault != null
          ? proyecto.cantidadPorUnidadDefault!.toStringAsFixed(
              proyecto.cantidadPorUnidadDefault! == proyecto.cantidadPorUnidadDefault!.roundToDouble() ? 0 : 1,
            )
          : '',
    );
    String? unidadMedida = proyecto.unidadMedidaDefault;
    bool loading = false;
    final unidades = ['kg', 'lb', 'und', 'lt', 'pz', 'm'];

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
                  'Editar Proyecto',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 20),
                _sheetField(
                  nombreCtrl,
                  'Nombre del proyecto',
                  'Ej: Exportación Mango 2024',
                ),
                const SizedBox(height: 12),
                _sheetField(
                  descCtrl,
                  'Descripción (Opcional)',
                  'Detalles del proyecto',
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.cream.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(
                        Icons.auto_fix_high_rounded,
                        color: AppColors.cream,
                        size: 14,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Plantilla de Operaciones',
                      style: TextStyle(
                        color: AppColors.cream,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _sheetField(
                  productoCtrl,
                  'Producto principal',
                  'Ej: Papaya, Ropa, Café',
                ),
                const SizedBox(height: 12),
                _sheetField(
                  tipoUnidadCtrl,
                  'Tipo de empaque',
                  'Ej: Caja, Saco, Paquete',
                ),
                const SizedBox(height: 12),
                const Text(
                  'Unidad de medida',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: unidades.map((u) {
                    final sel = unidadMedida == u;
                    return GestureDetector(
                      onTap: () => setModal(() => unidadMedida = u),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: sel ? AppColors.cream : AppColors.background,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: sel ? AppColors.cream : AppColors.border,
                          ),
                          boxShadow: sel
                              ? [
                                  BoxShadow(
                                    color: AppColors.cream.withValues(alpha: 0.2),
                                    blurRadius: 8,
                                  ),
                                ]
                              : null,
                        ),
                        child: Text(
                          u,
                          style: TextStyle(
                            color: sel
                                ? AppColors.background
                                : AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                if (unidadMedida != null) ...[
                  const SizedBox(height: 12),
                  _sheetField(
                    cantPorUnidadCtrl,
                    'Cantidad por empaque ($unidadMedida)',
                    'Ej: 20',
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                  ),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: loading
                        ? null
                        : () async {
                            if (nombreCtrl.text.trim().isEmpty) return;
                            setModal(() => loading = true);
                            try {
                              final repo = ref.read(proyectoRepositoryProvider);
                              await repo.actualizarProyecto(
                                proyecto.id,
                                nombre: nombreCtrl.text.trim(),
                                descripcion: descCtrl.text.trim(),
                                productoDefault: productoCtrl.text.trim().isNotEmpty
                                    ? productoCtrl.text.trim()
                                    : null,
                                tipoUnidadDefault: tipoUnidadCtrl.text.trim().isNotEmpty
                                    ? tipoUnidadCtrl.text.trim()
                                    : null,
                                unidadMedidaDefault: unidadMedida,
                                cantidadPorUnidadDefault: double.tryParse(
                                  cantPorUnidadCtrl.text,
                                ),
                              );
                              if (context.mounted) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Proyecto actualizado. Regresa y vuelve a entrar para ver cambios.',
                                    ),
                                  ),
                                );
                                ref.invalidate(proyectosProvider);
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
      ),
    );
  }


  void _showEditarCuentaSheet(
    BuildContext context,
    WidgetRef ref,
    CuentaResumenModel cuenta,
  ) {
    final nombreCtrl = TextEditingController(text: cuenta.nombre);
    final productoCtrl = TextEditingController(text: cuenta.producto);
    final tipoUnidadCtrl = TextEditingController(text: cuenta.tipoUnidad);
    final cantidadCtrl = TextEditingController(
      text: cuenta.cantidadUnidades.toString(),
    );
    final cantPorUnidadCtrl = TextEditingController(text: cuenta.cantidadPorUnidad.toString());
    final inversionCtrl = TextEditingController(
      text: cuenta.inversionTotal.toString(),
    );
    final precioCtrl = TextEditingController(
      text: cuenta.precioUnitario.toString(),
    );
    String unidadMedida = cuenta.unidadMedida;
    DateTime fechaApertura = cuenta.fechaApertura;
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
                  'Editar Cuenta',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 20),
                _sheetField(
                  nombreCtrl,
                  'Nombre de la cuenta',
                  'Ej: Caja Frutas Junio',
                ),
                const SizedBox(height: 12),
                _sheetField(
                  productoCtrl,
                  'Producto o Servicio',
                  'Ej: Mango, Ropa, Servicio',
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _sheetField(
                        tipoUnidadCtrl,
                        'Tipo de empaque/lote',
                        'Ej: Caja, Paquete, Lote',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Unidad de medida',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 6,
                            children: ['und', 'kg', 'lt', 'pz', 'm'].map((u) {
                              final sel = unidadMedida == u;
                              return GestureDetector(
                                onTap: () => setModal(() => unidadMedida = u),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: sel ? AppColors.cream : AppColors.background,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: sel ? AppColors.cream : AppColors.border,
                                    ),
                                  ),
                                  child: Text(
                                    u,
                                    style: TextStyle(
                                      color: sel ? AppColors.background : AppColors.textSecondary,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _sheetField(
                        cantidadCtrl,
                        'Cantidad',
                        'Ej: 200',
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                        onChanged: (_) {
                          setModal(() {
                            final cant = double.tryParse(cantidadCtrl.text) ?? 0;
                            final cpu = double.tryParse(cantPorUnidadCtrl.text) ?? 0;
                            final inv = double.tryParse(inversionCtrl.text) ?? 0;
                            final total = cant * cpu;
                            if (total > 0 && inv > 0)
                              precioCtrl.text = (inv / total).toStringAsFixed(2);
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _sheetField(
                        cantPorUnidadCtrl,
                        'Cant. por empaque ($unidadMedida)',
                        'Ej: 50',
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                        onChanged: (_) {
                          setModal(() {
                            final cant = double.tryParse(cantidadCtrl.text) ?? 0;
                            final cpu = double.tryParse(cantPorUnidadCtrl.text) ?? 0;
                            final inv = double.tryParse(inversionCtrl.text) ?? 0;
                            final total = cant * cpu;
                            if (total > 0 && inv > 0)
                              precioCtrl.text = (inv / total).toStringAsFixed(2);
                          });
                        },
                      ),
                    ),
                  ],
                ),
                if (cantidadCtrl.text.isNotEmpty && cantPorUnidadCtrl.text.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Stock: ${((double.tryParse(cantidadCtrl.text) ?? 0) * (double.tryParse(cantPorUnidadCtrl.text) ?? 0)).toStringAsFixed(0)} $unidadMedida',
                    style: const TextStyle(
                      color: AppColors.cream,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                _sheetField(
                  inversionCtrl,
                  'Inversión Total',
                  'Ej: 5000',
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                  onChanged: (_) {
                    setModal(() {
                      final cant = double.tryParse(cantidadCtrl.text) ?? 0;
                      final cpu = double.tryParse(cantPorUnidadCtrl.text) ?? 0;
                      final inv = double.tryParse(inversionCtrl.text) ?? 0;
                      final total = cant * cpu;
                      if (total > 0 && inv > 0)
                        precioCtrl.text = (inv / total).toStringAsFixed(2);
                    });
                  },
                ),
                const SizedBox(height: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Precio de Venta',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: precioCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                      onChanged: (_) => setModal(() {}),
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                      ),
                      decoration: InputDecoration(
                        hintText: '0.00',
                        hintStyle: const TextStyle(color: AppColors.textMuted),
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
                          vertical: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: loading
                        ? null
                        : () async {
                            if (nombreCtrl.text.isEmpty ||
                                productoCtrl.text.isEmpty ||
                                cantidadCtrl.text.isEmpty ||
                                cantPorUnidadCtrl.text.isEmpty ||
                                inversionCtrl.text.isEmpty ||
                                precioCtrl.text.isEmpty) {
                              return;
                            }
                            setModal(() => loading = true);
                            try {
                              final repo = ref.read(cuentaRepositoryProvider);
                              await repo.actualizarCuenta(
                                cuenta.id,
                                nombre: nombreCtrl.text,
                                producto: productoCtrl.text,
                                tipoUnidad: tipoUnidadCtrl.text.isEmpty ? 'Unidad' : tipoUnidadCtrl.text,
                                unidadMedida: unidadMedida,
                                cantidadUnidades: double.parse(cantidadCtrl.text),
                                cantidadPorUnidad: double.parse(cantPorUnidadCtrl.text),
                                inversionTotal: double.parse(inversionCtrl.text),
                                precioUnitario: double.parse(precioCtrl.text),
                                fechaApertura: fechaApertura,
                              );
                              if (context.mounted) {
                                Navigator.pop(context);
                                ref.invalidate(cuentasProvider(proyecto.id));
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

  void _showNuevaCuentaSheet(BuildContext context, WidgetRef ref) {
    final nombreCtrl = TextEditingController();
    final productoCtrl = TextEditingController(
      text: proyecto.productoDefault ?? '',
    );
    final tipoUnidadCtrl = TextEditingController(
      text: proyecto.tipoUnidadDefault ?? '',
    );
    final cantidadCtrl = TextEditingController();
    final cantPorUnidadCtrl = TextEditingController(
      text: proyecto.cantidadPorUnidadDefault != null
          ? proyecto.cantidadPorUnidadDefault!.toStringAsFixed(
              proyecto.cantidadPorUnidadDefault! == proyecto.cantidadPorUnidadDefault!.roundToDouble() ? 0 : 1,
            )
          : '',
    );
    final inversionCtrl = TextEditingController();
    final precioCtrl = TextEditingController();
    String unidadMedida = proyecto.unidadMedidaDefault ?? 'und';
    DateTime fechaApertura = DateTime.now();
    bool loading = false;
    EmpaqueModel? empaqueSeleccionado;

    void recalcPrecio(void Function(void Function()) setModal) {
      setModal(() {
        final cant = double.tryParse(cantidadCtrl.text) ?? 0;
        final cpu = double.tryParse(cantPorUnidadCtrl.text) ?? 0;
        final inv = double.tryParse(inversionCtrl.text) ?? 0;
        final total = cant * cpu;
        if (total > 0 && inv > 0) {
          precioCtrl.text = (inv / total).toStringAsFixed(2);
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
          final empaquesAsync = ref.watch(empaquesProvider(proyecto.id));

          return Padding(
            padding: EdgeInsets.fromLTRB(
              24, 20, 24,
              MediaQuery.of(ctx2).viewInsets.bottom + 32,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 36, height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.borderLight,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    proyecto.tipoPlantilla == 'TRANSPORTE'
                        ? 'Nuevo Vehículo'
                        : 'Nueva Cuenta',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _sheetField(
                    nombreCtrl,
                    proyecto.tipoPlantilla == 'TRANSPORTE' ? 'Nombre / Placa' : 'Nombre de la cuenta',
                    proyecto.tipoPlantilla == 'TRANSPORTE' ? 'Ej: Camión Norte — ABC-123' : 'Ej: Camión del Lunes',
                  ),
                  const SizedBox(height: 12),
                  _sheetField(
                    productoCtrl,
                    proyecto.tipoPlantilla == 'TRANSPORTE' ? 'Tipo de servicio' : 'Producto o Servicio',
                    proyecto.tipoPlantilla == 'TRANSPORTE' ? 'Ej: Flete, Transporte de carga' : productoCtrl.text.isNotEmpty ? productoCtrl.text : 'Ej: Mango, Ropa, Servicio',
                  ),
                  // ─── BOTONES RÁPIDOS DE PRODUCTO (DINÁMICOS) ──────────────────
                  Consumer(
                    builder: (context, ref, _) {
                      final historial = ref.watch(historialSugerenciasProvider(proyecto.id));
                      final productosUsados = historial.valueOrNull?.productos ?? [];

                      if (productosUsados.isEmpty) return const SizedBox.shrink();

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: productosUsados.take(10).map((prod) {
                              final sel = productoCtrl.text == prod;
                              return GestureDetector(
                                onTap: () => setModal(() {
                                  productoCtrl.text = sel ? '' : prod;
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
                                    prod,
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
                          const SizedBox(height: 16),
                        ],
                      );
                    },
                  ),
                  // ─── SELECTOR INTELIGENTE DE EMPAQUE (solo COMERCIO) ──────────────────────
                  if (proyecto.tipoPlantilla != 'TRANSPORTE')
                    empaquesAsync.when(
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                    data: (empaques) {
                      if (empaques.isEmpty) return const SizedBox.shrink();
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text(
                                'Seleccionar empaque',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.cream.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'Auto-rellena',
                                  style: TextStyle(
                                    color: AppColors.cream,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              ...empaques.map((emp) {
                                final sel = empaqueSeleccionado?.id == emp.id;
                                return GestureDetector(
                                  onTap: () {
                                    setModal(() {
                                      if (sel) {
                                        empaqueSeleccionado = null;
                                        tipoUnidadCtrl.text = proyecto.tipoUnidadDefault ?? '';
                                        cantPorUnidadCtrl.text = proyecto.cantidadPorUnidadDefault != null
                                            ? proyecto.cantidadPorUnidadDefault!.toStringAsFixed(
                                                proyecto.cantidadPorUnidadDefault! == proyecto.cantidadPorUnidadDefault!.roundToDouble() ? 0 : 1)
                                            : '';
                                        unidadMedida = proyecto.unidadMedidaDefault ?? 'und';
                                      } else {
                                        empaqueSeleccionado = emp;
                                        tipoUnidadCtrl.text = emp.nombre;
                                        cantPorUnidadCtrl.text = emp.cantidadPorUnidad.toStringAsFixed(
                                          emp.cantidadPorUnidad == emp.cantidadPorUnidad.roundToDouble() ? 0 : 1,
                                        );
                                        unidadMedida = emp.unidadMedida;
                                      }
                                    });
                                    recalcPrecio(setModal);
                                  },
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 150),
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                                    decoration: BoxDecoration(
                                      color: sel ? AppColors.cream : AppColors.cream.withValues(alpha: 0.08),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: sel ? AppColors.cream : AppColors.cream.withValues(alpha: 0.3),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (sel) ...[
                                          const Icon(Icons.check_circle, size: 16, color: AppColors.background),
                                          const SizedBox(width: 4),
                                        ],
                                        Text(
                                          '${emp.nombre} (${emp.cantidadPorUnidad.toStringAsFixed(0)} ${emp.unidadMedida})',
                                          style: TextStyle(
                                            color: sel ? AppColors.background : AppColors.cream,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }),
                              GestureDetector(
                                onTap: () => setModal(() {
                                  empaqueSeleccionado = null;
                                  tipoUnidadCtrl.clear();
                                  cantPorUnidadCtrl.clear();
                                }),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: AppColors.border),
                                  ),
                                  child: const Text(
                                    'Manual...',
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (empaqueSeleccionado?.descripcion != null &&
                              empaqueSeleccionado!.descripcion!.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppColors.cream.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.info_outline, size: 14, color: AppColors.cream),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        empaqueSeleccionado!.descripcion!,
                                        style: const TextStyle(
                                          color: AppColors.textMuted,
                                          fontSize: 11,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          const SizedBox(height: 12),
                        ],
                      );
                    },
                  ),
                  if (proyecto.tipoPlantilla != 'TRANSPORTE') ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _sheetField(tipoUnidadCtrl, 'Tipo de empaque/lote', 'Ej: Caja, Paquete, Lote'),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Unidad de medida', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 6,
                                children: ['und', 'kg', 'lt', 'pz', 'm'].map((u) {
                                  final sel = unidadMedida == u;
                                  return GestureDetector(
                                    onTap: () => setModal(() => unidadMedida = u),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: sel ? AppColors.cream : AppColors.background,
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: sel ? AppColors.cream : AppColors.border),
                                      ),
                                      child: Text(u, style: TextStyle(color: sel ? AppColors.background : AppColors.textSecondary, fontWeight: FontWeight.w500, fontSize: 12)),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _sheetField(
                            cantidadCtrl,
                            empaqueSeleccionado != null ? 'Cantidad de ${empaqueSeleccionado!.nombre}s' : 'Cantidad',
                            empaqueSeleccionado != null ? 'Ej: 10' : 'Ej: 200',
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                            onChanged: (_) => recalcPrecio(setModal),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _sheetField(
                            cantPorUnidadCtrl,
                            'Cant. por empaque ($unidadMedida)',
                            'Ej: 50',
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                            onChanged: (_) => recalcPrecio(setModal),
                          ),
                        ),
                      ],
                    ),
                    if (cantidadCtrl.text.isNotEmpty && cantPorUnidadCtrl.text.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.cream.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.inventory_2_outlined, size: 14, color: AppColors.cream),
                            const SizedBox(width: 6),
                            Text(
                              'Stock total: ${((double.tryParse(cantidadCtrl.text) ?? 0) * (double.tryParse(cantPorUnidadCtrl.text) ?? 0)).toStringAsFixed(0)} $unidadMedida',
                              style: const TextStyle(color: AppColors.cream, fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    _sheetField(
                      inversionCtrl, 'Inversión Total', 'Ej: 5000',
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                      onChanged: (_) => recalcPrecio(setModal),
                    ),
                    const SizedBox(height: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text('Precio de Venta /$unidadMedida', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
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
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
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
                          const Text('A este precio recuperas exactamente tu inversión.', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                        ],
                      ],
                    ),
                  ],
                  if (proyecto.tipoPlantilla == 'TRANSPORTE') ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.cream.withValues(alpha: 0.07),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.cream.withValues(alpha: 0.25)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, size: 14, color: AppColors.cream),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Los gastos e ingresos del vehículo se registran dentro del detalle.',
                              style: TextStyle(color: AppColors.cream, fontSize: 11),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: ctx2, initialDate: fechaApertura, firstDate: DateTime(2020), lastDate: DateTime.now(),
                        builder: (c, child) => Theme(data: ThemeData.dark(), child: child!),
                      );
                      if (picked != null) setModal(() => fechaApertura = picked);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border)),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Fecha de apertura', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                          Row(children: [
                            Text(DateFormat('dd MMM yyyy', 'es').format(fechaApertura), style: const TextStyle(color: AppColors.cream, fontWeight: FontWeight.w500, fontSize: 13)),
                            const SizedBox(width: 6),
                            const Icon(Icons.calendar_today_outlined, size: 14, color: AppColors.cream),
                          ]),
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
                        final esTransporte = proyecto.tipoPlantilla == 'TRANSPORTE';

                        if (esTransporte) {
                          // Para Transporte: validación mínima, inversión = 0, precio = 1
                          if (nombre.isEmpty || producto.isEmpty) {
                            ScaffoldMessenger.of(ctx2).showSnackBar(const SnackBar(content: Text('Completa nombre y tipo de servicio')));
                            return;
                          }
                          setModal(() => loading = true);
                          try {
                            await ref.read(cuentaRepositoryProvider).crearCuenta(
                              proyectoId: proyecto.id,
                              nombre: nombre,
                              producto: producto,
                              tipoUnidad: 'Viaje',
                              unidadMedida: 'viaje',
                              cantidadUnidades: 1,
                              cantidadPorUnidad: 1,
                              inversionTotal: 0,
                              precioUnitario: 1,
                              creadoPor: '',
                              fechaApertura: fechaApertura,
                            );
                            ref.invalidate(cuentasProvider(proyecto.id));
                            if (ctx2.mounted) Navigator.pop(ctx2);
                          } catch (e) {
                            setModal(() => loading = false);
                            if (ctx2.mounted) {
                              ScaffoldMessenger.of(ctx2).showSnackBar(SnackBar(content: Text(ErrorHandler.parse(e))));
                            }
                          }
                          return;
                        }

                        final cantidad = double.tryParse(cantidadCtrl.text);
                        final cpu = double.tryParse(cantPorUnidadCtrl.text);
                        final inversion = double.tryParse(inversionCtrl.text);
                        final precio = double.tryParse(precioCtrl.text);

                        if (nombre.isEmpty || producto.isEmpty || cantidad == null || cpu == null || inversion == null || precio == null) {
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
                            tipoUnidad: tipoUnidadCtrl.text.isEmpty ? 'Unidad' : tipoUnidadCtrl.text,
                            unidadMedida: unidadMedida,
                            cantidadUnidades: cantidad,
                            cantidadPorUnidad: cpu,
                            inversionTotal: inversion,
                            precioUnitario: precio,
                            creadoPor: '',
                            fechaApertura: fechaApertura,
                          );
                          ref.invalidate(cuentasProvider(proyecto.id));
                          if (ctx2.mounted) Navigator.pop(ctx2);
                        } catch (e) {
                          setModal(() => loading = false);
                          if (ctx2.mounted) {
                            ScaffoldMessenger.of(ctx2).showSnackBar(SnackBar(content: Text(ErrorHandler.parse(e))));
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
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                          : Text(
                              proyecto.tipoPlantilla == 'TRANSPORTE' ? 'Registrar Vehículo' : 'Crear Cuenta',
                              style: const TextStyle(fontWeight: FontWeight.w600),
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
  Widget _sheetField(
    TextEditingController ctrl,
    String label,
    String hint, {
    TextInputType? keyboardType,
    Function(String)? onChanged,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          onChanged: onChanged,
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
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
      ],
    );
  }

  // ─── NUEVO EMPAQUE ──────────────────────────────────────────────────────────
  void _showNuevoEmpaqueSheet(BuildContext context, WidgetRef ref) {
    final nombreCtrl = TextEditingController();
    final cantidadCtrl = TextEditingController();
    final medidaCtrl = TextEditingController();
    final descripcionCtrl = TextEditingController();
    String? medidaSeleccionada;
    bool loading = false;
    const List<String> medidasRapidas = ['kg', 'lb', 'und', 'lt', 'pz', 'm'];

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx2, setModal) {
          return Padding(
            padding: EdgeInsets.fromLTRB(
              24, 20, 24,
              MediaQuery.of(ctx2).viewInsets.bottom + 32,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 36, height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.borderLight,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Nuevo Empaque',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Ej: "Caja Mediana", "Bugui", "Saco de 50kg"',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                  ),
                  const SizedBox(height: 20),
                  // NOMBRE
                  _sheetField(nombreCtrl, 'Nombre del empaque', 'Ej: Bugui, Caja, Saco...'),
                  const SizedBox(height: 16),
                  // MEDIDA — botones rápidos + campo libre
                  const Text(
                    'Unidad de medida',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ...medidasRapidas.map((m) => GestureDetector(
                        onTap: () => setModal(() {
                          medidaSeleccionada = m;
                          medidaCtrl.clear();
                        }),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                          decoration: BoxDecoration(
                            color: medidaSeleccionada == m
                                ? AppColors.cream
                                : AppColors.background,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: medidaSeleccionada == m
                                  ? AppColors.cream
                                  : AppColors.border,
                            ),
                          ),
                          child: Text(
                            m,
                            style: TextStyle(
                              color: medidaSeleccionada == m
                                  ? AppColors.background
                                  : AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      )),
                      // Botón "Otra"
                      GestureDetector(
                        onTap: () => setModal(() => medidaSeleccionada = null),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                          decoration: BoxDecoration(
                            color: medidaSeleccionada == null && medidaCtrl.text.isEmpty
                                ? AppColors.background
                                : medidaSeleccionada == null
                                    ? AppColors.cream.withValues(alpha: 0.15)
                                    : AppColors.background,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: medidaSeleccionada == null && medidaCtrl.text.isNotEmpty
                                  ? AppColors.cream
                                  : AppColors.border,
                            ),
                          ),
                          child: Text(
                            'Otra...',
                            style: TextStyle(
                              color: medidaSeleccionada == null && medidaCtrl.text.isNotEmpty
                                  ? AppColors.cream
                                  : AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  // Campo libre para medida personalizada
                  AnimatedSize(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    child: medidaSeleccionada == null
                        ? Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: TextField(
                              controller: medidaCtrl,
                              onChanged: (_) => setModal(() {}),
                              style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                              decoration: InputDecoration(
                                hintText: 'Escribe tu unidad (Ej: baldes, atados)',
                                hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                                filled: true,
                                fillColor: AppColors.background,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
                                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.cream)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              ),
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                  const SizedBox(height: 16),
                  // CANTIDAD POR UNIDAD
                  _sheetField(
                    cantidadCtrl,
                    'Cantidad por unidad (¿cuánto contiene?)',
                    'Ej: 150 (si un Bugui tiene 150 kg)',
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                  ),
                  const SizedBox(height: 16),
                  // DESCRIPCIÓN (opcional)
                  _sheetField(
                    descripcionCtrl,
                    'Descripción (opcional)',
                    'Ej: Tiene 8 bandejas, para papaya de exportación',
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: loading ? null : () async {
                        final nombre = nombreCtrl.text.trim();
                        final unidad = medidaSeleccionada ?? medidaCtrl.text.trim();
                        final cantidad = double.tryParse(cantidadCtrl.text);

                        if (nombre.isEmpty) {
                          ScaffoldMessenger.of(ctx2).showSnackBar(
                            const SnackBar(content: Text('Ingresa el nombre del empaque')),
                          );
                          return;
                        }
                        if (unidad.isEmpty) {
                          ScaffoldMessenger.of(ctx2).showSnackBar(
                            const SnackBar(content: Text('Selecciona o escribe la unidad de medida')),
                          );
                          return;
                        }
                        if (cantidad == null || cantidad <= 0) {
                          ScaffoldMessenger.of(ctx2).showSnackBar(
                            const SnackBar(content: Text('Ingresa una cantidad válida mayor a 0')),
                          );
                          return;
                        }

                        setModal(() => loading = true);
                        try {
                          await ref.read(empaqueRepositoryProvider).crearEmpaque(
                            proyectoId: proyecto.id,
                            nombre: nombre,
                            unidadMedida: unidad,
                            cantidadPorUnidad: cantidad,
                            descripcion: descripcionCtrl.text.trim().isEmpty
                                ? null
                                : descripcionCtrl.text.trim(),
                          );
                          ref.invalidate(empaquesProvider(proyecto.id));
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
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: loading
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: AppColors.background, strokeWidth: 2))
                          : const Text('Guardar Empaque', style: TextStyle(fontWeight: FontWeight.w600)),
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

  void _confirmDeleteEmpaque(BuildContext context, WidgetRef ref, EmpaqueModel empaque) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Eliminar Empaque', style: TextStyle(color: AppColors.textPrimary)),
        content: Text(
          '¿Eliminar "${empaque.nombre}"? Esto no afecta las cuentas ya creadas.',
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
                await ref.read(empaqueRepositoryProvider).eliminarEmpaque(
                  proyectoId: proyecto.id,
                  empaqueId: empaque.id,
                );
                ref.invalidate(empaquesProvider(proyecto.id));
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(ErrorHandler.parse(e))),
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
}
