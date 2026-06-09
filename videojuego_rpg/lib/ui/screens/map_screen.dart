import 'package:flutter/material.dart';
import 'package:videojuego_rpg/data/services/api_service.dart';
import 'package:videojuego_rpg/ui/screens/inventory_screen.dart';
import 'package:videojuego_rpg/ui/screens/level_one_screen.dart';
import 'package:videojuego_rpg/ui/screens/login_screen.dart';
import 'package:videojuego_rpg/ui/screens/level_two_screen.dart';
import 'package:videojuego_rpg/ui/screens/level_three_screen.dart';
import 'package:videojuego_rpg/ui/screens/level_four_screen.dart';
import 'package:videojuego_rpg/ui/screens/level_five_screen.dart';
import 'package:videojuego_rpg/ui/screens/level_six_screen.dart';
import 'package:videojuego_rpg/ui/screens/level_seven_screen.dart';
import 'package:videojuego_rpg/ui/screens/level_eight_screen.dart';
import 'package:flutter/services.dart';

class MapScreen extends StatefulWidget {
  // era StatelessWidget
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  // Ya no son hardcodeados — vienen de Atlas
  int _maxLevelReached = 1;
  int _totalKeys = 0;
  bool _isLoading = true;
  String _username = '';

  Color _difficultyColor(String difficulty) {
    switch (difficulty) {
      case 'Tutorial':
        return Colors.blueAccent;
      case 'Fácil':
        return Colors.greenAccent;
      case 'Normal':
        return Colors.yellowAccent;
      case 'Difícil':
        return Colors.orangeAccent;
      case 'Muy Difícil':
        return Colors.redAccent;
      case 'Épico':
        return Colors.purpleAccent;
      default:
        return Colors.white;
    }
  }

  final List<String> levelNames = [
    "El Jardín del Despertar",
    "El Paso de los Guardianes",
    "Las Minas de Cristal Vivo",
    "El Bosque de los Susurros",
    "El Mercado del Silencio",
    "La Forja de la Esperanza",
    "El Pantano del Pesar",
    "La Gran Biblioteca de Cristal",
    "La Atalaya del Sacrificio",
    "El Trono del Cisma (Castillo)",
  ];

