import 'package:flutter/material.dart';
import 'package:videojuego_rpg/data/services/api_service.dart';
import 'package:videojuego_rpg/ui/screens/map_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Alterna entre "Registro" y "Login" en la misma pantalla
  bool _isRegistering = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkExistingSession();
  }

  // Si ya hay sesión guardada, salta directo al mapa
  Future<void> _checkExistingSession() async {
    final playerId = await ApiService.getPlayerId();
    if (playerId != null && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MapScreen()),
      );
    }
  }

  Future<void> _handleSubmit() async {
    final username = _usernameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirm = _confirmPasswordController.text.trim();

    if (_isRegistering) {
      // ← DECLARA primero la variable
      final usernameRegex = RegExp(r'^[a-zA-Z0-9]{3,15}$');
      if (!usernameRegex.hasMatch(username)) {
        _showError(
          "El nombre de guerrero debe tener entre 3 y 15 caracteres y solo puede contener letras y números.",
        );
        return;
      }

      if (!email.endsWith('@gmail.com')) {
        _showError(
          "El correo electrónico debe ser una cuenta de Gmail válida (@gmail.com).",
        );
        return;
      }

      final passwordRegex = RegExp(
        r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[^a-zA-Z0-9]).{8,}$',
      );
      if (!passwordRegex.hasMatch(password)) {
        _showError(
          "Usa números, letras minúsculas, mayúsculas y caracteres especiales con un mínimo de 8 caracteres.",
        );
        return;
      }

      if (password != confirm) {
        _showError("Las contraseñas no coinciden.");
        return;
      }
    } else {
      if (email.isEmpty || password.isEmpty) {
        _showError("Por favor llena todos los campos.");
        return;
      }
    }

    setState(() => _isLoading = true);

    try {
      Map<String, dynamic> data;
      if (_isRegistering) {
        data = await ApiService.register(username, email, password);
      } else {
        data = await ApiService.login(email, password);
      }
      await ApiService.saveSession(data['playerId'], data['username']);
      if (!mounted) return;
      _showLoreWelcome(data['username']);
    } catch (e) {
      _showError(e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showLoreWelcome(String username) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF16213E),
        title: Text(
          _isRegistering ? "Vínculo Establecido" : "Bienvenido de Vuelta",
          style: const TextStyle(color: Colors.white),
        ),
        content: Text(
          _isRegistering
              ? "Tu nombre ha sido grabado en los muros de Aethelgard. Despierta, $username."
              : "Los guardianes te recuerdan, $username. Continúa tu misión.",
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const MapScreen()),
              );
            },
            child: const Text(
              "IR AL JARDÍN",
              style: TextStyle(color: Color(0xFFE94560)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: Container(
        padding: const EdgeInsets.all(25.0),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.shield_moon,
                  size: 100,
                  color: Color(0xFFE94560),
                ),
                const SizedBox(height: 20),
                const Text(
                  "NEXUS RPG",
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 4,
                  ),
                ),
                const Text(
                  "Bajo la protección de la Reina",
                  style: TextStyle(
                    color: Colors.white70,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 40),

                // Solo en modo registro
                // Solo en modo registro
                if (_isRegistering) ...[
                  _buildTextField(
                    _usernameController,
                    "Nombre de Guerrero",
                    Icons.person,
                  ),
                  const SizedBox(height: 15),
                ],

                _buildTextField(
                  _emailController,
                  "Correo Electrónico",
                  Icons.email,
                ),
                const SizedBox(height: 15),
                _buildTextField(
                  _passwordController,
                  "Contraseña Sagrada",
                  Icons.lock,
                  obscure: true,
                ),
                const SizedBox(height: 15),

                // ← Campo nuevo solo en registro
                if (_isRegistering) ...[
                  _buildTextField(
                    _confirmPasswordController,
                    "Confirmar contraseña",
                    Icons.lock_outline,
                    obscure: true,
                  ),
                  const SizedBox(height: 15),
                ],

                // Botón principal
                _isLoading
                    ? const CircularProgressIndicator(color: Color(0xFFE94560))
                    : ElevatedButton(
                        onPressed: _handleSubmit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE94560),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 50,
                            vertical: 15,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: Text(
                          _isRegistering ? "CREAR PERFIL" : "ENTRAR AL REINO",
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                const SizedBox(height: 20),

                // Alternar registro / login
                TextButton(
                  onPressed: () =>
                      setState(() => _isRegistering = !_isRegistering),
                  child: Text(
                    _isRegistering
                        ? "¿Ya tienes cuenta? Inicia sesión"
                        : "¿Eres nuevo? Crea tu perfil",
                    style: const TextStyle(color: Colors.white54),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String hint,
    IconData icon, {
    bool obscure = false,
  }) {
    return Center(
      child: SizedBox(
        width: 350,
        child: TextField(
          controller: controller,
          obscureText: obscure,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: Colors.white70),
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.white30),
            filled: true,
            fillColor: Colors.white.withOpacity(0.1),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              vertical: 18,
              horizontal: 20,
            ),
          ),
        ),
      ),
    );
  }
}
