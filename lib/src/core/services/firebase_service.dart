// src/core/services/firebase_service.dart
// Este servicio centraliza toda la interacción con Firebase (Auth y Firestore),
// actuando como una capa de abstracción para el resto de la aplicación.

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class FirebaseService extends ChangeNotifier {
  // Instancias de los servicios de Firebase.
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  User? _user;
  User? get user => _user;

  // Inicializa el servicio y se suscribe a los cambios de estado de autenticación.
  void init() {
    _auth.authStateChanges().listen((firebaseUser) {
      _user = firebaseUser;
      // Notifica a los listeners (como la UI) que el usuario ha cambiado.
      notifyListeners();
    });
  }

  // Método para iniciar sesión con email y contraseña.
  Future<String?> signIn(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return null; // Retorna null si el inicio de sesión es exitoso.
    } on FirebaseAuthException catch (e) {
      // Mapea el código de error de Firebase a un mensaje legible.
      return _mapAuthError(e.code);
    } catch (e) {
      return 'Error desconocido: $e';
    }
  }

  // Método para registrar un nuevo usuario.
  Future<String?> signUp(String email, String password) async {
    try {
      await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      // Aquí podrías crear un documento de usuario en Firestore si es necesario.
      // Ejemplo: await _db.collection('users').doc(cred.user!.uid).set({'email': email, 'createdAt': FieldValue.serverTimestamp()});
      return null; // Retorna null si el registro es exitoso.
    } on FirebaseAuthException catch (e) {
      return _mapAuthError(e.code);
    } catch (e) {
      return 'Error desconocido: $e';
    }
  }

  // Método para cerrar sesión.
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Obtiene la referencia a un documento de juego para el usuario actual.
  // Esto permite persistir el estado del juego en Firestore.
  DocumentReference<Map<String, dynamic>> userGameDoc(String gameKey) {
    if (_user == null) {
      throw Exception(
        "Usuario no autenticado. No se puede acceder al estado del juego.",
      );
    }
    final uid = _user!.uid;
    // La ruta sigue la estructura de seguridad definida: artifacts/{appId}/users/{userId}/{collection}/{docId}
    // Usamos 'caida-dev' como appId para este ejemplo.
    return _db
        .collection('artifacts')
        .doc('caida-dev')
        .collection('users')
        .doc(uid)
        .collection(gameKey)
        .doc('gameState');
  }

  // Función privada para mapear códigos de error de Firebase a mensajes en español.
  String _mapAuthError(String code) {
    switch (code) {
      case 'invalid-email':
        return 'El correo electrónico no es válido.';
      case 'user-not-found':
        return 'No se encontró un usuario con ese correo.';
      case 'wrong-password':
        return 'La contraseña es incorrecta.';
      case 'email-already-in-use':
        return 'El correo electrónico ya está en uso.';
      case 'weak-password':
        return 'La contraseña es demasiado débil.';
      case 'operation-not-allowed':
        return 'Operación no permitida.';
      default:
        return 'Error de autenticación. Por favor, inténtelo de nuevo.';
    }
  }
}
