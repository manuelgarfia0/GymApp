class Validators {
  // Validación de email
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }

    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email';
    }

    return null;
  }

  // Validación de contraseña
  // CORRECCIÓN: mínimo 8 caracteres para coincidir con el backend
  // (UserRegistrationDTO tiene @Size(min = 8)).
  // El valor anterior de 6 causaba que formularios Flutter aceptaran
  // contraseñas que el backend rechazaría con 400 Bad Request.
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }

    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }

    return null;
  }

  // Validación de nombre de usuario
  static String? validateUsername(String? value) {
    if (value == null || value.isEmpty) {
      return 'Username is required';
    }

    if (value.length < 3) {
      return 'Username must be at least 3 characters';
    }

    final usernameRegex = RegExp(r'^[a-zA-Z0-9_]+$');
    if (!usernameRegex.hasMatch(value)) {
      return 'Username can only contain letters, numbers, and underscores';
    }

    return null;
  }

  // Validación de peso (para seguimiento de entrenamientos)
  static String? validateWeight(String? value) {
    if (value == null || value.isEmpty) {
      return 'Weight is required';
    }

    final weight = double.tryParse(value);
    if (weight == null) {
      return 'Please enter a valid number';
    }

    if (weight <= 0) {
      return 'Weight must be greater than 0';
    }

    if (weight > 1000) {
      return 'Weight seems too high';
    }

    return null;
  }

  // Validación de repeticiones (para seguimiento de entrenamientos)
  static String? validateReps(String? value) {
    if (value == null || value.isEmpty) {
      return 'Reps is required';
    }

    final reps = int.tryParse(value);
    if (reps == null) {
      return 'Please enter a valid number';
    }

    if (reps <= 0) {
      return 'Reps must be greater than 0';
    }

    if (reps > 1000) {
      return 'Reps seems too high';
    }

    return null;
  }

  // Validación de campo requerido
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }
}