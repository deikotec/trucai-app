// src/lobby/screens/lobby_screen.dart
// El Lobby es la pantalla principal después de iniciar sesión.
// Desde aquí, el usuario puede seleccionar a qué juego quiere entrar.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/firebase_service.dart';

class LobbyScreen extends StatelessWidget {
  const LobbyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final firebaseService = context.watch<FirebaseService>();
    // Obtiene el nombre del usuario a partir de su email para un saludo personalizado.
    final displayName =
        firebaseService.user?.email?.split('@').first ?? 'Jugador';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Casino Online'),
        actions: [
          // Botón para cerrar sesión.
          IconButton(
            tooltip: 'Cerrar sesión',
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await context.read<FirebaseService>().signOut();
              // Navega de vuelta a la pantalla de autenticación después de cerrar sesión.
              // El 'mounted' check es una buena práctica para evitar errores si el widget ya no está en el árbol.
              if (context.mounted) {
                Navigator.of(context).pushReplacementNamed('/auth');
              }
            },
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Saludo personalizado al usuario.
                Text(
                  '¡Bienvenido, $displayName!',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 16),
                Text(
                  'Elige un juego para comenzar',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 32),
                // Contenedor de los botones de selección de juego.
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  alignment: WrapAlignment.center,
                  children: [
                    // Botón para iniciar el juego de "Caída".
                    _GameCard(
                      title: 'Caída Venezolana',
                      icon: Icons.style, // Icono representativo de cartas
                      onTap: () =>
                          Navigator.of(context).pushNamed('/games/caida'),
                    ),
                    // Botón deshabilitado para un futuro juego.
                    const _GameCard(
                      title: 'Truco (Próximamente)',
                      icon: Icons.diamond,
                      onTap: null, // null deshabilita el botón
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Widget reutilizable para mostrar las opciones de juego.
class _GameCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback? onTap;

  const _GameCard({required this.title, required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 200,
          height: 120,
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 40,
                color: onTap != null
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey,
              ),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: onTap != null
                      ? Theme.of(context).colorScheme.onSurface
                      : Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
