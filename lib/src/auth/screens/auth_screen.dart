// src/auth/screens/auth_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/firebase_service.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _email = TextEditingController();
  final _pass = TextEditingController();
  bool _isLogin = true;
  String? _error;
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    final fb = context.watch<FirebaseService>();
    if (fb.user != null) {
      WidgetsBinding.instance.addPostFrameCallback((_){
        Navigator.of(context).pushReplacementNamed('/lobby');
      });
    }

    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Card(
            elevation: 8,
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Trucai – Casino de Cartas', style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 16),
                  if (_error != null) ...[
                    Text(_error!, style: const TextStyle(color: Colors.redAccent)),
                    const SizedBox(height: 8),
                  ],
                  TextField(controller: _email, decoration: const InputDecoration(labelText: 'Correo'),),
                  const SizedBox(height: 12),
                  TextField(controller: _pass, decoration: const InputDecoration(labelText: 'Contraseña'), obscureText: true),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _loading ? null : () async {
                        setState(()=>_loading=true);
                        final svc = context.read<FirebaseService>();
                        String? err;
                        if (_isLogin) {
                          err = await svc.signIn(_email.text.trim(), _pass.text);
                        } else {
                          err = await svc.signUp(_email.text.trim(), _pass.text);
                        }
                        setState(()=>_loading=false);
                        if (err != null) setState(()=>_error=err);
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text(_isLogin ? 'Entrar' : 'Registrarse'),
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => setState(()=>_isLogin=!_isLogin),
                    child: Text(_isLogin ? '¿No tienes cuenta? Regístrate' : '¿Ya tienes cuenta? Inicia sesión'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
