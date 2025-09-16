// src/games/caida/controllers/caida_logic.dart
import 'dart:math';
import '../models/caida_card.dart';

class CaidaLogic {
  static const suits = ['O', 'C', 'E', 'B'];
  static const ranks = ['1', '2', '3', '4', '5', '6', '7', 'S', 'C', 'R'];
  static const rankDisplay = {
    '1': 'As',
    '2': '2',
    '3': '3',
    '4': '4',
    '5': '5',
    '6': '6',
    '7': '7',
    'S': 'Sota',
    'C': 'Caballo',
    'R': 'Rey',
  };
  static const rankNumeric = {
    '1': 1,
    '2': 2,
    '3': 3,
    '4': 4,
    '5': 5,
    '6': 6,
    '7': 7,
    'S': 8,
    'C': 9,
    'R': 10,
  };

  static const cardPointsCaida = {
    '1': 1,
    '2': 1,
    '3': 1,
    '4': 1,
    '5': 1,
    '6': 1,
    '7': 1,
    'S': 2,
    'C': 3,
    'R': 4,
  };
  static const cantoPointsRonda = {
    '1': 1,
    '2': 1,
    '3': 1,
    '4': 1,
    '5': 1,
    '6': 1,
    '7': 1,
    'S': 2,
    'C': 3,
    'R': 4,
  };

  static const gameTargetScore = 24;
  static const mesaLimpiaBonus = 4;
  static const capturedBonusThreshold = 20;

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
  String? lastPlayerToCapture;
  String roundStarter = 'player';
  bool isFirstHandOfGame = true;
  int handNumber = 0;

  List<CaidaCard> createDeck() {
    final d = <CaidaCard>[];
    for (final s in suits) {
      for (final r in ranks) {
        d.add(
          CaidaCard(
            id: '$r$s',
            rank: r,
            suit: s,
            numericValue: rankNumeric[r]!,
            displayRank: rankDisplay[r]!,
          ),
        );
      }
    }
    return d;
  }

  void shuffle(List<CaidaCard> d) {
    final rnd = Random();
    for (int i = d.length - 1; i > 0; i--) {
      final j = rnd.nextInt(i + 1);
      final t = d[i];
      d[i] = d[j];
      d[j] = t;
    }
  }

  void resetAndStart({bool fullReset = true}) {
    playerHand.clear();
    opponentHand.clear();
    tableCards.clear();
    lastCardPlayedByPreviousPlayerRank = null;
    lastPlayerToCapture = roundStarter == 'player' ? 'opponent' : 'player';
    isFirstHandOfGame = true;
    handNumber = 0;

    if (fullReset) {
      playerScore = 0;
      opponentScore = 0;
      playerCapturedCount = 0;
      opponentCapturedCount = 0;
      roundStarter = Random().nextBool() ? 'player' : 'opponent';
      deck = createDeck();
      shuffle(deck);
      fullShuffledDeck = List.of(deck);
    }

    deck = List.of(fullShuffledDeck);
    tableCards.clear();
    final drawn = <String>{};
    while (tableCards.length < 4 && deck.isNotEmpty) {
      final c = deck.removeAt(0);
      if (!drawn.contains(c.rank)) {
        tableCards.add(c);
        drawn.add(c.rank);
      }
    }
  }

