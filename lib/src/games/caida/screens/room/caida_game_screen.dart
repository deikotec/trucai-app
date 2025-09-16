// src/games/caida/screens/caida_game_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../common/widgets/card_widget.dart';
import '../../providers/caida_provider.dart';
import '../../../../core/services/firebase_service.dart';
import '../../models/caida_card.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CaidaGameScreen extends StatefulWidget {
  const CaidaGameScreen({super.key});

  @override
  State<CaidaGameScreen> createState() => _CaidaGameScreenState();
}

class _CaidaGameScreenState extends State<CaidaGameScreen> {
  Future<void> _persist(FirebaseService fb, CaidaProvider p) async {
    final doc = fb.userGameDoc('caidaGame');
    await doc.set({
      'playerScore': p.logic.playerScore,
      'opponentScore': p.logic.opponentScore,
      'playerCapturedCount': p.logic.playerCapturedCount,
      'opponentCapturedCount': p.logic.opponentCapturedCount,
      'isPlayerTurn': p.logic.isPlayerTurn,
      'handNumber': p.logic.handNumber,
      'gameInProgress': true,
    }, SetOptions(merge: true));
  }

  Future<void> _restoreOrStart(FirebaseService fb, CaidaProvider p) async {
    try {
      final doc = await fb.userGameDoc('caidaGame').get();
      if (doc.exists && (doc.data()?['gameInProgress'] == true)) {
        final data = doc.data()!;
        p.logic.playerScore = (data['playerScore'] ?? 0) as int;
        p.logic.opponentScore = (data['opponentScore'] ?? 0) as int;
        p.logic.playerCapturedCount = (data['playerCapturedCount'] ?? 0) as int;
        p.logic.opponentCapturedCount =
            (data['opponentCapturedCount'] ?? 0) as int;
        p.logic.isPlayerTurn = (data['isPlayerTurn'] ?? true) as bool;
        p.logic.handNumber = (data['handNumber'] ?? 0) as int;
        p.log('Estado restaurado desde la nube.');
      } else {
        p.newGame(fullReset: true);
        await _initialChoiceFlow(p);
      }
    } catch (_) {
      p.newGame(fullReset: true);
      await _initialChoiceFlow(p);
    }
  }

