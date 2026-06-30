import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:excel/excel.dart' as xl;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../projects/providers/project_providers.dart';

class ReportesScreen extends ConsumerStatefulWidget {
  final String proyectoId;
  final String proyectoNombre;
  final String monedaSimbolo;

  const ReportesScreen({
    super.key,
    required this.proyectoId,
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
  bool incluyeAbonos = true;
  bool incluyeFlujoCaja = true;
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
      final reporteData = await ref.read(proyectoReporteProvider(widget.proyectoId).future);
      
      final sym = widget.monedaSimbolo;
      final fmt = DateFormat('dd/MM/yyyy', 'es');

      // Filter by date range if set
      final ventasFiltradas = reporteData.ventas.where((v) {
        if (_desde != null && v.fechaVenta.isBefore(_desde!)) return false;
        if (_hasta != null && v.fechaVenta.isAfter(_hasta!.add(const Duration(days: 1)))) return false;
        return true;
      }).toList();

      final gastosFiltrados = reporteData.gastos.where((g) {
        if (_desde != null && g.fechaGasto.isBefore(_desde!)) return false;
        if (_hasta != null && g.fechaGasto.isAfter(_hasta!.add(const Duration(days: 1)))) return false;
        return true;
      }).toList();

      final abonosFiltrados = reporteData.abonos.where((a) {
        if (_desde != null && a.fechaAbono.isBefore(_desde!)) return false;
        if (_hasta != null && a.fechaAbono.isAfter(_hasta!.add(const Duration(days: 1)))) return false;
        return true;
      }).toList();

      final excel = xl.Excel.createExcel();

      // ---- DASHBOARD RESUMEN SHEET ----
      final resumenSheet = excel['Dashboard General'];
      excel.setDefaultSheet('Dashboard General');
      if (excel.sheets.containsKey('Sheet1')) {
        excel.delete('Sheet1');
      }

      // Estilos profesionales
      final headerStyle = xl.CellStyle(
        bold: true,
        fontColorHex: xl.ExcelColor.fromHexString('#FFFFFF'),
        backgroundColorHex: xl.ExcelColor.fromHexString('#1A1A1A'),
        horizontalAlign: xl.HorizontalAlign.Center,
        verticalAlign: xl.VerticalAlign.Center,
      );
      
      final positiveStyle = xl.CellStyle(
        bold: true,
        fontColorHex: xl.ExcelColor.fromHexString('#FFFFFF'),
        backgroundColorHex: xl.ExcelColor.fromHexString('#2E7D32'),
        horizontalAlign: xl.HorizontalAlign.Center,
        verticalAlign: xl.VerticalAlign.Center,
      );
      
      final negativeStyle = xl.CellStyle(
        bold: true,
        fontColorHex: xl.ExcelColor.fromHexString('#FFFFFF'),
        backgroundColorHex: xl.ExcelColor.fromHexString('#C62828'),
        horizontalAlign: xl.HorizontalAlign.Center,
        verticalAlign: xl.VerticalAlign.Center,
      );

      final titleStyle = xl.CellStyle(
        bold: true,
        fontSize: 16,
        fontColorHex: xl.ExcelColor.fromHexString('#000000'),
      );

      void addRow(xl.Sheet sheet, List<String> data, {xl.CellStyle? style}) {
        final row = sheet.maxRows;
        for (var i = 0; i < data.length; i++) {
          final cell = sheet.cell(xl.CellIndex.indexByColumnRow(columnIndex: i, rowIndex: row));
          cell.value = xl.TextCellValue(data[i]);
          if (style != null) {
            cell.cellStyle = style;
          }
        }
      }

      final titleCell = resumenSheet.cell(xl.CellIndex.indexByString("A1"));
      titleCell.value = xl.TextCellValue('REPORTE GENERAL: ${widget.proyectoNombre}');
      titleCell.cellStyle = titleStyle;
      
      addRow(resumenSheet, ['Generado:', fmt.format(DateTime.now())]);
      if (_desde != null || _hasta != null) {
        addRow(resumenSheet, [
          'Período:',
          '${_desde != null ? fmt.format(_desde!) : "inicio"} - ${_hasta != null ? fmt.format(_hasta!) : "hoy"}'
        ]);
      }
      addRow(resumenSheet, []);

      if (incluyeGanancias) {
        addRow(resumenSheet, ['RESUMEN FINANCIERO'], style: headerStyle);
        addRow(resumenSheet, ['Inversión Total', '$sym ${reporteData.inversionTotal.toStringAsFixed(2)}']);
        addRow(resumenSheet, ['Ingresos Brutos', '$sym ${reporteData.ingresosBrutos.toStringAsFixed(2)}']);
        addRow(resumenSheet, ['Total Cobrado', '$sym ${reporteData.totalCobrado.toStringAsFixed(2)}']);
        addRow(resumenSheet, ['Total Gastos', '$sym ${reporteData.totalGastos.toStringAsFixed(2)}']);
        
        final gananciaCellLabel = resumenSheet.cell(xl.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: resumenSheet.maxRows));
        final gananciaCellValue = resumenSheet.cell(xl.CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: resumenSheet.maxRows - 1));
        gananciaCellLabel.value = xl.TextCellValue('GANANCIA NETA');
        gananciaCellValue.value = xl.TextCellValue('$sym ${reporteData.gananciaReal.toStringAsFixed(2)}');
        
        final gStyle = reporteData.gananciaReal >= 0 ? positiveStyle : negativeStyle;
        gananciaCellLabel.cellStyle = gStyle;
        gananciaCellValue.cellStyle = gStyle;
        addRow(resumenSheet, []);
      }

