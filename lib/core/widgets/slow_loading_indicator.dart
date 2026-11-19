import 'dart:async';
import 'package:flutter/material.dart';

/// Indicador de carga que informa al usuario si el servidor está arrancando
/// tras un periodo de inactividad cuando la petición supera [delay].
class SlowLoadingIndicator extends StatefulWidget {
  final Duration delay;
  final String title;
  final String subtitle;

  const SlowLoadingIndicator({
    super.key,
    this.delay = const Duration(seconds: 5),
    this.title = 'Despertando el servidor…',
    this.subtitle =
        'Puede tardar hasta 1 minuto tras un periodo de inactividad',
  });

  @override
  State<SlowLoadingIndicator> createState() => _SlowLoadingIndicatorState();
}

class _SlowLoadingIndicatorState extends State<SlowLoadingIndicator> {
  Timer? _timer;
  bool _showSlowMessage = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer(widget.delay, () {
      if (mounted) {
        setState(() => _showSlowMessage = true);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: Colors.blueAccent),
            if (_showSlowMessage) ...[
              const SizedBox(height: 18),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 280),
                builder: (context, opacity, child) =>
                    Opacity(opacity: opacity, child: child),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.subtitle,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
