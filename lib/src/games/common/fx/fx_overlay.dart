// src/games/common/fx/fx_overlay.dart
// Overlay que escucha al FxController y dibuja vuelos de cartas sobre un Stack.

import 'package:flutter/material.dart';
import 'fx_controller.dart';

class FxOverlay extends StatefulWidget {
  final FxController controller;
  const FxOverlay({super.key, required this.controller});

  @override
  State<FxOverlay> createState() => _FxOverlayState();
}

class _FxOverlayState extends State<FxOverlay> with TickerProviderStateMixin {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChange);
  }

  @override
  void didUpdateWidget(FxOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onChange);
      widget.controller.addListener(_onChange);
    }
  }

  void _onChange() => setState((){});

  @override
  void dispose() {
    widget.controller.removeListener(_onChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final flights = widget.controller.flights;
    return IgnorePointer(
      child: Stack(
        children: [
          for (final f in flights) _FlightAnim(key: ValueKey(f), flight: f),
        ],
      ),
    );
  }
}

class _FlightAnim extends StatefulWidget {
  final CardFlight flight;
  const _FlightAnim({super.key, required this.flight});

  @override
  State<_FlightAnim> createState() => _FlightAnimState();
}

class _FlightAnimState extends State<_FlightAnim> with SingleTickerProviderStateMixin {
  late final AnimationController _ac;
  late final Animation<double> _t;

  @override
  void initState() {
    super.initState();
    _ac = AnimationController(vsync: this, duration: widget.flight.duration)..forward();
    _t = CurvedAnimation(parent: _ac, curve: widget.flight.curve);
  }

  @override
  void dispose() {
    _ac.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final f = widget.flight;
    return AnimatedBuilder(
      animation: _t,
      builder: (_, __) {
        final x = lerpDouble(f.from.dx, f.to.dx, _t.value)!;
        final y = lerpDouble(f.from.dy, f.to.dy, _t.value)!;
        final s = 1.0 + 0.08 * (1 - (_t.value - 0.5).abs() * 2); // ligero "pop" en el centro
        return Positioned(
          left: x - f.size.width / 2,
          top: y - f.size.height / 2,
          child: Transform.scale(
            scale: s,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                f.imageUrl,
                width: f.size.width,
                height: f.size.height,
                fit: BoxFit.cover,
              ),
            ),
          ),
        );
      },
    );
  }
}

double? lerpDouble(num a, num b, double t) => a + (b - a) * t;
