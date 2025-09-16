// src/games/caida/screens/room/caida_game_screen.dart
// Esta es la pantalla principal donde se desarrolla el juego de Caída.
// Integra todos los componentes de la UI (manos, mesa, logs) y maneja
// la lógica de red y persistencia del estado del juego.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';

import '../../providers/caida_provider.dart';
import '../../../../core/services/firebase_service.dart';
import './components/opponent_hand.dart';
import './components/table_board.dart';
import './components/player_hand.dart';
import './components/log_panel.dart';
import './components/score_panel.dart';
import './components/bottom_action_panel.dart';
import './components/game_over_dialog.dart';
import '../../../common/fx/fx_controller.dart';
import '../../../common/fx/fx_overlay.dart';

// El StatefulWidget ahora solo gestiona el estado de la propia pantalla.
class CaidaGameScreen extends StatefulWidget {
  const CaidaGameScreen({super.key});

  @override
  State<CaidaGameScreen> createState() => _CaidaGameScreenState();
}

class _CaidaGameScreenState extends State<CaidaGameScreen> {
  final GlobalKey _centerStackKey = GlobalKey();
  final GlobalKey _tableKey = GlobalKey();
  final FxController _fxController = FxController();

  // El ChangeNotifierProvider ahora envuelve la pantalla del juego
  // para que el estado del provider persista durante toda la vida de la pantalla.
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CaidaProvider(),
      child: const _CaidaGameView(),
    );
  }
}

// Un widget interno para construir la UI una vez que el provider está disponible.
class _CaidaGameView extends StatefulWidget {
  const _CaidaGameView();

  @override
  State<_CaidaGameView> createState() => _CaidaGameViewState();
}

class _CaidaGameViewState extends State<_CaidaGameView> {
  final GlobalKey _centerStackKey = GlobalKey();
  final GlobalKey _tableKey = GlobalKey();
  final FxController _fxController = FxController();
  bool _isInitializing = false;

  @override
  void initState() {
    super.initState();
    // La inicialización se llama una sola vez.
    WidgetsBinding.instance.addPostFrameCallback((_) => _initializeGame());
  }

  Future<void> _initializeGame() async {
    // Previene múltiples inicializaciones.
    if (_isInitializing || !mounted) return;
    setState(() => _isInitializing = true);

    final provider = context.read<CaidaProvider>();
    final firebaseService = context.read<FirebaseService>();

    final restored = await provider.restoreGameFromFirebase(firebaseService);

    if (!restored && mounted) {
      provider.newGame(fullReset: true);
      if (provider.logic.roundStarter == 'player') {
        final choice = await _showInitialChoiceDialog();
        if (mounted)
          provider.initialChoice(
            choice,
            firebaseService,
          ); // Asegúrate de pasar ambos argumentos requeridos
      } else {
        provider.initialChoice(
          provider.logic.botRandomChoice(),
          firebaseService,
        );
      }
      if (mounted) provider.persistGameState(firebaseService);
    }
  }

  Future<String> _showInitialChoiceDialog() async {
    final choice = await showDialog<String>(
      context: context,
      barrierDismissible: false,
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
    return choice ?? 'asc';
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CaidaProvider>();
    final firebaseService = context.read<FirebaseService>();
    final isWideLayout = MediaQuery.of(context).size.width > 1000;
    final cardWidth = isWideLayout ? 100.0 : 72.0;
    final cardHeight = isWideLayout ? 150.0 : 108.0;

    // Listener para el fin del juego.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (provider.gameWinner != null &&
          ModalRoute.of(context)?.isCurrent == true) {
        showGameOverDialog(
          context: context,
          winner: provider.gameWinner!,
          onNewGame: () {
            Navigator.of(context).pop();
            provider.newGame(fullReset: true);
            _initializeGame();
          },
          onExit: () {
            Navigator.of(
              context,
            ).popUntil((route) => route.settings.name == '/lobby');
          },
        );
      }
    });

    // Si el juego no está listo (cargando desde Firebase), muestra un loader.
    if (!provider.isGameReady) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Caída Venezolana'),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Text(
                'Tú: ${provider.logic.playerScore} | Bot: ${provider.logic.opponentScore}',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Row(
        children: [
          if (isWideLayout) const LogPanel(),
          Expanded(
            child: Stack(
              key: _centerStackKey,
              children: [
                Column(
                  children: [
                    OpponentHand(
                      cardWidth: cardWidth,
                      cardHeight: cardHeight,
                      areaKey: _centerStackKey,
                    ),
                    TableBoard(
                      key: _tableKey,
                      cardWidth: cardWidth,
                      cardHeight: cardHeight,
                    ),
                    PlayerHand(
                      cardWidth: cardWidth,
                      cardHeight: cardHeight,
                      centerStackKey: _centerStackKey,
                      tableKey: _tableKey,
                      fxController: _fxController,
                    ),
                  ],
                ),
                FxOverlay(controller: _fxController),
              ],
            ),
          ),
          if (isWideLayout)
            ScorePanel(
              onNewGame: () {
                provider.newGame(fullReset: true);
                _initializeGame();
              },
              onExit: () => Navigator.of(context).pop(),
            ),
        ],
      ),
      bottomNavigationBar: isWideLayout
          ? null
          : BottomActionPanel(
              onNewGame: () {
                provider.newGame(fullReset: true);
                _initializeGame();
              },
            ),
    );
  }
}
