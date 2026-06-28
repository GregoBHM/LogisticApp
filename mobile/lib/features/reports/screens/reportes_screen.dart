import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/models/models.dart';

class ReportesScreen extends StatefulWidget {
  final CuentaResumenModel cuenta;
  final String proyectoNombre;
  
  const ReportesScreen({
    super.key, 
    required this.cuenta, 
    required this.proyectoNombre,
  });

  @override
  State<ReportesScreen> createState() => _ReportesScreenState();
}

class _ReportesScreenState extends State<ReportesScreen> {
  bool incluyeVentas = true;
  bool incluyeGastos = true;
  bool incluyeGanancias = true;
  bool incluyeStock = true;
  bool incluyeEquipo = false;

  void _exportar(String tipo) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Exportando $tipo... (En desarrollo)')));
  }

  @override
  Widget build(BuildContext context) {
    final ganancia = widget.cuenta.gananciaReal;

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
              Expanded(child: _metricTile('Ingresos', '\$${widget.cuenta.totalCobrado.toStringAsFixed(0)}', AppColors.textPrimary)),
              const SizedBox(width: 8),
              Expanded(child: _metricTile('Inversión', '\$${widget.cuenta.inversionTotal.toStringAsFixed(0)}', AppColors.negative)),
              const SizedBox(width: 8),
              Expanded(child: _metricTile('Neto', '${ganancia >= 0 ? '+' : ''}\$${ganancia.toStringAsFixed(0)}', ganancia >= 0 ? AppColors.positive : AppColors.negative)),
            ],
          ),
          const SizedBox(height: 24),
          const Text('Incluir en reporte', style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w500, letterSpacing: 0.5)),
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
                _toggleRow('Ganancias', incluyeGanancias, (v) => setState(() => incluyeGanancias = v)),
                const Divider(color: AppColors.border, height: 1),
                _toggleRow('Stock', incluyeStock, (v) => setState(() => incluyeStock = v)),
                const Divider(color: AppColors.border, height: 1),
                _toggleRow('Equipo', incluyeEquipo, (v) => setState(() => incluyeEquipo = v)),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _exportar('Excel'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.cream,
                foregroundColor: AppColors.background,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Exportar Excel', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => _exportar('PDF'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
                side: const BorderSide(color: AppColors.border),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Exportar PDF', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
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
            activeColor: AppColors.cream,
            activeTrackColor: AppColors.cream.withValues(alpha: 0.3),
            inactiveThumbColor: AppColors.textMuted,
            inactiveTrackColor: AppColors.surface,
          ),
        ],
      ),
    );
  }
}
