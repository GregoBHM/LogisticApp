import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:excel/excel.dart' as xl;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/models/models.dart';
import '../../projects/providers/project_providers.dart';

class ReportesScreen extends ConsumerStatefulWidget {
  final CuentaResumenModel cuenta;
  final String proyectoNombre;
  final String monedaSimbolo;

  const ReportesScreen({
    super.key,
    required this.cuenta,
    required this.proyectoNombre,
    this.monedaSimbolo = '\$',
  });

  @override
  ConsumerState<ReportesScreen> createState() => _ReportesScreenState();
}

class _ReportesScreenState extends ConsumerState<ReportesScreen> {
  bool incluyeVentas = true;
  bool incluyeGastos = true;
  bool incluyeGanancias = true;
  bool incluyeStock = true;
  bool incluyeEquipo = false;
  bool _exporting = false;

  DateTime? _desde;
  DateTime? _hasta;

  Future<void> _pickDesde() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _desde ?? DateTime.now().subtract(const Duration(days: 30)),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (c, child) => Theme(data: ThemeData.dark(), child: child!),
    );
    if (picked != null) setState(() => _desde = picked);
  }

  Future<void> _pickHasta() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _hasta ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (c, child) => Theme(data: ThemeData.dark(), child: child!),
    );
    if (picked != null) setState(() => _hasta = picked);
  }

  Future<void> _exportarExcel() async {
    setState(() => _exporting = true);
    try {
      final ventas = ref.read(ventasProvider(widget.cuenta.id)).value ?? [];
      final gastos = ref.read(gastosFamilyProvider(widget.cuenta.id)).value ?? [];
      final sym = widget.monedaSimbolo;
      final fmt = DateFormat('dd/MM/yyyy', 'es');

      // Filter by date range if set
      final ventasFiltradas = ventas.where((v) {
        if (_desde != null && v.fechaVenta.isBefore(_desde!)) return false;
        if (_hasta != null && v.fechaVenta.isAfter(_hasta!.add(const Duration(days: 1)))) return false;
        return true;
      }).toList();

      final gastosFiltrados = gastos.where((g) {
        if (_desde != null && g.fechaGasto.isBefore(_desde!)) return false;
        if (_hasta != null && g.fechaGasto.isAfter(_hasta!.add(const Duration(days: 1)))) return false;
        return true;
      }).toList();

      final excel = xl.Excel.createExcel();

      // ---- RESUMEN SHEET ----
      final resumenSheet = excel['Resumen'];
      excel.setDefaultSheet('Resumen');

      void addRow(xl.Sheet sheet, List<String> data, {bool bold = false}) {
        final row = sheet.maxRows;
        for (var i = 0; i < data.length; i++) {
          final cell = sheet.cell(xl.CellIndex.indexByColumnRow(columnIndex: i, rowIndex: row));
          cell.value = xl.TextCellValue(data[i]);
          if (bold) cell.cellStyle = xl.CellStyle(bold: bold);
        }
      }

      addRow(resumenSheet, ['REPORTE: ${widget.cuenta.producto} · ${widget.cuenta.nombre}'], bold: true);
      addRow(resumenSheet, ['Proyecto:', widget.proyectoNombre]);
      addRow(resumenSheet, ['Generado:', fmt.format(DateTime.now())]);
      if (_desde != null || _hasta != null) {
        addRow(resumenSheet, [
          'Período:',
          '${_desde != null ? fmt.format(_desde!) : "inicio"} - ${_hasta != null ? fmt.format(_hasta!) : "hoy"}'
        ]);
      }
      addRow(resumenSheet, []);

      if (incluyeGanancias) {
        addRow(resumenSheet, ['FINANCIERO'], bold: true);
        addRow(resumenSheet, ['Inversión Total', '$sym ${widget.cuenta.inversionTotal.toStringAsFixed(2)}']);
        addRow(resumenSheet, ['Ingresos Brutos', '$sym ${widget.cuenta.ingresosBrutos.toStringAsFixed(2)}']);
        addRow(resumenSheet, ['Total Cobrado', '$sym ${widget.cuenta.totalCobrado.toStringAsFixed(2)}']);
        addRow(resumenSheet, ['Total Gastos', '$sym ${widget.cuenta.totalGastos.toStringAsFixed(2)}']);
        addRow(resumenSheet, ['Ganancia Real', '$sym ${widget.cuenta.gananciaReal.toStringAsFixed(2)}']);
        addRow(resumenSheet, []);
      }

      if (incluyeStock) {
        addRow(resumenSheet, ['INVENTARIO'], bold: true);
        addRow(resumenSheet, ['Kilos Totales', '${widget.cuenta.kilosTotales.toStringAsFixed(1)} kg']);
        addRow(resumenSheet, ['Kilos Vendidos', '${widget.cuenta.kilosVendidos.toStringAsFixed(1)} kg']);
        addRow(resumenSheet, ['Kilos Restantes', '${widget.cuenta.kilosRestantes.toStringAsFixed(1)} kg']);
        addRow(resumenSheet, []);
      }

      // ---- VENTAS SHEET ----
      if (incluyeVentas && ventasFiltradas.isNotEmpty) {
        final ventasSheet = excel['Ventas'];
        addRow(ventasSheet, ['Fecha', 'Cliente', 'Kilos', 'Precio/Kg', 'Total', 'Abonado', 'Saldo', 'Estado'], bold: true);
        for (final v in ventasFiltradas) {
          addRow(ventasSheet, [
            fmt.format(v.fechaVenta),
            v.cliente,
            v.kilosVendidos.toStringAsFixed(1),
            '$sym ${v.precioPorKg.toStringAsFixed(2)}',
            '$sym ${v.totalVenta.toStringAsFixed(2)}',
            '$sym ${v.totalAbonado.toStringAsFixed(2)}',
            '$sym ${v.saldoPendiente.toStringAsFixed(2)}',
            v.estadoPago,
          ]);
        }
        addRow(ventasSheet, []);
        final totalVentas = ventasFiltradas.fold(0.0, (s, v) => s + v.totalVenta);
        addRow(ventasSheet, ['', '', '', 'TOTAL', '$sym ${totalVentas.toStringAsFixed(2)}'], bold: true);
      }

      // ---- GASTOS SHEET ----
      if (incluyeGastos && gastosFiltrados.isNotEmpty) {
        final gastosSheet = excel['Gastos'];
        addRow(gastosSheet, ['Fecha', 'Descripción', 'Monto', 'Registrado por'], bold: true);
        for (final g in gastosFiltrados) {
          addRow(gastosSheet, [
            fmt.format(g.fechaGasto),
            g.descripcion,
            '$sym ${g.monto.toStringAsFixed(2)}',
            g.registradoPorNombre,
          ]);
        }
        addRow(gastosSheet, []);
        final totalGastos = gastosFiltrados.fold(0.0, (s, g) => s + g.monto);
        addRow(gastosSheet, ['', 'TOTAL', '$sym ${totalGastos.toStringAsFixed(2)}'], bold: true);
      }

      // Save and share
      final bytes = excel.save()!;
      final dir = await getTemporaryDirectory();
      final fileName = 'Reporte_${widget.cuenta.producto}_${DateFormat('dd-MM-yyyy').format(DateTime.now())}.xlsx';
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(bytes);

      await Share.shareXFiles([XFile(file.path)], text: 'Reporte de ${widget.cuenta.producto}');
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al exportar: $e')));
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ganancia = widget.cuenta.gananciaReal;
    final sym = widget.monedaSimbolo;
    final fmt = DateFormat('dd MMM yyyy', 'es');

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, size: 16), onPressed: () => Navigator.pop(context)),
        title: const Text('Exportar Reporte'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        children: [
          Text('${widget.cuenta.producto} · ${widget.cuenta.nombre}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _metricTile('Ingresos', '$sym ${widget.cuenta.totalCobrado.toStringAsFixed(0)}', AppColors.textPrimary)),
              const SizedBox(width: 8),
              Expanded(child: _metricTile('Inversión', '$sym ${widget.cuenta.inversionTotal.toStringAsFixed(0)}', AppColors.negative)),
              const SizedBox(width: 8),
              Expanded(child: _metricTile('Neto', '${ganancia >= 0 ? '+' : ''}$sym ${ganancia.toStringAsFixed(0)}', ganancia >= 0 ? AppColors.positive : AppColors.negative)),
            ],
          ),
          const SizedBox(height: 24),
          const Text('RANGO DE FECHAS', style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w500, letterSpacing: 0.5)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: _pickDesde,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _desde != null ? AppColors.cream : AppColors.border),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_outlined, size: 14, color: AppColors.textSecondary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _desde != null ? fmt.format(_desde!) : 'Desde',
                            style: TextStyle(
                              color: _desde != null ? AppColors.cream : AppColors.textMuted,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        if (_desde != null)
                          GestureDetector(
                            onTap: () => setState(() => _desde = null),
                            child: const Icon(Icons.close, size: 14, color: AppColors.textMuted),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Text('→', style: TextStyle(color: AppColors.textMuted)),
              const SizedBox(width: 8),
              Expanded(
                child: GestureDetector(
                  onTap: _pickHasta,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _hasta != null ? AppColors.cream : AppColors.border),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_outlined, size: 14, color: AppColors.textSecondary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _hasta != null ? fmt.format(_hasta!) : 'Hasta',
                            style: TextStyle(
                              color: _hasta != null ? AppColors.cream : AppColors.textMuted,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        if (_hasta != null)
                          GestureDetector(
                            onTap: () => setState(() => _hasta = null),
                            child: const Icon(Icons.close, size: 14, color: AppColors.textMuted),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (_desde == null && _hasta == null)
            const Padding(
              padding: EdgeInsets.only(top: 6),
              child: Text('Sin filtro: se exportará todo el historial.', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
            ),
          const SizedBox(height: 24),
          const Text('INCLUIR EN REPORTE', style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w500, letterSpacing: 0.5)),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                _toggleRow('Ventas', incluyeVentas, (v) => setState(() => incluyeVentas = v)),
                const Divider(color: AppColors.border, height: 1),
                _toggleRow('Gastos', incluyeGastos, (v) => setState(() => incluyeGastos = v)),
                const Divider(color: AppColors.border, height: 1),
                _toggleRow('Ganancias / Financiero', incluyeGanancias, (v) => setState(() => incluyeGanancias = v)),
                const Divider(color: AppColors.border, height: 1),
                _toggleRow('Stock / Inventario', incluyeStock, (v) => setState(() => incluyeStock = v)),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _exporting ? null : _exportarExcel,
              icon: _exporting
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                  : const Icon(Icons.table_chart_outlined, size: 18),
              label: Text(_exporting ? 'Generando...' : 'Exportar Excel y Compartir', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.cream,
                foregroundColor: AppColors.background,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _metricTile(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _toggleRow(String label, bool value, Function(bool) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13)),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.cream,
            activeTrackColor: AppColors.cream.withValues(alpha: 0.3),
            inactiveThumbColor: AppColors.textMuted,
            inactiveTrackColor: AppColors.surface,
          ),
        ],
      ),
    );
  }
}
