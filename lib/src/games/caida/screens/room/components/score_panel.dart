// src/games/caida/widgets/score_panel.dart
// Panel de resultados con acciones. (sin cambios funcionales mayores)

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/caida_provider.dart';

class ScorePanel extends StatelessWidget {
  final VoidCallback onNewGame;
  final VoidCallback onExit;

  const ScorePanel({super.key, required this.onNewGame, required this.onExit});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<CaidaProvider>();
    return Container(
      width: 260,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.black.withOpacity(0.15)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Resultados',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          _kv('Tú', '${p.logic.playerScore}'),
          _kv('Bot', '${p.logic.opponentScore}'),
          const Divider(),
          _kv('Mano #', '${p.logic.handNumber}'),
          _kv('Capturas (Tú)', '${p.logic.playerCapturedCount}'),
          _kv('Capturas (Bot)', '${p.logic.opponentCapturedCount}'),
          _kv('Turno', p.logic.isPlayerTurn ? 'Tú' : 'Bot'),
          const Spacer(),
          FilledButton.icon(
            onPressed: onNewGame,
            icon: const Icon(Icons.replay),
            label: const Text('Nuevo juego'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: onExit,
            icon: const Icon(Icons.exit_to_app),
            label: const Text('Salir'),
          ),
        ],
      ),
    );
  }

  Widget _kv(String k, String v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(k, style: const TextStyle(color: Colors.white70)),
          Text(v, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
