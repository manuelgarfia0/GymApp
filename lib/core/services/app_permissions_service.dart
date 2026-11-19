import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Servicio centralizado que solicita y recuerda los permisos en tiempo de
/// ejecución necesarios al iniciar sesión o registrarse (p. ej. notificaciones).
class AppPermissionsService {
  static const String defaultChannelName = 'com.example.gym_app/rest_timer';

  final MethodChannel _channel;
  bool _requestedInSession = false;
  bool _notificationsGranted = false;

  AppPermissionsService({MethodChannel? channel})
      : _channel = channel ?? const MethodChannel(defaultChannelName);

  bool get _isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  bool get hasRequestedInSession => _requestedInSession;
  bool get notificationsGranted => _notificationsGranted;

  /// Solicita una vez por sesión los permisos necesarios de la app.
  ///
  /// En Android 13+ solicita `POST_NOTIFICATIONS`; en versiones anteriores o si
  /// ya estaban concedidos, el canal nativo responde `true` sin diálogo.
  Future<bool> requestRequiredPermissions({bool force = false}) async {
    if (!force && _requestedInSession) {
      return _notificationsGranted;
    }

    _requestedInSession = true;
    if (!_isAndroid) {
      _notificationsGranted = true;
      return true;
    }

    try {
      final granted = await _channel.invokeMethod<bool>('requestPermission');
      _notificationsGranted = granted ?? false;
      return _notificationsGranted;
    } on MissingPluginException {
      return false;
    } on PlatformException catch (e) {
      debugPrint('AppPermissionsService(requestPermission) error: ${e.message}');
      return false;
    }
  }

  /// Permite volver a solicitar los permisos tras un nuevo login o registro.
  void resetSession() {
    _requestedInSession = false;
  }
}
