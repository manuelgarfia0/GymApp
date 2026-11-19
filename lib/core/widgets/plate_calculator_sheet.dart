import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../utils/weight_converter.dart';

class PlateCalculatorSheet extends StatefulWidget {
  final double initialWeight;
  final WeightUnit unit;

  const PlateCalculatorSheet({
    super.key,
    required this.initialWeight,
    this.unit = WeightUnit.kg,
  });

  @override
  State<PlateCalculatorSheet> createState() => _PlateCalculatorSheetState();
}

class _PlateCalculatorSheetState extends State<PlateCalculatorSheet> {
  // Discos estándar disponibles según unidad
  List<double> get availablePlates => widget.unit == WeightUnit.lb
      ? const [45.0, 35.0, 25.0, 10.0, 5.0, 2.5]
      : const [25.0, 20.0, 15.0, 10.0, 5.0, 2.5, 1.25];

  // Peso por defecto de la barra olímpica (20 kg o 45 lb)
  late final double barWeight;

  // Lista que almacenará cuántos discos de cada tipo van *por lado*
  List<double> platesPerSide = [];

  late double currentWeight;

  @override
  void initState() {
    super.initState();
    barWeight = widget.unit == WeightUnit.lb ? 45.0 : 20.0;
    currentWeight = widget.initialWeight > 0 ? widget.initialWeight : barWeight;
    _calculatePlates();
  }

  void _calculatePlates() {
    platesPerSide.clear();

    // Si el peso pedido es menor que la barra, no hay discos.
    if (currentWeight <= barWeight) return;

    // Calculamos el peso total a repartir (sin la barra)
    double targetWeightPlates = currentWeight - barWeight;

    // Lo que hay que poner en un solo lado de la barra
    double weightPerSide = targetWeightPlates / 2.0;

    for (double plate in availablePlates) {
      while (weightPerSide >= plate) {
        platesPerSide.add(plate);
        weightPerSide -= plate;

        // Redondeo preventivo para problemas de precisión de punto flotante
        weightPerSide = double.parse(weightPerSide.toStringAsFixed(2));
      }
    }
  }

  double get _stepAmount => widget.unit == WeightUnit.lb ? 5.0 : 2.5;

  // Permite sumar/restar un par de discos mínimos al total
  void _adjustWeight(double amount) {
    setState(() {
      currentWeight += amount;
      if (currentWeight < barWeight) currentWeight = barWeight;
      _calculatePlates();
    });
  }

  @override
  Widget build(BuildContext context) {
    final unitLabel = widget.unit.label;
    final textPrimary = AppTheme.textPrimary(context);
    final textSecondary = AppTheme.textSecondary(context);

    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: AppTheme.cardBg(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: textSecondary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Plate Calculator',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 24),

          // Controles de peso
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(
                  Icons.remove_circle_outline,
                  size: 32,
                  color: Colors.grey,
                ),
                onPressed: () => _adjustWeight(-_stepAmount),
              ),
              const SizedBox(width: 16),
              Text(
                '${currentWeight.toStringAsFixed(1)} $unitLabel',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(width: 16),
              IconButton(
                icon: const Icon(
                  Icons.add_circle_outline,
                  size: 32,
                  color: Colors.grey,
                ),
                onPressed: () => _adjustWeight(_stepAmount),
              ),
            ],
          ),

          Text(
            'Includes $barWeight$unitLabel bar',
            style: TextStyle(
              color: textSecondary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 32),

          // Visualización de discos (Texto)
          Text(
            'Plates PER SIDE:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 16),

          if (platesPerSide.isEmpty)
            Text(
              'Just the empty bar!',
              style: TextStyle(
                color: textSecondary,
                fontSize: 16,
                fontStyle: FontStyle.italic,
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: platesPerSide.map((plate) {
                // Color distinto según el tamaño del disco (estilo olímpico)
                Color plateColor = AppTheme.plateDefault;
                if (plate == 25 || plate == 45) plateColor = AppTheme.plateRed;
                if (plate == 20 || plate == 35) plateColor = AppTheme.plateBlue;
                if (plate == 15) plateColor = AppTheme.plateYellow;
                if (plate == 10) plateColor = AppTheme.plateGreen;

                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: plateColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: textSecondary),
                  ),
                  child: Text(
                    plate.toStringAsFixed(
                      plate % 1 == 0 ? 0 : 2,
                    ), // 20 en vez de 20.0, pero 2.5 sí muestra decimales
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryTextColor,
                    ),
                  ),
                );
              }).toList(),
            ),

          const SizedBox(height: 32),

          // Botón para aplicar el peso al input de la serie
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
              ),
              onPressed: () => Navigator.pop(context, currentWeight),
              child: const Text(
                'Apply Weight',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryTextColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
