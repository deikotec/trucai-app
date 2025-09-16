// src/games/caida/screens/room/components/game_over_dialog.dart
// Este es un nuevo archivo que contiene la función para mostrar el
// diálogo de fin de partida.

import 'package:flutter/material.dart';

Future<void> showGameOverDialog({
  required BuildContext context,
  required String winner,
  required VoidCallback onNewGame,
  required VoidCallback onExit,
}) async {
  final didPlayerWin = winner == 'player';

  return showDialog<void>(
    context: context,
    barrierDismissible: false, // El usuario debe elegir una opción.
    builder: (BuildContext context) {
      return AlertDialog(
        title: Row(
          children: [
            Icon(
              didPlayerWin ? Icons.emoji_events : Icons.sentiment_dissatisfied,
              color: didPlayerWin ? Colors.amber : Colors.grey,
            ),
            const SizedBox(width: 10),
            Text(didPlayerWin ? '¡Has Ganado!' : 'Has Perdido'),
          ],
        ),
        content: const Text('¿Qué te gustaría hacer ahora?'),
        actions: <Widget>[
          TextButton(child: const Text('Salir'), onPressed: onExit),
          FilledButton(
            child: const Text('Jugar de Nuevo'),
            onPressed: onNewGame,
          ),
        ],
      );
    },
  );
}
