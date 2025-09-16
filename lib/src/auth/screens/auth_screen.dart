// src/auth/screens/auth_screen.dart
// Esta pantalla maneja el inicio de sesión y el registro de usuarios
// utilizando el servicio de Firebase.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/firebase_service.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  // Controladores para los campos de texto de email y contraseña.
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // Variables de estado del widget.
  bool _isLogin = true; // Determina si el formulario es para login o registro.
  String? _error; // Almacena mensajes de error.
  bool _loading =
      false; // Controla el estado de carga para deshabilitar botones.

  // Función para manejar el proceso de autenticación.
  Future<void> _handleAuth() async {
    // Si ya está cargando, no hacer nada.
    if (_loading) return;

    // Oculta el teclado.
    FocusScope.of(context).unfocus();

    // Actualiza el estado a "cargando".
    setState(() {
      _loading = true;
      _error = null;
    });

    final firebaseService = context.read<FirebaseService>();
    String? errorResult;

    // Llama al método de signIn o signUp según el estado de _isLogin.
    if (_isLogin) {
      errorResult = await firebaseService.signIn(
        _emailController.text.trim(),
        _passwordController.text,
      );
    } else {
      errorResult = await firebaseService.signUp(
        _emailController.text.trim(),
        _passwordController.text,
      );
    }

    // Actualiza el estado finalizando la carga.
    setState(() => _loading = false);

    // Si hubo un error, lo muestra en la UI.
    if (errorResult != null && mounted) {
      setState(() => _error = errorResult);
    }
  }

  @override
  void dispose() {
    // Libera los recursos de los controladores al destruir el widget.
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Escucha los cambios en el servicio de Firebase.
    final firebaseService = context.watch<FirebaseService>();

    // Si el usuario ya está autenticado, navega al lobby.
    // Se usa addPostFrameCallback para evitar errores de setState durante el build.
    if (firebaseService.user != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/lobby');
        }
      });
      // Muestra un loader mientras se redirige para evitar un frame vacío.
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      // Fondo con un gradiente sutil para mejorar la estética.
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.background,
              Theme.of(context).colorScheme.surface.withOpacity(0.5),
            ],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Trucai Casino',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 24),
                      // Muestra el mensaje de error si existe.
                      if (_error != null) ...[
                        Text(
                          _error!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                      ],
                      // Campo de texto para el email.
                      TextField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: 'Correo Electrónico',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 12),
                      // Campo de texto para la contraseña.
                      TextField(
                        controller: _passwordController,
                        decoration: const InputDecoration(
                          labelText: 'Contraseña',
                          border: OutlineInputBorder(),
                        ),
                        obscureText: true,
                        onSubmitted: (_) => _handleAuth(),
                      ),
                      const SizedBox(height: 24),
                      // Botón principal de acción.
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: _handleAuth,
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          // Muestra un indicador de carga si _loading es true.
                          child: _loading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(_isLogin ? 'ENTRAR' : 'REGISTRARSE'),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Botón para cambiar entre login y registro.
                      TextButton(
                        onPressed: () => setState(() => _isLogin = !_isLogin),
                        child: Text(
                          _isLogin
                              ? '¿No tienes cuenta? Regístrate'
                              : '¿Ya tienes cuenta? Inicia sesión',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
