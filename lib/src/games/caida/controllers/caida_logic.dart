// src/games/caida/controllers/caida_logic.dart
// Esta clase contiene toda la lógica pura del juego de Caída,
// independientemente de la interfaz de usuario. Es la traducción
// directa y mejorada de la lógica que tenías en JavaScript.

import 'dart:math';
import '../models/caida_card.dart';

class CaidaLogic {
  // --- CONSTANTES Y REGLAS DEL JUEGO ---
  static const int gameTargetScore = 24;
  static const int mesaLimpiaBonus = 4;
  static const int capturedBonusThreshold = 20;

  // --- ESTADO DEL JUEGO ---
  List<CaidaCard> fullShuffledDeck = [];
  List<CaidaCard> deck = [];
  List<CaidaCard> playerHand = [];
  List<CaidaCard> opponentHand = [];
  List<CaidaCard> tableCards = [];

  int playerScore = 0;
  int opponentScore = 0;
  int playerCapturedCount = 0;
  int opponentCapturedCount = 0;

  bool isPlayerTurn = true;
  String? lastCardPlayedByPreviousPlayerRank;
  String? lastPlayerToCapture; // 'player' o 'opponent'
  String roundStarter = 'player';
  bool isFirstHandOfGame = true;
  int handNumber = 0;
  bool gameInProgress = false;

  // --- MÉTODOS DE INICIALIZACIÓN Y MANEJO DEL MAZO ---

  List<CaidaCard> _createDeck() {
    final List<CaidaCard> newDeck = [];
    for (final suit in CaidaCard.suits.keys) {
      for (final rank in CaidaCard.ranks.keys) {
        newDeck.add(CaidaCard(rank: rank, suit: suit));
      }
    }
    return newDeck;
  }

  void _shuffleDeck(List<CaidaCard> deckToShuffle) {
    deckToShuffle.shuffle(Random());
  }

  void startNewGame({bool fullReset = true}) {
    if (fullReset) {
      playerScore = 0;
      opponentScore = 0;
      roundStarter = Random().nextBool() ? 'player' : 'opponent';
      fullShuffledDeck = _createDeck();
      _shuffleDeck(fullShuffledDeck);
    }

    playerCapturedCount = 0;
    opponentCapturedCount = 0;

    playerHand.clear();
    opponentHand.clear();
    tableCards.clear();

    lastCardPlayedByPreviousPlayerRank = null;
    lastPlayerToCapture = roundStarter == 'player' ? 'opponent' : 'player';
    isFirstHandOfGame = true;
    handNumber = 0;

    deck = List.of(fullShuffledDeck);

    final Set<String> ranksOnTable = {};
    while (tableCards.length < 4 && deck.isNotEmpty) {
      final card = deck.removeAt(0);
      if (!ranksOnTable.contains(card.rank)) {
        tableCards.add(card);
        ranksOnTable.add(card.rank);
      } else {
        // Si la carta ya está, la devolvemos al final del mazo y barajamos de nuevo
        // para asegurar 4 cartas únicas en la mesa si es posible.
        deck.add(card);
        _shuffleDeck(deck);
      }
    }
    gameInProgress = true;
  }

  // --- LÓGICA DE JUGADAS Y TURNOS ---

  int processTableOrderChoice(String choice) {
    final sequence = choice == 'asc'
        ? ['1', '2', '3', '4']
        : ['4', '3', '2', '1'];
    final sortedTable = [...tableCards]
      ..sort((a, b) => a.numericValue.compareTo(b.numericValue));

    int points = 0;
    for (int i = 0; i < sortedTable.length; i++) {
      if (i < sequence.length && sortedTable[i].rank == sequence[i]) {
        points += sortedTable[i].numericValue;
      }
    }

    if (points == 0) {
      points = 1;
      if (roundStarter == 'player')
        opponentScore += points;
      else
        playerScore += points;
    } else {
      if (roundStarter == 'player')
        playerScore += points;
      else
        opponentScore += points;
    }

    isPlayerTurn = (roundStarter != 'player');

    return points;
  }

