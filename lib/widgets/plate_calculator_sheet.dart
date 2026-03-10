import 'package:flutter/material.dart';

class PlateCalculatorSheet extends StatefulWidget {
  final double initialWeight;

  const PlateCalculatorSheet({super.key, required this.initialWeight});

  @override
  State<PlateCalculatorSheet> createState() => _PlateCalculatorSheetState();
}

class _PlateCalculatorSheetState extends State<PlateCalculatorSheet> {
  // Discos estándar disponibles en la mayoría de gimnasios (en kg)
  final List<double> availablePlates = [25.0, 20.0, 15.0, 10.0, 5.0, 2.5, 1.25];
  
  // Peso por defecto de la barra olímpica (en kg)
  double barWeight = 20.0;
  
  // Lista que almacenará cuántos discos de cada tipo van *por lado*
  List<double> platesPerSide = [];
  
  late double currentWeight;

  @override
  void initState() {
    super.initState();
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

  // Permite sumar/restar 2.5kg (un disco pequeño por lado) al total
  void _adjustWeight(double amount) {
    setState(() {
      currentWeight += amount;
      if (currentWeight < barWeight) currentWeight = barWeight;
      _calculatePlates();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: const BoxDecoration(
        color: Color(0xFF1E1E1E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 24),
          const Text('Plate Calculator', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 24),

          // Controles de peso
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(icon: const Icon(Icons.remove_circle_outline, size: 32, color: Colors.grey), onPressed: () => _adjustWeight(-2.5)),
              const SizedBox(width: 16),
              Text('${currentWeight.toStringAsFixed(1)} kg', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
              const SizedBox(width: 16),
              IconButton(icon: const Icon(Icons.add_circle_outline, size: 32, color: Colors.grey), onPressed: () => _adjustWeight(2.5)),
            ],
          ),
          
          Text('Includes ${barWeight}kg bar', style: const TextStyle(color: Colors.grey, fontSize: 14)),
          const SizedBox(height: 32),

          // Visualización de discos (Texto)
          const Text('Plates PER SIDE:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 16),
          
          if (platesPerSide.isEmpty)
            const Text('Just the empty bar!', style: TextStyle(color: Colors.grey, fontSize: 16, fontStyle: FontStyle.italic))
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: platesPerSide.map((plate) {
                // Color distinto según el tamaño del disco (estilo olímpico)
                Color plateColor = Colors.grey[800]!;
                if (plate == 25) plateColor = Colors.red[800]!;
                if (plate == 20) plateColor = Colors.blue[800]!;
                if (plate == 15) plateColor = Colors.amber[800]!;
                if (plate == 10) plateColor = Colors.green[800]!;

                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: plateColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[700]!),
                  ),
                  child: Text(
                    '${plate.toStringAsFixed(plate % 1 == 0 ? 0 : 2)}', // 20 en vez de 20.0, pero 2.5 sí muestra decimales
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
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
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
              onPressed: () => Navigator.pop(context, currentWeight),
              child: const Text('Apply Weight', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          )
        ],
      ),
    );
  }
}