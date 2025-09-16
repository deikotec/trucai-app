// src/games/caida/providers/caida_provider.dart
// Provider con estado + últimos efectos/jugada para disparar FX desde la pantalla.

import 'package:flutter/foundation.dart';
import '../controllers/caida_logic.dart';
import '../models/caida_card.dart';

class CaidaProvider extends ChangeNotifier {
  final logic = CaidaLogic();
  final List<String> logs = [];

  Map<String, dynamic>? lastEffects;
  CaidaCard? lastPlayedCard;
  String? lastWho; // 'player' o 'opponent'

  void log(String t) {
    logs.insert(0, t);
    notifyListeners();
  }

  void newGame({bool fullReset = true}) {
    logs.clear();
    lastEffects = null;
    lastPlayedCard = null;
    lastWho = null;
    logic.resetAndStart(fullReset: fullReset);
    notifyListeners();
  }

  Future<void> initialChoice(String? choice) async {
    final pts = logic.processTableOrderChoice(choice ?? 'asc');
    log('Orden ${choice ?? 'asc'}: +$pts pts');
  }

  void playerTapCard(CaidaCard c) {
    final res = logic.playerPlayCard(c.id);
    lastWho = 'player';
    lastPlayedCard = res['card'] as CaidaCard?;
    lastEffects = (res['effects'] as Map<String, dynamic>?) ?? {};
    log('Jugaste ${c.displayRank} de ${c.suit}.');
    if (lastEffects?['caida'] != null) {
      log('¡Caída! +${lastEffects!['caida']} pts.');
    }
    if (lastEffects?['mesaLimpia'] != null) {
      log('¡Mesa limpia! +${lastEffects!['mesaLimpia']} pts.');
    }
    if ((lastEffects?['capturedCount'] ?? 0) > 2) {
      log(
        '...y te llevas ${(lastEffects?['capturedCount'] ?? 0) - 2} en escalera.',
      );
    }
    notifyListeners();
  }

  void opponentAutoPlay() {
    final res = logic.opponentTurn();
    lastWho = 'opponent';
    lastPlayedCard = res['card'] as CaidaCard?;
    lastEffects = (res['effects'] as Map<String, dynamic>?) ?? {};
    final card = lastPlayedCard;
    if (card != null) log('Oponente jugó ${card.displayRank} de ${card.suit}.');
    if (lastEffects?['caida'] != null) {
      log('Bot hace caída: +${lastEffects!['caida']} pts.');
    }
    if (lastEffects?['mesaLimpia'] != null) {
      log('Bot mesa limpia: +${lastEffects!['mesaLimpia']} pts.');
    }
    if ((lastEffects?['capturedCount'] ?? 0) > 2) {
      log(
        'Bot se lleva ${(lastEffects?['capturedCount'] ?? 0) - 2} en escalera.',
      );
    }
    notifyListeners();
  }
}
