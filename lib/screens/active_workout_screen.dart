import 'package:flutter/material.dart';
import 'package:gym_app/models/workout.dart'; // El modelo para la API
import 'package:gym_app/services/workout_service.dart'; // El servicio de Spring Boot

// 1. Le cambiamos el nombre a ActiveSet para que no choque con el WorkoutSet de la API
class ActiveSet {
  double? weight;
  int? reps;
  
  ActiveSet({this.weight, this.reps});
}

class ActiveWorkoutScreen extends StatefulWidget {
  const ActiveWorkoutScreen({super.key});

  @override
  State<ActiveWorkoutScreen> createState() => _ActiveWorkoutScreenState();
}

class _ActiveWorkoutScreenState extends State<ActiveWorkoutScreen> {
  // Ahora usamos ActiveSet para la lista de la pantalla
  final List<ActiveSet> _sets = [ActiveSet()];
  
  // Servicios y estado de carga
  final WorkoutService _workoutService = WorkoutService();
  bool _isSaving = false;

  void _addSet() {
    setState(() {
      _sets.add(ActiveSet());
    });
  }

    Future<void> _finishWorkout() async {
    final validSets = _sets.where((s) => s.weight != null && s.reps != null).toList();
    
    if (validSets.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Añade al menos una serie válida.'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() { _isSaving = true; });

    // 1. Preparamos la lista de series con el formato exacto del backend
    final List<WorkoutSetDTO> setsToSend = [];
    for (int i = 0; i < validSets.length; i++) {
      setsToSend.add(WorkoutSetDTO(
        exerciseId: 1, // Press de banca (ejemplo fijo por ahora)
        exerciseOrder: 1, // Primer ejercicio de la rutina
        setNumber: i + 1, // Serie 1, 2, 3...
        weight: validSets[i].weight!,
        reps: validSets[i].reps!,
      ));
    }

    // 2. Preparamos el Entrenamiento principal
    final request = WorkoutDTO(
      name: 'Entrenamiento de Pecho',
      startTime: DateTime.now().toIso8601String(), // Formato de fecha que entiende Java
      userId: 1, // TODO: Cogeremos esto del usuario logueado más adelante. Asumimos ID 1.
      sets: setsToSend,
    );

    // 3. Enviamos a Spring Boot
    final success = await _workoutService.saveWorkout(request);

    setState(() { _isSaving = false; });

    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('¡Entrenamiento guardado en la Base de Datos!'), backgroundColor: Colors.green),
        );
        Navigator.pop(context); // Volvemos a la Home
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al guardar el entrenamiento.'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Entrenamiento Activo'),
        backgroundColor: Colors.blueAccent,
        actions: [
          // Si está guardando, mostramos una ruedita, si no, el botón FINALIZAR
          _isSaving 
            ? const Padding(
                padding: EdgeInsets.all(16.0),
                child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
              )
            : TextButton(
                onPressed: _finishWorkout,
                child: const Text('FINALIZAR', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Press de Banca (Barra)',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blueAccent),
            ),
            const SizedBox(height: 16),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Text('SET', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                Text('KG', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                Text('REPS', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
              ],
            ),
            const Divider(),
            Expanded(
              child: ListView.builder(
                itemCount: _sets.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: Colors.grey[800], borderRadius: BorderRadius.circular(8)),
                          child: Text('${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        SizedBox(
                          width: 80,
                          child: TextField(
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            decoration: const InputDecoration(filled: true, fillColor: Color(0xFF2C2C2C), border: OutlineInputBorder(borderSide: BorderSide.none), hintText: '0'),
                            onChanged: (value) => _sets[index].weight = double.tryParse(value),
                          ),
                        ),
                        SizedBox(
                          width: 80,
                          child: TextField(
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            decoration: const InputDecoration(filled: true, fillColor: Color(0xFF2C2C2C), border: OutlineInputBorder(borderSide: BorderSide.none), hintText: '0'),
                            onChanged: (value) => _sets[index].reps = int.tryParse(value),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _addSet,
                icon: const Icon(Icons.add),
                label: const Text('Añadir Serie'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[800], foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16)),
              ),
            )
          ],
        ),
      ),
    );
  }
}