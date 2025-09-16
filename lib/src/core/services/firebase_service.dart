// src/core/services/firebase_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class FirebaseService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  User? _user;
  User? get user => _user;

  void init() {
    _auth.authStateChanges().listen((u) {
      _user = u;
      notifyListeners();
    });
  }

  Future<String?> signIn(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return null;
    } on FirebaseAuthException catch (e) {
      return _mapAuth(e.code);
    } catch (e) {
      return 'Error desconocido: $e';
    }
  }

  Future<String?> signUp(String email, String password) async {
    try {
      await _auth.createUserWithEmailAndPassword(email: email, password: password);
      return null;
    } on FirebaseAuthException catch (e) {
      return _mapAuth(e.code);
    } catch (e) {
      return 'Error desconocido: $e';
    }
  }

  Future<void> signOut() => _auth.signOut();

  DocumentReference<Map<String, dynamic>> userGameDoc(String gameKey) {
    final uid = _user!.uid;
    return _db
      .collection('artifacts').doc('caida-dev')
      .collection('users').doc(uid)
      .collection(gameKey).doc('gameState');
  }

  String _mapAuth(String code) {
    switch (code) {
      case 'invalid-email': return 'Correo electrónico inválido.';
      case 'user-not-found': return 'Usuario no encontrado.';
      case 'wrong-password': return 'Contraseña incorrecta.';
      case 'email-already-in-use': return 'Este correo ya está registrado.';
      default: return 'Error de autenticación ($code).';
    }
  }
}
