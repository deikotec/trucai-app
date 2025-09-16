// src/games/caida/screens/room/components/bottom_action_panel.dart
// Este es un nuevo widget para la barra de acciones inferior en diseños móviles.

import 'package:flutter/material.dart';

class BottomActionPanel extends StatelessWidget {
  final VoidCallback onNewGame;

  const BottomActionPanel({super.key, required this.onNewGame});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: onNewGame,
                icon: const Icon(Icons.replay),
                label: const Text('Nuevo Juego'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.exit_to_app),
                label: const Text('Salir'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