  List<dynamic> _levels = [];
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        ApiService.getPlayer(),
        ApiService.getLevels(),
      ]);
      setState(() {
        final playerData = results[0] as Map<String, dynamic>;
        _maxLevelReached = playerData['max_level_reached'] ?? 1;
        _totalKeys = playerData['totalKeys'] ?? 0;
        _username = playerData['username'] ?? '';
        _levels = results[1] as List<dynamic>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _showExitDialog();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("FRAGMENTOS DE AETHELGARD"),
              if (_username.isNotEmpty)
                Text(
                  _username,
                  style: const TextStyle(fontSize: 12, color: Colors.white54),
                ),
            ],
          ),
          backgroundColor: const Color(0xFF16213E),
          actions: [
            // Llaves recolectadas (ya lo tenías)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              child: Row(
                children: [
                  const Icon(Icons.vpn_key, color: Color(0xFFE94560), size: 16),
                  const SizedBox(width: 4),
                  Text(
                    '$_totalKeys/9',
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),
            // Inventario (ya lo tenías)
            IconButton(
              icon: const Icon(Icons.backpack, color: Color(0xFFE94560)),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => InventoryScreen()),
              ),
            ),
            // ← AGREGA ESTO (US-TF-4-1)
            IconButton(
              icon: const Icon(Icons.exit_to_app, color: Colors.white54),
              onPressed: () => _showExitDialog(),
            ),
          ],
        ),
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFFE94560)),
              )
            : Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
                  ),
                ),
                child: ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: _levels.length,
                  itemBuilder: (context, index) {
                    final level = _levels[index];
                    final levelNum = level['level_number'] as int;
                    final title = level['title'] as String;
                    final lore = level['lore_snippet'] as String? ?? '';
                    final difficulty = level['difficulty'] as String? ?? '';
                    final isLocked = levelNum > _maxLevelReached;

                    return GestureDetector(
                      onTap: () => _handleLevelTap(context, levelNum, isLocked),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 15),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: isLocked
                              ? Colors.black26
                              : const Color(0xFFE94560).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                            color: isLocked
                                ? Colors.white10
                                : const Color(0xFFE94560),
                            width: 2,
                          ),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: isLocked
                                  ? Colors.grey
                                  : const Color(0xFFE94560),
                              child: Text(
                                '$levelNum',
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title,
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: isLocked
                                          ? Colors.white30
                                          : Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    lore,
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: isLocked
                                          ? Colors.white12
                                          : Colors.white38,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _difficultyColor(
                                            difficulty,
                                          ).withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                          border: Border.all(
                                            color: _difficultyColor(
                                              difficulty,
                                            ).withOpacity(0.5),
                                          ),
                                        ),
                                        child: Text(
                                          difficulty,
                                          style: TextStyle(
                                            fontSize: 9,
                                            color: isLocked
                                                ? Colors.white24
                                                : _difficultyColor(difficulty),
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      if (levelNum < _maxLevelReached)
                                        const Text(
                                          "✓ COMPLETADO",
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: Colors.greenAccent,
                                          ),
                                        ),
                                      if (levelNum == 10 && _totalKeys < 9)
                                        Text(
                                          "Faltan ${9 - _totalKeys} fragmentos",
                                          style: const TextStyle(
                                            fontSize: 10,
                                            color: Color(0xFFE94560),
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              isLocked ? Icons.lock : Icons.play_arrow,
                              color: isLocked ? Colors.white24 : Colors.white,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
      ),
    );
  }

  void _handleLevelTap(BuildContext context, int level, bool isLocked) {
    if (level == 10 && _totalKeys < 9) {
      _showLoreMessage(
        context,
        "EL SELLO DE MALAKOR",
        "Aún te faltan ${9 - _totalKeys} fragmentos de esperanza.",
      );
      return;
    }
    if (isLocked) {
      _showLoreMessage(
        context,
        "CAMINO CERRADO",
        "Debes restaurar los fragmentos anteriores antes de avanzar.",
      );
      return;
    }

    // ← SOLO nivel 1 tiene pantalla por ahora
    if (level == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const LevelOneScreen()),
      ).then((_) => _loadData());
    } else if (level == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const LevelTwoScreen()),
      ).then((_) => _loadData());
    } else if (level == 3) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const LevelThreeScreen()),
      ).then((_) => _loadData());
    } else if (level == 4) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const LevelFourScreen()),
      ).then((_) => _loadData());
    } else if (level == 5) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const LevelFiveScreen()),
      ).then((_) => _loadData());
    } else if (level == 6) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const LevelSixScreen()),
      ).then((_) => _loadData());
    } else if (level == 7) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const LevelSevenScreen()),
      ).then((_) => _loadData());
    } else if (level == 8) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const LevelEightScreen()),
      ).then((_) => _loadData());
    }
  }

  void _showLoreMessage(BuildContext context, String title, String msg) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: Text(title, style: const TextStyle(color: Color(0xFFE94560))),
        content: Text(msg, style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "ENTENDIDO",
              style: TextStyle(color: Color(0xFFE94560)),
            ),
          ),
        ],
      ),
    );
  }

  // US-TF-4-1: Confirmación de salida
  void _showExitDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF16213E),
        title: const Text(
          "¿Abandonar Aethelgard?",
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          "Tu progreso está guardado en la nube. ¿Deseas salir?",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          // No — regresa al mapa
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("NO", style: TextStyle(color: Colors.white54)),
          ),
          // Sí — limpia sesión y cierra (US-TF-4-1)
          TextButton(
            onPressed: () async {
              await ApiService.clearSession(); // limpia SharedPreferences
              if (!mounted) return;
              // ← Para web redirige al login en lugar de cerrar
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false, // elimina todas las pantallas anteriores
              );
            },
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFE94560),
            ),
            child: const Text(
              "SÍ, SALIR",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
