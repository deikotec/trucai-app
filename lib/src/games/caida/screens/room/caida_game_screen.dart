// src/games/caida/screens/caida_game_screen.dart
// Pantalla de Caída: integra vuelo de carta (mano -> mesa) con FxOverlay.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/caida_provider.dart';
import '../../../../core/services/firebase_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import './components/opponent_hand.dart';
import './components/table_board.dart';
import './components/player_hand.dart';
import './components/log_panel.dart';
import './components/score_panel.dart';
import '../../../common/fx/fx_controller.dart';
import '../../../common/fx/fx_overlay.dart';

class CaidaGameScreen extends StatefulWidget {
  const CaidaGameScreen({super.key});

  @override
  State<CaidaGameScreen> createState() => _CaidaGameScreenState();
}

class _CaidaGameScreenState extends State<CaidaGameScreen> {
  final GlobalKey _centerStackKey =
      GlobalKey(); // referencia para coords locales
  final GlobalKey _tableKey = GlobalKey(); // destino del vuelo
  final FxController _fx = FxController();

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
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CaidaProvider(),
      builder: (context, _) {
        final p = context.watch<CaidaProvider>();
        final fb = context.watch<FirebaseService>();

        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if (p.logs.isEmpty &&
              p.logic.handNumber == 0 &&
              p.logic.playerScore == 0 &&
              p.logic.opponentScore == 0) {
            await _restoreOrStart(fb, p);
            setState(() {});
          }
        });

        final isWide = MediaQuery.of(context).size.width > 1000;
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
            ],
          ),
          body: Row(
            children: [
              const LogPanel(),
              // Zona central apilada: contenido + overlay FX
              Expanded(
                child: Stack(
                  key: _centerStackKey,
                  children: [
                    Column(
                      children: [
                        OpponentHand(
                          cardWidth: cardW,
                          cardHeight: cardH,
                          areaKey: _centerStackKey,
                        ),
                        // Asignamos la key del destino
                        TableBoard(
                          key: _tableKey,
                          cardWidth: cardW,
                          cardHeight: cardH,
                        ),
                        PlayerHand(
                          cardWidth: cardW,
                          cardHeight: cardH,
                          centerStackKey: _centerStackKey,
                          tableKey: _tableKey,
                          fx: _fx,
                        ),
                      ],
                    ),
                    FxOverlay(controller: _fx),
                  ],
                ),
              ),
              if (isWide)
                ScorePanel(
                  onNewGame: () async {
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
                  onExit: () => Navigator.of(context).pop(),
                ),
            ],
          ),
          bottomNavigationBar: isWide
              ? null
              : SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(
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
                                      onPressed: () =>
                                          Navigator.pop(context, false),
                                      child: const Text('Cancelar'),
                                    ),
                                    FilledButton(
                                      onPressed: () =>
                                          Navigator.pop(context, true),
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
                            label: const Text('Nuevo juego'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.exit_to_app),
                            label: const Text('Salir'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
        );
      },
    );
  }
}