      if (incluyeStock) {
        addRow(resumenSheet, ['INVENTARIO GLOBAL'], style: headerStyle);
        addRow(resumenSheet, ['Kilos Totales', '${reporteData.kilosTotales.toStringAsFixed(1)} kg']);
        addRow(resumenSheet, ['Kilos Vendidos', '${reporteData.kilosVendidos.toStringAsFixed(1)} kg']);
        addRow(resumenSheet, ['Kilos Restantes', '${reporteData.kilosRestantes.toStringAsFixed(1)} kg']);
        addRow(resumenSheet, []);
      }

      // ---- DASHBOARD CLIENTES ----
      if (incluyeVentas && ventasFiltradas.isNotEmpty) {
        final clientesSheet = excel['Dash - Clientes'];
        addRow(clientesSheet, ['DASHBOARD POR CLIENTES'], style: headerStyle);
        addRow(clientesSheet, ['Cliente', 'Cuenta', 'Kilos Totales', 'Monto Total', 'Total Abonado', 'Saldo Pendiente'], style: headerStyle);
        
        final mapClientes = <String, Map<String, dynamic>>{};
        for (final v in ventasFiltradas) {
          final c = '${v.cliente} (${v.cuentaNombre})';
          if (!mapClientes.containsKey(c)) {
            mapClientes[c] = {'kilos': 0.0, 'monto': 0.0, 'abonado': 0.0, 'saldo': 0.0, 'cliente': v.cliente, 'cuenta': v.cuentaNombre};
          }
          mapClientes[c]!['kilos'] = (mapClientes[c]!['kilos'] as double) + v.kilosVendidos;
          mapClientes[c]!['monto'] = (mapClientes[c]!['monto'] as double) + v.totalVenta;
          mapClientes[c]!['abonado'] = (mapClientes[c]!['abonado'] as double) + v.totalAbonado;
          mapClientes[c]!['saldo'] = (mapClientes[c]!['saldo'] as double) + v.saldoPendiente;
        }

        final listClientes = mapClientes.entries.toList()..sort((a, b) => (b.value['monto'] as double).compareTo(a.value['monto'] as double));
        
        for (final entry in listClientes) {
          addRow(clientesSheet, [
            entry.value['cliente'] as String,
            entry.value['cuenta'] as String,
            '${(entry.value['kilos'] as double).toStringAsFixed(1)} kg',
            '$sym ${(entry.value['monto'] as double).toStringAsFixed(2)}',
            '$sym ${(entry.value['abonado'] as double).toStringAsFixed(2)}',
            '$sym ${(entry.value['saldo'] as double).toStringAsFixed(2)}',
          ]);
        }
      }

