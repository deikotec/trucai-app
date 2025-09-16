// src/games/common/fx/fx_controller.dart
// Controlador de efectos visuales transitorios para la mesa (vuelos de cartas, bursts).
// Se usa con un FxOverlay que dibuja sobre la zona central del juego.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class CardFlight {
  final String imageUrl;      // Imagen de la carta a volar
  final Offset from;          // Punto inicial (en coords locales del Stack central)
  final Offset to;            // Punto final (en coords locales del Stack central)
  final Size size;            // Tamaño de la carta
  final Duration duration;    // Duración del vuelo
  final Curve curve;          // Curva de animación

  CardFlight({
    required this.imageUrl,
    required this.from,
    required this.to,
    required this.size,
    this.duration = const Duration(milliseconds: 380),
    this.curve = Curves.easeOutCubic,
  });
}

class FxController extends ChangeNotifier {
  final List<CardFlight> _flights = [];
  List<CardFlight> get flights => List.unmodifiable(_flights);

  void flyCard(CardFlight f) {
    _flights.add(f);
    notifyListeners();
    // Remover tras finalizar
    Future.delayed(f.duration + const Duration(milliseconds: 40), () {
      _flights.remove(f);
      notifyListeners();
    });
  }
}
