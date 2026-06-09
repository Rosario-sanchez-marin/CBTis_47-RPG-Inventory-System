import 'package:flutter/material.dart';
import 'package:videojuego_rpg/ui/screens/login_screen.dart'; // Asegúrate de que el nombre coincida con tu proyecto

void main() {
  runApp(const NexusRPG());
}

class NexusRPG extends StatelessWidget {
  const NexusRPG({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nexus RPG - Aethelgard',
      debugShowCheckedModeBanner: false,

      // CONFIGURACIÓN DEL TEMA (Visual del Juego)
      theme: ThemeData(
        useMaterial3: true,
        // 1. Mantenemos el brillo general en oscuro
        brightness: Brightness.dark,

        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFE94560),
          // 2. ¡AQUÍ ESTÁ EL TRUCO!
          // Agregamos esta línea para que el esquema sepa que es para modo oscuro
          brightness: Brightness.dark,

          primary: const Color(0xFFE94560),
          secondary: const Color(0xFF0F3460),
          surface: const Color(0xFF16213E),
        ),

        // ... el resto de tu código (textTheme, elevatedButtonTheme, etc.)
      ),

      // PANTALLA INICIAL (Epic 1 - Login)
      home: const LoginScreen(),
    );
  }
}
