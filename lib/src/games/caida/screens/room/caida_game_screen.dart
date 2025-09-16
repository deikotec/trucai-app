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
import '../../../common/fx/fx_controller.dart';
import '../../../common/fx/fx_overlay.dart';

class CaidaGameScreen extends StatefulWidget {
  const CaidaGameScreen({super.key});

  @override
  State<CaidaGameScreen> createState() => _CaidaGameScreenState();
}

class _CaidaGameScreenState extends State<CaidaGameScreen> {
  // GlobalKeys para obtener el tamaño y posición de los widgets en el árbol.
  final GlobalKey _centerStackKey =
      GlobalKey(); // Para el sistema de coordenadas de los efectos.
  final GlobalKey _tableKey =
      GlobalKey(); // Para el destino del "vuelo" de la carta.
  final FxController _fxController = FxController();
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    // Se inicializa el juego después de que el primer frame sea renderizado.
    WidgetsBinding.instance.addPostFrameCallback((_) => _initializeGame());
  }

  // Lógica de inicialización del juego.
  Future<void> _initializeGame() async {
    if (!mounted || _isInitialized) return;
    setState(() => _isInitialized = true);

    final provider = context.read<CaidaProvider>();
    final firebaseService = context.read<FirebaseService>();

    // Intenta restaurar una partida en progreso desde Firestore.
    final gameRestored = await provider.restoreGameFromFirebase(
      firebaseService,
    );

    // Si no hay partida para restaurar, empieza una nueva.
    if (!gameRestored) {
      provider.newGame(fullReset: true);
      // Muestra el diálogo de elección inicial si el jugador es "mano".
      if (provider.logic.roundStarter == 'player') {
        final choice = await _showInitialChoiceDialog();
        provider.initialChoice(choice);
      } else {
        // El bot elige aleatoriamente.
        provider.initialChoice(provider.logic.botRandomChoice());
      }
    }

    // Persiste el estado inicial del juego.
    provider.persistGameState(firebaseService);
  }

  // Muestra el diálogo para que el jugador elija el orden de la mesa.
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
    return choice ??
        'asc'; // Devuelve 'asc' por defecto si el diálogo se cierra.
  }

  @override
  Widget build(BuildContext context) {
    // Determina el layout basado en el ancho de la pantalla.
    final isWideLayout = MediaQuery.of(context).size.width > 1000;
    final cardWidth = isWideLayout ? 100.0 : 72.0;
    final cardHeight = isWideLayout ? 150.0 : 108.0;

    return ChangeNotifierProvider(
      create: (_) => CaidaProvider(),
      child: Consumer<CaidaProvider>(
        builder: (context, provider, child) {
          // Si el juego no está inicializado, muestra un loader.
          if (!provider.isGameReady) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          return Scaffold(
            appBar: AppBar(
              title: const Text('Caída Venezolana'),
              actions: [
                // Muestra el puntaje en la AppBar.
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
                // El panel de logs es visible solo en pantallas anchas.
                if (isWideLayout) const LogPanel(),
                // Zona central del juego.
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
                            key: _tableKey, // Key para la mesa.
                            cardWidth: cardWidth,
                            cardHeight: cardHeight,
                          ),
                          PlayerHand(
                            cardWidth: cardWidth,
                            cardHeight: cardHeight,
                            centerStackKey: _centerStackKey,
                            tableKey: _tableKey,
                            fxController:
                                _fxController, // Fix: agrega el parámetro requerido
                          ),
                        ],
                      ),
                      // Overlay para los efectos visuales (vuelo de cartas).
                      FxOverlay(controller: _fxController),
                    ],
                  ),
                ),
                // Panel de puntaje y acciones en pantallas anchas.
                if (isWideLayout)
                  ScorePanel(
                    onNewGame: () {
                      final provider = context.read<CaidaProvider>();
                      provider.newGame(fullReset: true);
                    },
                    onExit: () {
                      Navigator.of(context).pop();
                    },
                  ),
              ],
            ),
            // Barra de navegación inferior para acciones en pantallas pequeñas.
            bottomNavigationBar: isWideLayout
                ? null
                : BottomActionPanel(
                    onNewGame: () {
                      final provider = context.read<CaidaProvider>();
                      provider.newGame(fullReset: true);
                    },
                  ),
          );
        },
      ),
    );
  }
}