  Map<String, dynamic> dealHandsAndCheckCantos() {
    if (deck.length < 6) return {'event': 'no-more-cards'};
    handNumber++;

    for (int i = 0; i < 3; i++) {
      if (deck.isNotEmpty) playerHand.add(deck.removeAt(0));
      if (deck.isNotEmpty) opponentHand.add(deck.removeAt(0));
    }
    playerHand.sort((a, b) => a.numericValue.compareTo(b.numericValue));

    final playerCanto = _checkCantos(playerHand);
    final opponentCanto = _checkCantos(opponentHand);
    Map<String, dynamic>? winnerCantoInfo;

    if (playerCanto != null || opponentCanto != null) {
      String? winner;
      Map<String, dynamic>? winningCanto;

      if (opponentCanto == null ||
          (playerCanto != null &&
              playerCanto['points'] > opponentCanto['points'])) {
        winner = 'player';
        winningCanto = playerCanto;
      } else if (playerCanto == null ||
          (opponentCanto['points'] > playerCanto['points'])) {
        winner = 'opponent';
        winningCanto = opponentCanto;
      } else {
        // Empate en puntos, decide el rango de la carta
        if (CaidaCard.ranks[playerCanto['rank']]! >
            CaidaCard.ranks[opponentCanto['rank']]!) {
          winner = 'player';
          winningCanto = playerCanto;
        } else {
          winner = 'opponent';
          winningCanto = opponentCanto;
        }
      }

      if (winningCanto != null) {
        final int points = winningCanto['points'];
        if (winner == 'player') {
          playerScore += points;
        } else {
          opponentScore += points;
        }

        winnerCantoInfo = {'who': winner, 'canto': winningCanto};

        if (winningCanto['autoWin'] == true) {
          return {'event': 'auto-win', 'winner': winner, 'canto': winningCanto};
        }
      }
    }

    isFirstHandOfGame = false;
    return {'event': 'dealt', 'cantoResult': winnerCantoInfo};
  }

  Map<String, dynamic>? _checkCantos(List<CaidaCard> hand) {
    if (hand.length < 3) return null;
    final sorted = [...hand]
      ..sort((a, b) => a.numericValue.compareTo(b.numericValue));
    final r = sorted.map((c) => c.rank).toList();
    final v = sorted.map((c) => c.numericValue).toList();
    final possible = <Map<String, dynamic>>[];

    if (v.length >= 3 && v[0] == v[1] && v[1] == v[2]) {
      possible.add({
        'type': 'Tribilín',
        'points': isFirstHandOfGame ? gameTargetScore : 5,
        'rank': r[0],
        'autoWin': isFirstHandOfGame,
      });
    }
    if (r.contains('1') && r.contains('C') && r.contains('R')) {
      possible.add({
        'type': 'Registro',
        'points': 8,
        'rank': 'R',
        'autoWin': false,
      });
    }
    if (v.length >= 3) {
      final isVigia =
          (v[0] == v[1] && v[2] == v[0] + 1) ||
          (v[1] == v[2] && v[0] == v[1] - 1);
      if (isVigia) {
        possible.add({
          'type': 'Vigía',
          'points': 7,
          'rank': v[0] == v[1] ? r[0] : r[1],
          'autoWin': false,
        });
      }
    }
    if (v.length >= 3 && v[0] + 1 == v[1] && v[1] + 1 == v[2]) {
      possible.add({
        'type': 'Patrulla',
        'points': 6,
        'rank': r[2],
        'autoWin': false,
      });
    }
    if (v.length >= 2) {
      String? rondaRank;
      if (v[0] == v[1]) {
        rondaRank = r[0];
      } else if (v.length >= 3 && v[1] == v[2]) {
        rondaRank = r[1];
      }

      if (rondaRank != null) {
        possible.add({
          'type': 'Ronda',
          'points': CaidaCard.cantoPointsRonda[rondaRank],
          'rank': rondaRank,
          'autoWin': false,
        });
      }
    }

    if (possible.isEmpty) return null;
    possible.sort((a, b) => (b['points'] as int).compareTo(a['points'] as int));
    return possible.first;
  }

  CaidaCard botChooseCard() {
    opponentHand.sort(
      (a, b) => b.numericValue.compareTo(a.numericValue),
    ); // Juega de mayor a menor
    // Intenta hacer una caída.
    for (final card in opponentHand) {
      if (card.rank == lastCardPlayedByPreviousPlayerRank) {
        return card;
      }
    }
    // Intenta capturar.
    for (final card in opponentHand) {
      if (tableCards.any((tableCard) => tableCard.rank == card.rank)) {
        return card;
      }
    }
    return opponentHand.last; // Si no, juega la carta de menor valor.
  }

