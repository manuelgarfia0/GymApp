/// Unidad de peso preferida por el usuario en la interfaz.
///
/// La base de datos y las entidades de dominio almacenan siempre kilogramos (kg)
/// como fuente canónica; la conversión a libras (lb) se aplica exclusivamente en
/// presentación y parsing de entrada.
enum WeightUnit {
  kg,
  lb;

  String get code => this == WeightUnit.lb ? 'lb' : 'kg';
  String get label => code;
  String get headerLabel => this == WeightUnit.lb ? 'LB' : 'KG';

  static WeightUnit fromCode(String? code) {
    final normalized = (code ?? '').trim().toLowerCase();
    if (normalized == 'lb' || normalized == 'lbs') {
      return WeightUnit.lb;
    }
    return WeightUnit.kg;
  }
}

/// Conversor y formateador consistente entre kilogramos (kg) y libras (lb).
class WeightConverter {
  static const double lbPerKg = 2.20462262185;

  /// Convierte un valor canónico en kg a la unidad de visualización elegida.
  static double fromKg(double kg, WeightUnit unit) {
    if (unit == WeightUnit.kg) return kg;
    return kg * lbPerKg;
  }

  /// Convierte un valor introducido en [unit] a kilogramos canónicos.
  static double toKg(double displayValue, WeightUnit unit) {
    if (unit == WeightUnit.kg) return displayValue;
    return displayValue / lbPerKg;
  }

  /// Formatea un número ya expresado en la unidad de destino eliminando `.0`.
  static String formatNumber(double value) {
    final rounded = double.parse(value.toStringAsFixed(1));
    if (rounded == rounded.truncateToDouble()) {
      return rounded.toInt().toString();
    }
    return rounded.toStringAsFixed(1);
  }

  /// Formatea un peso almacenado en kg para mostrarlo en [unit].
  static String formatWeight(
    double kg,
    WeightUnit unit, {
    bool includeUnit = true,
  }) {
    final formatted = formatNumber(fromKg(kg, unit));
    return includeUnit ? '$formatted ${unit.label}' : formatted;
  }

  /// Formatea un peso en kg para inicializar campos de texto editables en [unit].
  static String formatInputFromKg(double kg, WeightUnit unit) {
    return formatNumber(fromKg(kg, unit));
  }

  /// Parsea texto introducido por el usuario en [unit] y devuelve su equivalente en kg.
  static double? parseInputToKg(String raw, WeightUnit unit) {
    final normalized = raw.trim().replaceAll(',', '.');
    if (normalized.isEmpty) return null;
    final parsed = double.tryParse(normalized);
    if (parsed == null) return null;
    return toKg(parsed, unit);
  }

  /// Formatea un volumen total almacenado en kg (sin abreviar miles).
  static String formatVolume(double kgVolume, WeightUnit unit) {
    return '${fromKg(kgVolume, unit).toStringAsFixed(0)} ${unit.label}';
  }

  /// Formatea un volumen compacto para tarjetas de resumen en el perfil.
  static String formatCompactVolume(double kgVolume, WeightUnit unit) {
    final converted = fromKg(kgVolume, unit);
    if (converted >= 1000) {
      return '${(converted / 1000).toStringAsFixed(1)}k ${unit.label}';
    }
    return '${converted.toStringAsFixed(0)} ${unit.label}';
  }
}