  Future<void> _initialChoiceFlow(CaidaProvider p) async {
    if (p.logic.roundStarter == 'player') {
      final choice = await showDialog<String>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Eres mano'),
          content: const Text('Elige el orden de la mesa inicial'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, 'asc'),
              child: const Text('Ascendente'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, 'desc'),
              child: const Text('Descendente'),
            ),
          ],
        ),
      );
      await p.initialChoice(choice);
    } else {
      final choice = (DateTime.now().millisecondsSinceEpoch % 2 == 0)
          ? 'asc'
          : 'desc';
      await p.initialChoice(choice);
      p.log('El Bot eligió $choice.');
    }
  }

  @override
  void initState() {
    super.initState();
    // Atajo: el provider se creará en build; restauramos tras primer frame.
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CaidaProvider(),
      builder: (context, _) {
        final p = context.watch<CaidaProvider>();
        final fb = context.watch<FirebaseService>();

        // Restaurar una vez al montar
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if (p.logs.isEmpty &&
              p.logic.handNumber == 0 &&
              p.logic.playerScore == 0 &&
              p.logic.opponentScore == 0) {
            await _restoreOrStart(fb, p);
            setState(() {});
          }
        });

        final isWide = MediaQuery.of(context).size.width > 900;
        final cardW = isWide ? 100.0 : 72.0;
        final cardH = isWide ? 150.0 : 108.0;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Caída – Trucai'),
            actions: [
              Center(
                child: Text(
                  'Tú: ${p.logic.playerScore} | Bot: ${p.logic.opponentScore}  ',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              IconButton(
                tooltip: 'Nuevo juego',
                onPressed: () async {
                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Confirmación'),
                      content: const Text(
                        '¿Seguro que quieres empezar un nuevo juego?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancelar'),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Sí, seguro'),
                        ),
                      ],
                    ),
                  );
                  if (ok == true) {
                    p.newGame(fullReset: true);
                    await _initialChoiceFlow(p);
                    await _persist(fb, p);
                  }
                },
                icon: const Icon(Icons.replay),
              ),
              IconButton(
                tooltip: 'Salir',
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.exit_to_app),
              ),
            ],
          ),
          body: Row(
            children: [
              // Panel de logs
              Container(
                width: isWide ? 320 : 240,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.15),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const ListTile(
                      title: Text(
                        'Registro de jugadas',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(8),
                        reverse: true,
                        itemCount: p.logs.length,
                        itemBuilder: (_, i) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Text(p.logs[i]),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Mesa + manos
              Expanded(
                child: Column(
                  children: [
                    // Mano rival (boca abajo)
                    SizedBox(
                      height: cardH + 24,
                      child: Center(
                        child: Wrap(
                          alignment: WrapAlignment.center,
                          children: p.logic.opponentHand
                              .map(
                                (_) => Container(
                                  width: cardW,
                                  height: cardH,
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFF4338CA),
                                        Color(0xFF3730A3),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.tealAccent,
                                      width: 2,
                                    ),
                                    boxShadow: const [
                                      BoxShadow(
                                        blurRadius: 6,
                                        color: Colors.black54,
                                      ),
                                    ],
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                    ),
                    // Mesa central
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: const RadialGradient(
                            colors: [Color(0xFF059669), Color(0xFF065F46)],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.tealAccent),
                          boxShadow: const [
                            BoxShadow(
                              blurRadius: 18,
                              color: Colors.black54,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Wrap(
                            alignment: WrapAlignment.center,
                            children: p.logic.tableCards
                                .map(
                                  (c) => CardWidget(
                                    card: c,
                                    width: cardW,
                                    height: cardH,
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                      ),
                    ),
                    // Mano jugador
                    SizedBox(
                      height: cardH + 24,
                      child: Center(
                        child: Wrap(
                          alignment: WrapAlignment.center,
                          children: p.logic.playerHand
                              .map(
                                (c) => CardWidget(
                                  card: c,
                                  width: cardW,
                                  height: cardH,
                                  disabled: !p.logic.isPlayerTurn,
                                  onTap: () async {
                                    if (!p.logic.isPlayerTurn) return;
                                    p.playerTapCard(c);
                                    await _afterAnyPlay(fb, p);
                                  },
                                ),
                              )
                              .toList(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _afterAnyPlay(FirebaseService fb, CaidaProvider p) async {
    final status = p.logic.checkHandOrRound();
    final win = p.logic.checkGameWinner();
    if (win != null) {
      await _persist(fb, p);
      await showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          title: Text(win == 'player' ? '¡Ganaste!' : '¡Perdiste!'),
          content: const Text('¿Qué te gustaría hacer ahora?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cerrar'),
            ),
          ],
        ),
      );
      return;
    }
    if (status == 'deal') {
      final res = p.logic.dealHands();
      if (res['event'] == 'auto-win') {
        p.log('Canto ganador automático (${res['who']}).');
      } else if (res['event'] == 'dealt' && res['winner'] != null) {
        final w = res['winner'];
        p.log(
          '${w['who'] == 'player' ? 'Tienes' : 'El oponente tiene'} canto de ${w['canto']['type']} (+${w['canto']['points']} pts).',
        );
      }
    } else if (status == 'round-end') {
      p.log('Fin de ronda.');
      p.logic.roundStarter = p.logic.roundStarter == 'player'
          ? 'opponent'
          : 'player';
      p.logic.resetAndStart(fullReset: false);
      await _initialChoiceFlow(p);
    }

    if (!p.logic.isPlayerTurn) {
      await Future.delayed(const Duration(milliseconds: 900));
      p.opponentAutoPlay();
      final post = p.logic.checkHandOrRound();
      final w2 = p.logic.checkGameWinner();
      if (w2 != null) {
        await _persist(fb, p);
        await showDialog<void>(
          context: context,
          builder: (_) => AlertDialog(
            title: Text(w2 == 'player' ? '¡Ganaste!' : '¡Perdiste!'),
            content: const Text('¿Qué te gustaría hacer ahora?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cerrar'),
              ),
            ],
          ),
        );
        return;
      }
      if (post == 'deal') {
        final res2 = p.logic.dealHands();
        if (res2['event'] == 'auto-win') {
          p.log('Canto ganador automático (${res2['who']}).');
        } else if (res2['event'] == 'dealt' && res2['winner'] != null) {
          final w = res2['winner'];
          p.log(
            '${w['who'] == 'player' ? 'Tienes' : 'El oponente tiene'} canto de ${w['canto']['type']} (+${w['canto']['points']} pts).',
          );
        }
      } else if (post == 'round-end') {
        p.log('Fin de ronda.');
        p.logic.roundStarter = p.logic.roundStarter == 'player'
            ? 'opponent'
            : 'player';
        p.logic.resetAndStart(fullReset: false);
        await _initialChoiceFlow(p);
      }
    }

    await _persist(fb, p);
  }
}
