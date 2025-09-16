// src/games/caida/providers/caida_provider.dart
// Este provider actúa como el cerebro que conecta la UI con la lógica del juego.
// Maneja las acciones del usuario, las respuestas del bot, la persistencia
// de datos y notifica a la UI sobre cualquier cambio en el estado.

import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

import '../controllers/caida_logic.dart';
import '../models/caida_card.dart';
import '../../../core/services/firebase_service.dart';

class CaidaProvider extends ChangeNotifier {
  final CaidaLogic logic = CaidaLogic();
  final List<String> logs = [];
  bool isGameReady = false; // Controla la pantalla de carga inicial.
  String? gameWinner;

  // --- MÉTODOS DE LOGGING ---
  void _log(String message) {
    logs.insert(0, message);
    if (logs.length > 100)
      logs.removeLast(); // Evita que la lista crezca indefinidamente.
  }

  void _logEffects(
    Map<String, dynamic> effects,
    String player,
    CaidaCard playedCard,
  ) {
    final playerName = player == 'player' ? 'Tú' : 'El Bot';
    if (effects['caida'] != null) {
      _log(
        '¡Caída! $playerName suma ${effects['caida']['value']} pts con ${effects['caida']['rank']}.',
      );
    }
    if (effects['capture'] != null) {
      final List<CaidaCard> captured = effects['capture']['captured'];
      final capturedText = captured.map((c) => c.displayRank).join(', ');
      _log('$playerName captura $capturedText con ${playedCard.displayRank}.');
    }
    if (effects['mesaLimpia'] == true) {
      _log(
        '¡Mesa Limpia! $playerName gana ${CaidaLogic.mesaLimpiaBonus} pts extra.',
      );
    }
  }

  // --- GESTIÓN DEL ESTADO DEL JUEGO ---

  // Inicia un nuevo juego desde cero.
  void newGame({bool fullReset = true}) {
    logs.clear();
    gameWinner = null;
    logic.startNewGame(fullReset: fullReset);
    _log("Nuevo juego comenzado.");
    notifyListeners();
  }

  // Procesa la elección inicial del orden de la mesa.
  // **CORRECCIÓN**: Se añade el parámetro FirebaseService para poder llamar a opponentAutoPlay.
  void initialChoice(String choice, FirebaseService fb) {
    final pts = logic.processTableOrderChoice(choice);
    _log(
      '${logic.roundStarter == 'player' ? 'Elegiste' : 'El Bot eligió'} orden ${choice == 'asc' ? 'ascendente' : 'descendente'}: +$pts pts.',
    );

    final result = logic.dealHandsAndCheckCantos();
    _handleCantoResult(result['cantoResult']);

    notifyListeners();

    // **CORRECCIÓN**: Si después de la configuración inicial es el turno del bot, iniciar su jugada.
    if (!logic.isPlayerTurn && logic.gameInProgress) {
      Future.delayed(
        const Duration(milliseconds: 1500),
        () => opponentAutoPlay(fb),
      );
    }
  }

  // Maneja la acción del jugador al tocar una carta.
  Future<void> playerPlayCard(CaidaCard card, FirebaseService fb) async {
    if (!logic.isPlayerTurn || !logic.gameInProgress) return;

    final effects = logic.processPlay(card, 'player');
    _logEffects(effects, 'player', card);

    _postPlayChecks(fb);
  }

  // Dispara la jugada automática del oponente.
  Future<void> opponentAutoPlay(FirebaseService fb) async {
    if (logic.isPlayerTurn ||
        !logic.gameInProgress ||
        logic.opponentHand.isEmpty)
      return;

    final cardToPlay = logic.botChooseCard();
    final effects = logic.processPlay(cardToPlay, 'opponent');
    _log('Oponente jugó ${cardToPlay.displayRank} de ${cardToPlay.suit}.');
    _logEffects(effects, 'opponent', cardToPlay);

    _postPlayChecks(fb);
  }

  // Comprobaciones que se hacen después de cada jugada.
  void _postPlayChecks(FirebaseService fb) {
    notifyListeners();
    persistGameState(fb);

    gameWinner = logic.checkGameWinner();
    if (gameWinner != null) {
      _log("¡Fin del juego! Ganador: $gameWinner");
      logic.gameInProgress = false;
      persistGameState(fb); // Guarda el estado final
      notifyListeners();
      return;
    }

    if (logic.isHandFinished()) {
      _handleHandEnd(fb);
    } else if (!logic.isPlayerTurn) {
      Future.delayed(
        const Duration(milliseconds: 1200),
        () => opponentAutoPlay(fb),
      );
    }
  }