  Map<String, dynamic>? checkCantos(List<CaidaCard> hand) {
    if (hand.length < 3) return null;
    final sorted = [...hand]
      ..sort((a, b) => a.numericValue.compareTo(b.numericValue));
    final r = sorted.map((c) => c.rank).toList();
    final v = sorted.map((c) => c.numericValue).toList();
    final possible = <Map<String, dynamic>>[];

    if (v[0] == v[1] && v[1] == v[2]) {
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
    if (v[0] + 1 == v[1] && v[1] + 1 == v[2]) {
      possible.add({
        'type': 'Patrulla',
        'points': 6,
        'rank': r[2],
        'autoWin': false,
      });
    }
    if (v[0] == v[1] || v[1] == v[2]) {
      final rondaRank = (v[0] == v[1]) ? r[0] : r[1];
      possible.add({
        'type': 'Ronda',
        'points': cantoPointsRonda[rondaRank],
        'rank': rondaRank,
        'autoWin': false,
      });
    }

    if (possible.isEmpty) return null;
    possible.sort((a, b) => (b['points'] as int).compareTo(a['points'] as int));
    return possible.first;
  }

  Map<String, dynamic> dealHands() {
    if (deck.length < 6) return {'event': 'no-more-cards'};
    handNumber++;
    for (int i = 0; i < 3; i++) {
      playerHand.add(deck.removeAt(0));
      opponentHand.add(deck.removeAt(0));
    }
    final p = checkCantos(playerHand);
    final o = checkCantos(opponentHand);
    Map<String, dynamic>? winner;
    if (p != null || o != null) {
      if (o == null ||
          (p != null && (p['points'] as int) > (o['points'] as int))) {
        winner = {'who': 'player', 'canto': p};
      } else if (p == null || ((o['points'] as int) > (p['points'] as int))) {
        winner = {'who': 'opponent', 'canto': o};
      } else {
        final pr = rankNumeric[p['rank']]!;
        final or = rankNumeric[o['rank']]!;
        winner = (pr > or)
            ? {'who': 'player', 'canto': p}
            : {'who': 'opponent', 'canto': o};
      }
      final pts = (winner['canto']['points'] as int);
      if (winner['who'] == 'player') {
        playerScore += pts;
      } else {
        opponentScore += pts;
      }
      if (pts >= gameTargetScore) {
        return {'event': 'auto-win', 'who': winner['who']};
      }
    }
    isFirstHandOfGame = false;
    return {'event': 'dealt', 'winner': winner};
  }

  Map<String, dynamic> playerPlayCard(String cardId) {
    final idx = playerHand.indexWhere((c) => c.id == cardId);
    if (idx < 0) return {'error': 'card-not-found'};
    final played = playerHand.removeAt(idx);
    final eff = _processPlay(played, 'player');
    return {'event': 'player-play', 'card': played, 'effects': eff};
  }

  Map<String, dynamic> opponentTurn() {
    if (opponentHand.isEmpty) return {'event': 'opponent-pass'};
    final played = opponentHand.removeAt(0);
    final eff = _processPlay(played, 'opponent');
    return {'event': 'opponent-play', 'card': played, 'effects': eff};
  }

  Map<String, dynamic> _processPlay(CaidaCard played, String who) {
    final effects = <String, dynamic>{};
    if (lastCardPlayedByPreviousPlayerRank == played.rank) {
      final val = cardPointsCaida[played.rank]!;
      if (who == 'player') {
        playerScore += val;
      } else {
        opponentScore += val;
      }
      effects['caida'] = val;
    }
    lastCardPlayedByPreviousPlayerRank = played.rank;

    final idx = tableCards.indexWhere((c) => c.rank == played.rank);
    if (idx > -1) {
      final captured = <CaidaCard>[];
      captured.add(played);
      final main = tableCards.removeAt(idx);
      captured.add(main);
      lastPlayerToCapture = who;

      int lastVal = main.numericValue;
      bool keep = true;
      while (keep) {
        keep = false;
        final nextIdx = tableCards.indexWhere(
          (c) => c.numericValue == lastVal + 1,
        );
        if (nextIdx > -1) {
          final seq = tableCards.removeAt(nextIdx);
          captured.add(seq);
          lastVal = seq.numericValue;
          keep = true;
        }
      }

      if (tableCards.isEmpty) {
        if (who == 'player') {
          playerScore += mesaLimpiaBonus;
        } else {
          opponentScore += mesaLimpiaBonus;
        }
        effects['mesaLimpia'] = mesaLimpiaBonus;
      }

      if (who == 'player') {
        playerCapturedCount += captured.length;
      } else {
        opponentCapturedCount += captured.length;
      }
      effects['capturedCount'] = captured.length;
    } else {
      tableCards.add(played);
    }

    isPlayerTurn = (who != 'player');
    return effects;
  }

  String checkHandOrRound() {
    if (playerHand.isEmpty && opponentHand.isEmpty) {
      if (deck.isNotEmpty) {
        return 'deal';
      } else {
        if (tableCards.isNotEmpty) {
          if (lastPlayerToCapture == 'player') {
            playerCapturedCount += tableCards.length;
          } else {
            opponentCapturedCount += tableCards.length;
          }
          tableCards.clear();
        }
        final pBonus = (playerCapturedCount - capturedBonusThreshold).clamp(
          0,
          1000,
        );
        final oBonus = (opponentCapturedCount - capturedBonusThreshold).clamp(
          0,
          1000,
        );
        playerScore += pBonus;
        opponentScore += oBonus;
        return 'round-end';
      }
    }
    return 'continue';
  }

  String? checkGameWinner() {
    if (playerScore >= gameTargetScore) return 'player';
    if (opponentScore >= gameTargetScore) return 'opponent';
    return null;
  }

  int processTableOrderChoice(String choice) {
    final seq = choice == 'asc' ? ['1', '2', '3', '4'] : ['4', '3', '2', '1'];
    final sorted = [...tableCards]
      ..sort((a, b) => a.numericValue.compareTo(b.numericValue));
    int points = 0;
    for (int i = 0; i < sorted.length; i++) {
      if (sorted[i].rank == seq[i]) points += sorted[i].numericValue;
    }
    if (points == 0) {
      if (roundStarter == 'player') {
        opponentScore += 1;
      } else {
        playerScore += 1;
      }
      isPlayerTurn = (roundStarter != 'player');
      return 1;
    } else {
      if (roundStarter == 'player') {
        playerScore += points;
      } else {
        opponentScore += points;
      }
      isPlayerTurn = (roundStarter != 'player');
      return points;
    }
  }
}
