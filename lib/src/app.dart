// src/app.dart
// Este archivo define el widget raíz de la aplicación, MaterialApp,
// configurando el tema, las rutas de navegación y los proveedores de estado.

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

import 'core/services/firebase_service.dart';
import 'auth/screens/auth_screen.dart';
import 'lobby/screens/lobby_screen.dart';
import 'games/caida/screens/room/caida_game_screen.dart';

// Función asíncrona para inicializar Firebase.
// Es crucial que Firebase se inicialice antes de que la app se ejecute.
Future<void> _initFirebase() async {
  try {
    // Si usas 'flutterfire configure', puedes usar DefaultFirebaseOptions.
    // await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

    // Para este caso, usamos la configuración manual para asegurar compatibilidad.
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyCbligeo6IJw5qKhon5z_LzqGE6x-iSrf4", // Tu API Key
        authDomain: "caida-game.firebaseapp.com",
        projectId: "caida-game",
        storageBucket: "caida-game.appspot.com",
        messagingSenderId: "707030975610",
        appId: "1:707030975610:web:e719a16b40d49008d0e7c3",
      ),
    );
  } catch (e) {
    // Imprime un error si la inicialización de Firebase falla.
    debugPrint("Error al inicializar Firebase: $e");
  }
}

// Widget principal que construye la aplicación.
class TrucaiApp extends StatefulWidget {
  const TrucaiApp({super.key});

  @override
  State<TrucaiApp> createState() => _TrucaiAppState();
}

class _TrucaiAppState extends State<TrucaiApp> {
  // Futuro para controlar el estado de la inicialización de Firebase.
  late final Future<void> _firebaseInitialization;

  @override
  void initState() {
    super.initState();
    _firebaseInitialization = _initFirebase();
  }

  @override
  Widget build(BuildContext context) {
    // MultiProvider permite que múltiples proveedores de estado estén disponibles
    // en todo el árbol de widgets.
    return MultiProvider(
      providers: [
        // ChangeNotifierProvider para el servicio de Firebase.
        // Se inicializa aquí para que esté disponible en toda la app.
        ChangeNotifierProvider(create: (_) => FirebaseService()..init()),
      ],
      child: MaterialApp(
        title: 'Trucai – Casino de Cartas',
        // Definición del tema oscuro de la aplicación.
        theme: ThemeData(
          brightness: Brightness.dark,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(
              0xFF4338CA,
            ), // Un morado como color principal
            brightness: Brightness.dark,
            background: const Color(0xFF111827), // Fondo principal oscuro
            surface: const Color(0xFF1F2937), // Superficies como cards
          ),
          useMaterial3: true,
          fontFamily: 'Poppins', // Usamos la fuente Poppins para consistencia
        ),
        debugShowCheckedModeBanner: false,
        // Usamos un FutureBuilder para mostrar un splash screen mientras Firebase inicializa.
        home: FutureBuilder(
          future: _firebaseInitialization,
          builder: (context, snapshot) {
            // Si hay un error, muestra un mensaje de error.
            if (snapshot.hasError) {
              return const Scaffold(
                body: Center(
                  child: Text('Error al conectar con los servicios.'),
                ),
              );
            }
            // Si la conexión es exitosa, muestra la pantalla de autenticación.
            if (snapshot.connectionState == ConnectionState.done) {
              return const AuthScreen();
            }
            // Mientras tanto, muestra un indicador de carga.
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          },
        ),
        // Definición de las rutas nombradas de la aplicación.
        routes: {
          '/auth': (_) => const AuthScreen(),
          '/lobby': (_) => const LobbyScreen(),
          '/games/caida': (_) => const CaidaGameScreen(),
        },
      ),
    );
  }
}