      // ---- VENTAS SHEET ----
      if (incluyeVentas && ventasFiltradas.isNotEmpty) {
        final ventasSheet = excel['Detalle Ventas'];
        addRow(ventasSheet, ['Fecha', 'Cuenta', 'Cliente', 'Kilos', 'Precio/Kg', 'Total', 'Abonado', 'Saldo', 'Estado'], style: headerStyle);
        for (final v in ventasFiltradas) {
          addRow(ventasSheet, [
            fmt.format(v.fechaVenta),
            v.cuentaNombre,
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
        addRow(ventasSheet, ['', '', '', '', 'TOTAL', '$sym ${totalVentas.toStringAsFixed(2)}'], style: headerStyle);
      }

      // ---- GASTOS SHEET ----
      if (incluyeGastos && gastosFiltrados.isNotEmpty) {
        final gastosSheet = excel['Gastos'];
        addRow(gastosSheet, ['Fecha', 'Cuenta', 'Descripción', 'Monto', 'Registrado por'], style: headerStyle);
        for (final g in gastosFiltrados) {
          addRow(gastosSheet, [
            fmt.format(g.fechaGasto),
            g.cuentaNombre,
            g.descripcion,
            '$sym ${g.monto.toStringAsFixed(2)}',
            g.registradoPorNombre,
          ]);
        }
        addRow(gastosSheet, []);
        final totalGastos = gastosFiltrados.fold(0.0, (s, g) => s + g.monto);
        addRow(gastosSheet, ['', '', 'TOTAL', '$sym ${totalGastos.toStringAsFixed(2)}'], style: headerStyle);
      }

      // ---- HISTORIAL DE ABONOS SHEET ----
      if (incluyeAbonos && abonosFiltrados.isNotEmpty) {
        final abonosSheet = excel['Historial de Pagos'];
        addRow(abonosSheet, ['Fecha', 'Cuenta', 'Cliente', 'Monto Abonado', 'Registrado por'], style: headerStyle);
        for (final a in abonosFiltrados) {
          addRow(abonosSheet, [
            fmt.format(a.fechaAbono),
            a.cuentaNombre,
            a.cliente ?? 'Desconocido',
            '$sym ${a.monto.toStringAsFixed(2)}',
            a.registradoPorNombre,
          ]);
        }
        addRow(abonosSheet, []);
        final totalAbonos = abonosFiltrados.fold(0.0, (s, a) => s + a.monto);
        addRow(abonosSheet, ['', '', 'TOTAL ABONADO', '$sym ${totalAbonos.toStringAsFixed(2)}'], style: headerStyle);
      }

      // ---- FLUJO DE CAJA DIARIO SHEET ----
      if (incluyeFlujoCaja && (abonosFiltrados.isNotEmpty || gastosFiltrados.isNotEmpty)) {
        final flujoSheet = excel['Flujo de Caja'];
        addRow(flujoSheet, ['FLUJO DE CAJA (INGRESOS Y EGRESOS)'], style: headerStyle);
        addRow(flujoSheet, ['Fecha', 'Tipo', 'Descripción', 'Cuenta', 'Ingreso (+)', 'Egreso (-)', 'Saldo del Día'], style: headerStyle);

        final mapFlujo = <String, Map<String, dynamic>>{};
        
        for (final a in abonosFiltrados) {
          final f = a.fechaAbono.toIso8601String().substring(0, 10);
          if (!mapFlujo.containsKey(f)) {
            mapFlujo[f] = {'fecha': a.fechaAbono, 'ingresos': 0.0, 'egresos': 0.0, 'detalles': []};
          }
          mapFlujo[f]!['ingresos'] = (mapFlujo[f]!['ingresos'] as double) + a.monto;
          (mapFlujo[f]!['detalles'] as List).add('Pago: ${a.cliente} [${a.cuentaNombre}] ($sym${a.monto})');
        }

        for (final g in gastosFiltrados) {
          final f = g.fechaGasto.toIso8601String().substring(0, 10);
          if (!mapFlujo.containsKey(f)) {
            mapFlujo[f] = {'fecha': g.fechaGasto, 'ingresos': 0.0, 'egresos': 0.0, 'detalles': []};
          }
          mapFlujo[f]!['egresos'] = (mapFlujo[f]!['egresos'] as double) + g.monto;
          (mapFlujo[f]!['detalles'] as List).add('Gasto: ${g.descripcion} [${g.cuentaNombre}] ($sym${g.monto})');
        }

        final listFlujo = mapFlujo.entries.toList()..sort((a, b) => (a.value['fecha'] as DateTime).compareTo(b.value['fecha'] as DateTime));
        
        double saldoAcumulado = 0.0;
        for (final entry in listFlujo) {
          final ingresos = entry.value['ingresos'] as double;
          final egresos = entry.value['egresos'] as double;
          saldoAcumulado += (ingresos - egresos);
          
          final detallesStr = (entry.value['detalles'] as List).join(' | ');
          
          addRow(flujoSheet, [
            fmt.format(entry.value['fecha'] as DateTime),
            (ingresos > 0 && egresos > 0) ? 'Mixto' : (ingresos > 0 ? 'Ingreso' : 'Egreso'),
            detallesStr,
            'Varias',
            ingresos > 0 ? '$sym ${ingresos.toStringAsFixed(2)}' : '',
            egresos > 0 ? '$sym ${egresos.toStringAsFixed(2)}' : '',
            '$sym ${saldoAcumulado.toStringAsFixed(2)}',
          ]);
        }
      }

      // Save and share
      final bytes = excel.save()!;
      final dir = await getTemporaryDirectory();
      final fileName = 'Reporte_${widget.proyectoNombre.replaceAll(' ', '_')}_${DateFormat('dd-MM-yyyy').format(DateTime.now())}.xlsx';
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(bytes);

      await Share.shareXFiles([XFile(file.path)], text: 'Reporte de Proyecto: ${widget.proyectoNombre}');
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al exportar: $e')));
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd MMM yyyy', 'es');

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, size: 16), onPressed: () => Navigator.pop(context)),
        title: const Text('Reporte General'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        children: [
          Text(widget.proyectoNombre, style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
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
                _toggleRow('Ventas (Dashboards y Detalles)', incluyeVentas, (v) => setState(() => incluyeVentas = v)),
                const Divider(color: AppColors.border, height: 1),
                _toggleRow('Historial de Pagos / Abonos', incluyeAbonos, (v) => setState(() => incluyeAbonos = v)),
                const Divider(color: AppColors.border, height: 1),
                _toggleRow('Gastos Operativos', incluyeGastos, (v) => setState(() => incluyeGastos = v)),
                const Divider(color: AppColors.border, height: 1),
                _toggleRow('Flujo de Caja (Ingresos y Egresos)', incluyeFlujoCaja, (v) => setState(() => incluyeFlujoCaja = v)),
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
              label: Text(_exporting ? 'Generando...' : 'Exportar Excel Consolidado', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
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