  String botRandomChoice() => Random().nextBool() ? 'asc' : 'desc';

  Map<String, dynamic> processPlay(CaidaCard playedCard, String currentPlayer) {
    final Map<String, dynamic> effects = {};

    if (currentPlayer == 'player') {
      playerHand.removeWhere((c) => c.id == playedCard.id);
    } else {
      opponentHand.removeWhere((c) => c.id == playedCard.id);
    }

    if (playedCard.rank == lastCardPlayedByPreviousPlayerRank) {
      final caidaValue = CaidaCard.cardPointsCaida[playedCard.rank]!;
      if (currentPlayer == 'player')
        playerScore += caidaValue;
      else
        opponentScore += caidaValue;
      effects['caida'] = {'value': caidaValue, 'rank': playedCard.displayRank};
    }
    lastCardPlayedByPreviousPlayerRank = playedCard.rank;

    final mainCaptureIndex = tableCards.indexWhere(
      (c) => c.rank == playedCard.rank,
    );
    if (mainCaptureIndex > -1) {
      List<CaidaCard> capturedCardsOnPlay = [playedCard];
      final mainCapturedCard = tableCards.removeAt(mainCaptureIndex);
      capturedCardsOnPlay.add(mainCapturedCard);

      lastPlayerToCapture = currentPlayer;

      tableCards.sort((a, b) => a.numericValue.compareTo(b.numericValue));
      int lastCapturedValue = mainCapturedCard.numericValue;
      bool sequenceFound = true;
      while (sequenceFound) {
        sequenceFound = false;
        final nextInSequenceIndex = tableCards.indexWhere(
          (c) => c.numericValue == lastCapturedValue + 1,
        );
        if (nextInSequenceIndex > -1) {
          final sequenceCard = tableCards.removeAt(nextInSequenceIndex);
          capturedCardsOnPlay.add(sequenceCard);
          lastCapturedValue = sequenceCard.numericValue;
          sequenceFound = true;
        }
      }

      effects['capture'] = {
        'played': playedCard,
        'captured': capturedCardsOnPlay
            .where((c) => c.id != playedCard.id)
            .toList(),
      };

      if (tableCards.isEmpty) {
        if (currentPlayer == 'player')
          playerScore += mesaLimpiaBonus;
        else
          opponentScore += mesaLimpiaBonus;
        effects['mesaLimpia'] = true;
      }

      if (currentPlayer == 'player')
        playerCapturedCount += capturedCardsOnPlay.length;
      else
        opponentCapturedCount += capturedCardsOnPlay.length;
    } else {
      tableCards.add(playedCard);
    }

    isPlayerTurn = !isPlayerTurn;

    return effects;
  }

  // --- LÓGICA DE FIN DE RONDA Y PARTIDA ---

  bool isHandFinished() {
    return playerHand.isEmpty && opponentHand.isEmpty;
  }

  Map<String, dynamic> endRound() {
    final Map<String, dynamic> roundEndSummary = {};

    if (tableCards.isNotEmpty && lastPlayerToCapture != null) {
      if (lastPlayerToCapture == 'player')
        playerCapturedCount += tableCards.length;
      else
        opponentCapturedCount += tableCards.length;
      roundEndSummary['remainingCards'] = {
        'winner': lastPlayerToCapture,
        'count': tableCards.length,
      };
      tableCards.clear();
    }

    final playerBonus = max(0, playerCapturedCount - capturedBonusThreshold);
    if (playerBonus > 0) {
      playerScore += playerBonus;
      roundEndSummary['playerBonus'] = playerBonus;
    }

    final opponentBonus = max(
      0,
      opponentCapturedCount - capturedBonusThreshold,
    );
    if (opponentBonus > 0) {
      opponentScore += opponentBonus;
      roundEndSummary['opponentBonus'] = opponentBonus;
    }

    // Cambia quien empieza la siguiente ronda
    roundStarter = roundStarter == 'player' ? 'opponent' : 'player';
    startNewGame(fullReset: false);

    return roundEndSummary;
  }

  String? checkGameWinner() {
    if (playerScore >= gameTargetScore) {
      gameInProgress = false;
      return 'player';
    }
    if (opponentScore >= gameTargetScore) {
      gameInProgress = false;
      return 'opponent';
    }
    return null;
  }
}