  // Lógica para el final de una mano (cuando ambos se quedan sin cartas).
  void _handleHandEnd(FirebaseService fb) {
    if (!logic.gameInProgress) return;

    if (logic.deck.isEmpty) {
      _log("Fin de la ronda. Contando puntos extra...");
      final summary = logic.endRound();
      if (summary['playerBonus'] != null)
        _log("Bonus para ti: ${summary['playerBonus']} pts.");
      if (summary['opponentBonus'] != null)
        _log("Bonus para el Bot: ${summary['opponentBonus']} pts.");

      _log(
        "Comenzando nueva ronda. ${logic.roundStarter == 'player' ? 'Eres' : 'El Bot es'} mano.",
      );

      // La UI se encargará de mostrar el diálogo si es turno del jugador.
    } else {
      _log("Repartiendo nuevas cartas.");
      final result = logic.dealHandsAndCheckCantos();
      _handleCantoResult(result['cantoResult']);
    }

    gameWinner = logic.checkGameWinner();
    if (gameWinner != null) {
      _log("¡Fin del juego! Ganador: $gameWinner");
      logic.gameInProgress = false;
    }

    notifyListeners();
    persistGameState(fb);

    if (!logic.isPlayerTurn && logic.gameInProgress) {
      Future.delayed(
        const Duration(milliseconds: 1200),
        () => opponentAutoPlay(fb),
      );
    }
  }

  void _handleCantoResult(Map<String, dynamic>? cantoResult) {
    if (cantoResult != null) {
      final who = cantoResult['who'] == 'player' ? 'Tienes' : 'El Bot tiene';
      final canto = cantoResult['canto'];
      _log(
        "¡Canto! $who ${canto['type']} de ${canto['rank']}. +${canto['points']} pts.",
      );
    }
  }

  // --- PERSISTENCIA DE DATOS ---

  Future<void> persistGameState(FirebaseService fb) async {
    try {
      final docRef = fb.userGameDoc('caida');
      final state = {
        'playerScore': logic.playerScore,
        'opponentScore': logic.opponentScore,
        'playerCapturedCount': logic.playerCapturedCount,
        'opponentCapturedCount': logic.opponentCapturedCount,
        'isPlayerTurn': logic.isPlayerTurn,
        'handNumber': logic.handNumber,
        'gameInProgress': logic.gameInProgress,
        'roundStarter': logic.roundStarter,
        'lastPlayerToCapture': logic.lastPlayerToCapture,
        'lastCardPlayedByPreviousPlayerRank':
            logic.lastCardPlayedByPreviousPlayerRank,
        'fullShuffledDeck': logic.fullShuffledDeck
            .map((c) => c.toMap())
            .toList(),
        'deck': logic.deck.map((c) => c.toMap()).toList(),
        'playerHand': logic.playerHand.map((c) => c.toMap()).toList(),
        'opponentHand': logic.opponentHand.map((c) => c.toMap()).toList(),
        'tableCards': logic.tableCards.map((c) => c.toMap()).toList(),
      };
      await docRef.set(state, SetOptions(merge: true));
    } catch (e) {
      debugPrint("Error al guardar el estado del juego: $e");
    }
  }

  Future<bool> restoreGameFromFirebase(FirebaseService fb) async {
    try {
      final doc = await fb.userGameDoc('caida').get();
      if (doc.exists && doc.data()?['gameInProgress'] == true) {
        final data = doc.data()!;
        logic.playerScore = data['playerScore'] ?? 0;
        logic.opponentScore = data['opponentScore'] ?? 0;
        logic.playerCapturedCount = data['playerCapturedCount'] ?? 0;
        logic.opponentCapturedCount = data['opponentCapturedCount'] ?? 0;
        logic.isPlayerTurn = data['isPlayerTurn'] ?? true;
        logic.handNumber = data['handNumber'] ?? 0;
        logic.gameInProgress = data['gameInProgress'] ?? false;
        logic.roundStarter = data['roundStarter'] ?? 'player';
        logic.lastPlayerToCapture = data['lastPlayerToCapture'];
        logic.lastCardPlayedByPreviousPlayerRank =
            data['lastCardPlayedByPreviousPlayerRank'];
        logic.fullShuffledDeck = (data['fullShuffledDeck'] as List? ?? [])
            .map((map) => CaidaCard.fromMap(map))
            .toList();
        logic.deck = (data['deck'] as List? ?? [])
            .map((map) => CaidaCard.fromMap(map))
            .toList();
        logic.playerHand = (data['playerHand'] as List? ?? [])
            .map((map) => CaidaCard.fromMap(map))
            .toList();
        logic.opponentHand = (data['opponentHand'] as List? ?? [])
            .map((map) => CaidaCard.fromMap(map))
            .toList();
        logic.tableCards = (data['tableCards'] as List? ?? [])
            .map((map) => CaidaCard.fromMap(map))
            .toList();
        _log('Partida anterior restaurada.');
        isGameReady = true;
        notifyListeners();

        // **CORRECCIÓN**: Si al restaurar es el turno del bot, que juegue.
        if (!logic.isPlayerTurn && logic.gameInProgress) {
          Future.microtask(() => opponentAutoPlay(fb));
        }
        return true;
      }
    } catch (e) {
      debugPrint("Error al restaurar el estado del juego: $e");
    }
    // Si no hay juego para restaurar o hay un error, el juego está "listo" para empezar de cero.
    isGameReady = true;
    notifyListeners();
    return false;
  }
}
