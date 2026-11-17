import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Acciones interactivas disparadas desde la notificación del temporizador de descanso.
enum RestTimerNotificationAction {
  subtract20('sub20'),
  add20('add20'),
  stop('stop'),
  completed('completed');

  final String wireValue;
  const RestTimerNotificationAction(this.wireValue);

  static RestTimerNotificationAction? fromWireValue(String? value) {
    for (final action in values) {
      if (action.wireValue == value) return action;
    }
    return null;
  }
}

/// Puente limpio hacia el canal nativo de Android para mostrar, actualizar y
/// controlar la notificación en vivo del temporizador de descanso, además de
/// emitir las alertas sonoras sutiles y hápticas al finalizar o ajustar el tiempo.
class RestTimerNotificationService {
  static const String channelName = 'com.example.gym_app/rest_timer';

  final MethodChannel _channel;
  ValueChanged<RestTimerNotificationAction>? _onAction;
  bool _handlerRegistered = false;

  RestTimerNotificationService({MethodChannel? channel})
      : _channel = channel ?? const MethodChannel(channelName);

  bool get _isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// Registra el callback que recibe pulsaciones de botones desde la notificación
  /// (`-20s`, `+20s`, `Terminar`) o el evento de finalización automática en segundo plano.
  void setActionHandler(ValueChanged<RestTimerNotificationAction>? handler) {
    _onAction = handler;
    if (handler == null) {
      if (_handlerRegistered) {
        _channel.setMethodCallHandler(null);
        _handlerRegistered = false;
      }
      return;
    }

    if (!_handlerRegistered) {
      _channel.setMethodCallHandler(_handleNativeCall);
      _handlerRegistered = true;
    }
  }

  Future<void> _handleNativeCall(MethodCall call) async {
    if (call.method != 'onNotificationAction') return;
    final args = call.arguments;
    final rawAction = args is Map ? args['action'] as String? : null;
    final parsed = RestTimerNotificationAction.fromWireValue(rawAction);
    if (parsed != null) {
      _onAction?.call(parsed);
    }
  }

  /// Solicita el permiso de notificaciones en Android 13+ cuando procede.
  Future<bool> requestPermission() async {
    if (!_isAndroid) return false;
    return await _invokeSafe<bool>('requestPermission') ?? false;
  }

  /// Publica o actualiza la notificación persistente del temporizador con cuenta
  /// atrás en vivo y botones interactivos (`-20s`, `+20s`, `Terminar`).
  Future<void> showOrUpdate({
    required int remainingSeconds,
    required int totalSeconds,
    required bool isPaused,
    required bool soundEnabled,
    required bool vibrationEnabled,
    String? exerciseName,
  }) async {
    if (!_isAndroid) return;
    await _invokeSafe<void>('showOrUpdateTimer', {
      'remainingSeconds': remainingSeconds,
      'totalSeconds': totalSeconds,
      'isPaused': isPaused,
      'soundEnabled': soundEnabled,
      'vibrationEnabled': vibrationEnabled,
      'exerciseName': exerciseName,
    });
  }

  /// Oculta la notificación del temporizador activo y detiene el ticker nativo.
  Future<void> cancel() async {
    if (!_isAndroid) return;
    await _invokeSafe<void>('cancelTimer');
  }

  /// Ejecuta el aviso de fin de descanso: vibración perceptible y/o tono sutil
  /// no intrusivo que no interrumpe la música en segundo plano.
  Future<void> playCompletionFeedback({
    required bool playSound,
    required bool vibrate,
  }) async {
    if (_isAndroid) {
      await _invokeSafe<void>('playCompletionFeedback', {
        'playSound': playSound,
        'vibrate': vibrate,
      });
      return;
    }

    if (vibrate) {
      await _safeHaptic(HapticFeedback.heavyImpact);
    }
  }

  /// Feedback háptico breve al pulsar controles del temporizador (`+20s`, `-20s`, pausa).
  Future<void> lightImpact() async {
    await _safeHaptic(HapticFeedback.lightImpact);
    if (_isAndroid) {
      await _invokeSafe<void>('vibrateLight');
    }
  }

  Future<T?> _invokeSafe<T>(String method, [dynamic arguments]) async {
    try {
      return await _channel.invokeMethod<T>(method, arguments);
    } on MissingPluginException {
      return null;
    } on PlatformException catch (e) {
      debugPrint('RestTimerNotificationService($method) error: ${e.message}');
      return null;
    }
  }

  Future<void> _safeHaptic(Future<void> Function() feedbackFn) async {
    try {
      await feedbackFn();
    } on MissingPluginException {
      // Ignorado en entornos sin canal de plataforma (tests unitarios / desktop).
    } catch (_) {
      // Ignorado en dispositivos sin motor háptico.
    }
  }
}
