// src/lobby/screens/lobby_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/firebase_service.dart';

class LobbyScreen extends StatelessWidget {
  const LobbyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final fb = context.watch<FirebaseService>();
    final name = fb.user?.email?.split('@').first ?? 'Jugador';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trucai – Lobby'),
        actions: [
          IconButton(
            tooltip: 'Cerrar sesión',
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await context.read<FirebaseService>().signOut();
              if (context.mounted) Navigator.of(context).pushReplacementNamed('/auth');
            },
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Hola $name', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              const Text('Elige un juego para comenzar'),
              const SizedBox(height: 20),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.sports_esports),
                    label: const Text('Jugar Caída'),
                    onPressed: ()=>Navigator.of(context).pushNamed('/games/caida'),
                  ),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.upcoming),
                    label: const Text('Truco Ajiley (próximamente)'),
                    onPressed: null,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
