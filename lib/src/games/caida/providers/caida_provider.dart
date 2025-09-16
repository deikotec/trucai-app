// src/games/caida/providers/caida_provider.dart
import 'package:flutter/foundation.dart';
import '../controllers/caida_logic.dart';
import '../models/caida_card.dart';

class CaidaProvider extends ChangeNotifier {
  final logic = CaidaLogic();
  final List<String> logs = [];

  void log(String t) { logs.insert(0, t); notifyListeners(); }

  void newGame({bool fullReset=true}) {
    logs.clear();
    logic.resetAndStart(fullReset: fullReset);
    notifyListeners();
  }

  Future<void> initialChoice(String? choice) async {
    final pts = logic.processTableOrderChoice(choice ?? 'asc');
    log('Orden ${choice ?? 'asc'}: +$pts pts');
  }

  void playerTapCard(CaidaCard c) {
    final res = logic.playerPlayCard(c.id);
    log('Jugaste ${c.displayRank} de ${c.suit}.');
    final eff = res['effects'] as Map<String,dynamic>;
    if (eff['caida']!=null) log('¡Caída! +${eff['caida']} pts.');
    if (eff['mesaLimpia']!=null) log('¡Mesa limpia! +${eff['mesaLimpia']} pts.');
    if (eff['capturedCount']!=null && eff['capturedCount']>2) log('...y te llevas ${eff['capturedCount']-2} en escalera.');
    notifyListeners();
  }

  void opponentAutoPlay() {
    final res = logic.opponentTurn();
    final card = res['card'] as CaidaCard?;
    if (card != null) log('Oponente jugó ${card.displayRank} de ${card.suit}.');
    final eff = res['effects'] as Map<String,dynamic>?;
    if (eff!=null) {
      if (eff['caida']!=null) log('Bot hace caída: +${eff['caida']} pts.');
      if (eff['mesaLimpia']!=null) log('Bot mesa limpia: +${eff['mesaLimpia']} pts.');
      if (eff['capturedCount']!=null && eff['capturedCount']>2) log('Bot se lleva ${eff['capturedCount']-2} en escalera.');
    }
    notifyListeners();
  }
}
