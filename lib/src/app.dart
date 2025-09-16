// src/main_app.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

import 'core/services/firebase_service.dart';
import 'auth/screens/auth_screen.dart';
import 'lobby/screens/lobby_screen.dart';
import 'games/caida/screens/room/caida_game_screen.dart';

// import 'firebase_options.dart'; // si usas flutterfire configure

const String _apiKey = "AIzaSyCbligeo6IJw5qKhon5z_LzqGE6x-iSrf4";
const String _authDomain = "caida-game.firebaseapp.com";
const String _projectId = "caida-game";
const String _storageBucket = "caida-game.appspot.com";
const String _messagingSenderId = "707030975610";
const String _appId = "1:707030975610:web:e719a16b40d49008d0e7c3";

Future<void> _initFirebase() async {
  try {
    await Firebase.initializeApp(
      // options: DefaultFirebaseOptions.currentPlatform,
      options: FirebaseOptions(
        apiKey: _apiKey,
        appId: _appId,
        messagingSenderId: _messagingSenderId,
        projectId: _projectId,
        authDomain: _authDomain,
        storageBucket: _storageBucket,
      ),
    );
  } catch (_) {}
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _initFirebase();
  runApp(const TrucaiApp());
}

class TrucaiApp extends StatelessWidget {
  const TrucaiApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => FirebaseService()..init()),
      ],
      child: MaterialApp(
        title: 'Trucai – Casino de Cartas',
        theme: ThemeData(
          brightness: Brightness.dark,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF4338CA),
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
          fontFamily: 'Poppins',
        ),
        debugShowCheckedModeBanner: false,
        initialRoute: '/auth',
        routes: {
          '/auth': (_) => const AuthScreen(),
          '/lobby': (_) => const LobbyScreen(),
          '/games/caida': (_) => const CaidaGameScreen(),
        },
      ),
    );
  }
}
