import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/models/models.dart';
import '../providers/project_providers.dart';
import '../../auth/providers/auth_providers.dart';
import 'proyecto_detalle_screen.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final proyectosAsync = ref.watch(proyectosProvider);
    final perfilAsync = ref.watch(perfilProvider);

    return Scaffold(
      body: SafeArea(
        child: proyectosAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: AppColors.negative))),
          data: (proyectos) {
            final nombre = perfilAsync.value?.nombre ?? '';
            return RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(proyectosProvider);
                ref.invalidate(perfilProvider);
              },
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('GyL Logistic', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 22, letterSpacing: -0.5)),
                        const SizedBox(height: 2),
                        Text(nombre.isNotEmpty ? 'Hola, $nombre' : 'Panel de control', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                      ],
                    ),
                    GestureDetector(
                      onTap: () => _showPerfilMenu(context, ref),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: const Icon(Icons.person_outline, color: AppColors.textSecondary, size: 18),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    _quickStat('${proyectos.length}', 'Proyectos'),
                    const SizedBox(width: 8),
                    _quickStat(
                      '${proyectos.fold<int>(0, (s, p) => s + (ref.watch(cuentasProvider(p.id)).value?.where((c) => c.estaAbierta).length ?? 0))}',
                      'Cuentas activas',
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                const Text('Proyectos', style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w500, letterSpacing: 0.5)),
                const SizedBox(height: 12),
                if (proyectos.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Column(
                        children: [
                          const Icon(Icons.folder_open_outlined, color: AppColors.textMuted, size: 40),
                          const SizedBox(height: 12),
                          const Text('Aún no tienes proyectos', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                          const SizedBox(height: 6),
                          const Text('Toca + para crear tu primer proyecto', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                        ],
                      ),
                    ),
                  )
                else
                  ...proyectos.map((p) => _buildProyectoCard(context, ref, p)),
              ],
            ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.small(
        onPressed: () => _showNuevoProyectoSheet(context, ref),
        backgroundColor: AppColors.cream,
        foregroundColor: AppColors.background,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: const Icon(Icons.add, size: 20),
      ),
    );
  }

  Widget _quickStat(String value, String label) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              Text(value, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 20)),
              const SizedBox(height: 2),
              Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
            ],
          ),
        ),
      );

  Widget _buildProyectoCard(BuildContext context, WidgetRef ref, ProyectoModel proyecto) {
    final cuentasAsync = ref.watch(cuentasProvider(proyecto.id));
    final cuentas = cuentasAsync.value ?? [];
    final abiertas = cuentas.where((c) => c.estaAbierta).length;
    final gananciaTotal = cuentas.fold<double>(0, (s, c) => s + c.gananciaReal);
    final sym = proyecto.monedaSimbolo;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProyectoDetalleScreen(proyecto: proyecto))),
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
                  // ── Ícono del tipo de proyecto ──
                  Container(
                    padding: const EdgeInsets.all(5),
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: AppColors.cream.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      proyecto.tipoPlantilla == 'TRANSPORTE'
                          ? Icons.local_shipping_rounded
                          : Icons.storefront_rounded,
                      color: AppColors.cream,
                      size: 14,
                    ),
                  ),
                  Expanded(
                    child: Text(proyecto.nombre, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w500, fontSize: 15)),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: abiertas > 0 ? AppColors.positiveSubtle : AppColors.surface,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: abiertas > 0 ? AppColors.positive.withValues(alpha: 0.2) : AppColors.border),
                    ),
                    child: Text(
                      abiertas > 0
                          ? proyecto.tipoPlantilla == 'TRANSPORTE'
                              ? '$abiertas vehículo${abiertas > 1 ? 's' : ''} activo${abiertas > 1 ? 's' : ''}'
                              : '$abiertas activa${abiertas > 1 ? 's' : ''}'
                          : proyecto.tipoPlantilla == 'TRANSPORTE'
                              ? 'Sin vehículos'
                              : 'Sin cuentas activas',
                      style: TextStyle(color: abiertas > 0 ? AppColors.positive : AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
              if (proyecto.descripcion?.isNotEmpty == true) ...[
                const SizedBox(height: 6),
                Text(proyecto.descripcion!, style: const TextStyle(color: AppColors.textMuted, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
              const SizedBox(height: 14),
              Row(
                children: [
                  _metricPill(
                    Icons.trending_up,
                    '${gananciaTotal >= 0 ? '+' : ''}$sym ${gananciaTotal.toStringAsFixed(0)}',
                    gananciaTotal >= 0 ? AppColors.positive : AppColors.negative,
                  ),
                  const SizedBox(width: 12),
                  _metricPill(
                    proyecto.tipoPlantilla == 'TRANSPORTE' ? Icons.directions_car_rounded : Icons.inventory_2_outlined,
                    proyecto.tipoPlantilla == 'TRANSPORTE'
                        ? '${cuentas.length} vehículo${cuentas.length != 1 ? 's' : ''}'
                        : '${cuentas.length} cuenta${cuentas.length != 1 ? 's' : ''}',
                    AppColors.textSecondary,
                  ),
                  const Spacer(),
                  const Icon(Icons.arrow_forward_ios, size: 12, color: AppColors.textMuted),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _metricPill(IconData icon, String text, Color color) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(text, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w500)),
        ],
      );

  void _showPerfilMenu(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: AppColors.borderLight, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.logout, color: AppColors.negative, size: 20),
              title: const Text('Cerrar sesión', style: TextStyle(color: AppColors.negative, fontSize: 14)),
              onTap: () async {
                Navigator.pop(context);
                await ref.read(authRepositoryProvider).signOut();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showNuevoProyectoSheet(BuildContext context, WidgetRef ref) {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final productoCtrl = TextEditingController();
    final tipoUnidadCtrl = TextEditingController();
    final cantPorUnidadCtrl = TextEditingController();
    String monedaSimbolo = 'S/';
    String monedaCodigo = 'PEN';
    String? unidadMedidaDefault;
    bool showPlantilla = false;
    String tipoPlantilla = 'COMERCIO';

    final monedas = [
      {'simbolo': 'S/', 'codigo': 'PEN', 'label': 'Sol Peruano (S/)'},
      {'simbolo': '\$', 'codigo': 'USD', 'label': 'Dólar (USD)'},
      {'simbolo': 'MXN', 'codigo': 'MXN', 'label': 'Peso Mexicano (MXN)'},
      {'simbolo': 'COP', 'codigo': 'COP', 'label': 'Peso Colombiano (COP)'},
      {'simbolo': '€', 'codigo': 'EUR', 'label': 'Euro (€)'},
    ];

    final unidades = ['kg', 'lb', 'und', 'lt', 'pz', 'm'];

    Widget buildLabel(String text) => Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text(
            text,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        );

    Widget buildField(
      TextEditingController ctrl,
      String hint, {
      TextInputType? keyboardType,
      List<TextInputFormatter>? inputFormatters,
    }) =>
        TextField(
          controller: ctrl,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
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
        );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(
            24,
            20,
            24,
            MediaQuery.of(context).viewInsets.bottom + 32,
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
                  'Nuevo Proyecto',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Configura tu negocio y su plantilla de operaciones',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                ),
                const SizedBox(height: 20),

                // ── SECCIÓN 1: DATOS DEL NEGOCIO ──
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppColors.cream.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Icon(
                              Icons.business_outlined,
                              color: AppColors.cream,
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'Datos del Negocio',
                            style: TextStyle(
                              color: AppColors.cream,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      buildLabel('Nombre del proyecto'),
                      buildField(nameCtrl, 'Ej. Distribuidora San Juan'),
                      const SizedBox(height: 12),
                      buildLabel('Descripción (opcional)'),
                      buildField(descCtrl, 'Ej. Ventas de papaya zona norte'),
                      const SizedBox(height: 12),
                      buildLabel('Moneda'),
                      DropdownButtonFormField<String>(
                        initialValue: monedaCodigo,
                        dropdownColor: AppColors.surface,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                        ),
                        decoration: InputDecoration(
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
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                        ),
                        items: monedas
                            .map(
                              (m) => DropdownMenuItem(
                                value: m['codigo'],
                                child: Text(m['label']!),
                              ),
                            )
                            .toList(),
                        onChanged: (val) {
                          if (val == null) return;
                          setModalState(() {
                            monedaCodigo = val;
                            monedaSimbolo = monedas.firstWhere(
                              (m) => m['codigo'] == val,
                            )['simbolo']!;
                          });
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ── TIPO DE PROYECTO ──
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tipo de proyecto',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        // COMERCIO
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setModalState(() => tipoPlantilla = 'COMERCIO'),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                              decoration: BoxDecoration(
                                color: tipoPlantilla == 'COMERCIO'
                                    ? AppColors.cream.withValues(alpha: 0.12)
                                    : AppColors.background,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: tipoPlantilla == 'COMERCIO'
                                      ? AppColors.cream
                                      : AppColors.border,
                                  width: tipoPlantilla == 'COMERCIO' ? 1.5 : 1,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.storefront_rounded,
                                    color: tipoPlantilla == 'COMERCIO'
                                        ? AppColors.cream
                                        : AppColors.textMuted,
                                    size: 24,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Comercio',
                                    style: TextStyle(
                                      color: tipoPlantilla == 'COMERCIO'
                                          ? AppColors.cream
                                          : AppColors.textSecondary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Frutas, ropa, abarrotes',
                                    style: TextStyle(
                                      color: tipoPlantilla == 'COMERCIO'
                                          ? AppColors.cream.withValues(alpha: 0.7)
                                          : AppColors.textMuted,
                                      fontSize: 10,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        // TRANSPORTE
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setModalState(() => tipoPlantilla = 'TRANSPORTE'),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                              decoration: BoxDecoration(
                                color: tipoPlantilla == 'TRANSPORTE'
                                    ? AppColors.cream.withValues(alpha: 0.12)
                                    : AppColors.background,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: tipoPlantilla == 'TRANSPORTE'
                                      ? AppColors.cream
                                      : AppColors.border,
                                  width: tipoPlantilla == 'TRANSPORTE' ? 1.5 : 1,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.local_shipping_rounded,
                                    color: tipoPlantilla == 'TRANSPORTE'
                                        ? AppColors.cream
                                        : AppColors.textMuted,
                                    size: 24,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Transporte',
                                    style: TextStyle(
                                      color: tipoPlantilla == 'TRANSPORTE'
                                          ? AppColors.cream
                                          : AppColors.textSecondary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Flota, fletes, vehículos',
                                    style: TextStyle(
                                      color: tipoPlantilla == 'TRANSPORTE'
                                          ? AppColors.cream.withValues(alpha: 0.7)
                                          : AppColors.textMuted,
                                      fontSize: 10,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 14),


                GestureDetector(
                  onTap: () =>
                      setModalState(() => showPlantilla = !showPlantilla),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: showPlantilla
                          ? AppColors.cream.withValues(alpha: 0.08)
                          : AppColors.background,
                      borderRadius: showPlantilla
                          ? const BorderRadius.vertical(
                              top: Radius.circular(12),
                            )
                          : BorderRadius.circular(12),
                      border: Border.all(
                        color: showPlantilla
                            ? AppColors.cream.withValues(alpha: 0.3)
                            : AppColors.border,
                      ),
                    ),
                    child: Row(
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
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Plantilla de Operaciones',
                                style: TextStyle(
                                  color: AppColors.cream,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                showPlantilla
                                    ? 'Los lotes nuevos se rellenan solos'
                                    : 'Toca para configurar tu producto principal',
                                style: const TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          showPlantilla
                              ? Icons.keyboard_arrow_up_rounded
                              : Icons.keyboard_arrow_down_rounded,
                          color: AppColors.cream,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),

                // ── SECCIÓN 2: PLANTILLA (COLAPSABLE) ──
                AnimatedSize(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                  child: showPlantilla
                      ? Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: const BorderRadius.vertical(
                              bottom: Radius.circular(12),
                            ),
                            border: Border.all(
                              color: AppColors.cream.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              buildLabel('¿Qué producto manejas?'),
                              buildField(
                                productoCtrl,
                                'Ej. Papaya, Ropa, Café',
                              ),
                              const SizedBox(height: 12),
                              buildLabel('¿Cómo lo empacas/transportas?'),
                              buildField(
                                tipoUnidadCtrl,
                                'Ej. Caja, Saco, Paquete',
                              ),
                              const SizedBox(height: 12),
                              buildLabel('Unidad de medida'),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: unidades.map((u) {
                                  final sel = unidadMedidaDefault == u;
                                  return GestureDetector(
                                    onTap: () => setModalState(
                                      () => unidadMedidaDefault = u,
                                    ),
                                    child: AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 150,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: sel
                                            ? AppColors.cream
                                            : AppColors.surface,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: sel
                                              ? AppColors.cream
                                              : AppColors.border,
                                        ),
                                        boxShadow: sel
                                            ? [
                                                BoxShadow(
                                                  color: AppColors.cream
                                                      .withValues(alpha: 0.2),
                                                  blurRadius: 8,
                                                  spreadRadius: 0,
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
                              if (unidadMedidaDefault != null) ...[
                                const SizedBox(height: 12),
                                buildLabel(
                                  'Cantidad por empaque ($unidadMedidaDefault)',
                                ),
                                buildField(
                                  cantPorUnidadCtrl,
                                  'Ej. 20',
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                                ),
                              ],
                            ],
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
                const SizedBox(height: 24),

                // ── BOTÓN CREAR ──
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: nameCtrl.text.trim().length >= 2
                        ? () async {
                            final perfil = ref.read(perfilProvider).value;
                            if (perfil == null) return;
                            await ref
                                .read(proyectoRepositoryProvider)
                                .crearProyecto(
                                  nombre: nameCtrl.text,
                                  descripcion: descCtrl.text.isEmpty
                                      ? null
                                      : descCtrl.text,
                                  monedaSimbolo: monedaSimbolo,
                                  monedaCodigo: monedaCodigo,
                                  creadoPor: perfil.id,
                                  productoDefault:
                                      productoCtrl.text.trim().isNotEmpty
                                          ? productoCtrl.text
                                          : null,
                                  tipoUnidadDefault:
                                      tipoUnidadCtrl.text.trim().isNotEmpty
                                          ? tipoUnidadCtrl.text
                                          : null,
                                  unidadMedidaDefault: unidadMedidaDefault,
                                  cantidadPorUnidadDefault: double.tryParse(
                                    cantPorUnidadCtrl.text,
                                  ),
                                  tipoPlantilla: tipoPlantilla,
                                );
                            if (ctx.mounted) Navigator.pop(ctx);
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.cream,
                      foregroundColor: AppColors.background,
                      disabledBackgroundColor: AppColors.border,
                      disabledForegroundColor: AppColors.textMuted,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Crear Proyecto',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

