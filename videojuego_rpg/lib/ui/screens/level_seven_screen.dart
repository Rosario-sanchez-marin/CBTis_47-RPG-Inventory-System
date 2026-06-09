import 'package:flutter/material.dart';
import 'dart:async';
import 'package:videojuego_rpg/data/services/api_service.dart';
import 'package:videojuego_rpg/ui/widgets/battle_hotbar.dart';

class LevelSevenScreen extends StatefulWidget {
  const LevelSevenScreen({super.key});

  @override
  State<LevelSevenScreen> createState() => _LevelSevenScreenState();
}

class _LevelSevenScreenState extends State<LevelSevenScreen> {
  int _dialogIndex = 0;
  bool _isCombatActive = false;
  bool gameEnded = false;
  bool _isWalking = false;
  double _playerX = -1.0;

  // --- MIREYA ---
  int mireyaHP = 200;
  int mireyaMaxHP = 200;
  int _turnCounter = 0;

  // --- JUGADOR ---
  int playerHP = 100;
  bool isPlayerTurn = true;
  String combatLog = "¡Mireya, la Plañidera Eterna, emerge de la niebla!";

  // --- ESTADOS DE EFECTOS ---
  bool _jugadorEnNiebla = false; // no puede atacar 1 turno
  bool _jugadorEnvenenado = false; // pierde 5 HP por turno
  int _turnosVeneno = 0; // cuántos turnos quedan de veneno
  bool _flechaEcoActiva = false;
  int _turnosFlechaEco = 0;

  Timer? _mireyaTimer;
  Timer? _venenoTimer;

  // --- HOTBAR ---
  List<Map<String, dynamic>> hotbar = [
    {"name": "", "icon": null, "type": "empty"},
    {"name": "", "icon": null, "type": "empty"},
    {"name": "", "icon": null, "type": "empty"},
  ];
  List<Map<String, dynamic>> _fullInventory = [];

  // --- DIÁLOGOS DE MIREYA ---
  final List<String> _dialogs = [
    "Detente, portador...\nNo temas. Solo quiero que escuches mi historia.",
    "Fui la guardiana de este pantano.\nCuando Malakor corrompió el reino,\nme negué a abandonar mi puesto.",
    "Me prometió que si me quedaba,\nprotegería a los que amaba.\nMentía. Los perdí a todos.",
    "Ahora solo quedo yo...\ny esta tristeza que se ha vuelto\ntan densa como la niebla eterna.",
    "No quiero hacerte daño, portador.\nPero tampoco puedo dejar pasar\na quien podría liberar a Malakor.",
    "Perdóname por lo que está a punto de ocurrir.\nEs la única forma que me queda\nde mantener mi promesa rota.",
  ];

  @override
  void initState() {
    super.initState();
    _loadHotbar();
  }

  @override
  void dispose() {
    _mireyaTimer?.cancel();
    _venenoTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadHotbar() async {
    try {
      await ApiService.resetHp(100);
      final player = await ApiService.getPlayer();
      final inventory = await ApiService.getInventory();
      setState(() {
        playerHP = (player['stats']?['hp'] as int? ?? 100).clamp(0, 100);
        _fullInventory = List<Map<String, dynamic>>.from(inventory);
        hotbar = [
          inventory.any((i) => i['type'] == 'weapon')
              ? {
                  "name": inventory.any((i) => i['item_id'] == 'hoja_reforzada')
                      ? "Hoja Ref."
                      : "Espada",
                  "icon": inventory.any((i) => i['item_id'] == 'hoja_reforzada')
                      ? Icons.auto_fix_high
                      : Icons.colorize,
                  "type": "weapon",
                  "_id": inventory.firstWhere(
                    (i) => i['type'] == 'weapon',
                  )['_id'],
                }
              : {"name": "", "icon": null, "type": "empty"},
          inventory.any(
                (i) =>
                    i['type'] == 'consumable' &&
                    i['item_id'] != 'esencia_glacial' &&
                    i['item_id'] != 'flecha_eco' &&
                    i['item_id'] != 'frasco_nostalgia' &&
                    i['item_id'] != 'esencia_pesar',
              )
              ? {
                  "name": "Poción",
                  "icon": Icons.health_and_safety,
                  "type": "heal",
                  "_id": inventory.firstWhere(
                    (i) =>
                        i['type'] == 'consumable' &&
                        i['item_id'] != 'esencia_glacial' &&
                        i['item_id'] != 'flecha_eco' &&
                        i['item_id'] != 'frasco_nostalgia' &&
                        i['item_id'] != 'esencia_pesar',
                  )['_id'],
                }
              : {"name": "", "icon": null, "type": "empty"},
          inventory.any((i) => i['item_id'] == 'esencia_glacial')
              ? {
                  "name": "Esencia",
                  "icon": Icons.ac_unit,
                  "type": "freeze",
                  "_id": inventory.firstWhere(
                    (i) => i['item_id'] == 'esencia_glacial',
                  )['_id'],
                }
              : {"name": "", "icon": null, "type": "empty"},
        ];
      });
    } catch (e) {
      debugPrint('Error cargando hotbar: $e');
    }
  }

  void _nextDialog() {
    setState(() {
      if (_dialogIndex < _dialogs.length - 1)
        _dialogIndex++;
      else
        _startWalking();
    });
  }

  void _startWalking() {
    setState(() {
      _isWalking = true;
      _playerX = -1.0;
    });
    Future.delayed(
      const Duration(milliseconds: 50),
      () => setState(() => _playerX = 0.0),
    );
    Future.delayed(const Duration(seconds: 2), _showEnemyEncounter);
  }

  void _showEnemyEncounter() {
    setState(
      () => combatLog =
          "¡Mireya eleva sus manos!\n¡La niebla del pantano cobra vida!",
    );
    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        _isWalking = false;
        _isCombatActive = true;
      });
      _startMireyaAI();
    });
  }

  // --- IA DE MIREYA ---
  void _startMireyaAI() {
    _mireyaTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (gameEnded || !_isCombatActive) {
        timer.cancel();
        return;
      }

      _turnCounter++;

      // Cada 8 turnos: TORMENTA DEL PESAR (todas las mecánicas juntas)
      if (_turnCounter % 1 == 0) {
        _tormentaDelPesar();
        return;
      }

      // Prioridad: niebla > veneno > absorción > ataque normal
      if (_turnCounter % 4 == 0) {
        _aplicarNiebla();
      } else if (_turnCounter % 2 == 0) {
        _aplicarVeneno();
      } else if (_turnCounter % 3 == 0) {
        _mireyaAbsorcion();
      } else {
        _mireyaAtaqueNormal();
      }
    });
  }

  // --- MECÁNICAS DE MIREYA ---
  void _mireyaAtaqueNormal() {
    if (gameEnded) return;
    setState(() {
      int damage = 12 + (DateTime.now().millisecond % 10);
      combatLog = "😢 ¡Mireya llora y sus lágrimas te queman! -$damage HP";
      playerHP = (playerHP - damage).clamp(0, 100);
      if (playerHP <= 0) _endGame(false);
    });
    ApiService.resetHp(playerHP).catchError((_) {});
  }

  void _aplicarNiebla() {
    if (gameEnded) return;
    setState(() {
      _jugadorEnNiebla = true;
      int damage = 10;
      playerHP = (playerHP - damage).clamp(0, 100);
      combatLog =
          "🌫️ ¡La niebla del pesar te envuelve!\n-$damage HP y pierdes tu próximo turno.";
      if (playerHP <= 0) _endGame(false);
    });
    ApiService.resetHp(playerHP).catchError((_) {});
  }

  void _aplicarVeneno() {
    if (gameEnded) return;
    setState(() {
      _jugadorEnvenenado = true;
      _turnosVeneno = 3;
      combatLog =
          "☠️ ¡Las aguas del pantano te envenenan!\nPerderás 5 HP por turno durante 3 turnos.";
    });
    _iniciarVeneno();
  }

  void _iniciarVeneno() {
    _venenoTimer?.cancel();
    _venenoTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (gameEnded || !_jugadorEnvenenado) {
        timer.cancel();
        return;
      }
      setState(() {
        playerHP = (playerHP - 5).clamp(0, 100);
        _turnosVeneno--;
        if (_turnosVeneno > 0) {
          combatLog =
              "☠️ El veneno del pantano te corroe... -5 HP ($_turnosVeneno turnos restantes)";
        } else {
          _jugadorEnvenenado = false;
          combatLog = "✨ El veneno ha desaparecido.";
          timer.cancel();
        }
        if (playerHP <= 0) _endGame(false);
      });
      ApiService.resetHp(playerHP).catchError((_) {});
    });
  }

  void _mireyaAbsorcion() {
    if (gameEnded) return;
    final hpAntes = mireyaHP;
    setState(() {
      mireyaHP = (mireyaHP + 8).clamp(0, mireyaMaxHP);
      final recuperado = mireyaHP - hpAntes;
      combatLog =
          "💧 ¡Mireya absorbe la tristeza del pantano!\n+$recuperado HP recuperados";
    });
  }

  void _tormentaDelPesar() {
    if (gameEnded) return;
    setState(() {
      // Niebla
      _jugadorEnNiebla = true;
      // Veneno
      _jugadorEnvenenado = true;
      _turnosVeneno = 3;
      // Absorción
      mireyaHP = (mireyaHP + 8).clamp(0, mireyaMaxHP);
      // Daño directo
      int damage = 15;
      playerHP = (playerHP - damage).clamp(0, 100);
      combatLog =
          "💀 ¡MIREYA LIBERA TODA SU TRISTEZA!\n¡La tormenta del pesar te consume! -$damage HP\n¡Estás envenenado y en la niebla!";
      if (playerHP <= 0) _endGame(false);
    });
    ApiService.resetHp(playerHP).catchError((_) {});
    _iniciarVeneno();
  }

  // --- ATAQUE DEL JUGADOR ---
  void _playerAttack() {
    if (!isPlayerTurn || gameEnded) return;

    // Si está en niebla, falla el ataque
    if (_jugadorEnNiebla) {
      setState(() {
        _jugadorEnNiebla = false;
        combatLog = "🌫️ ¡La niebla nubla tu visión!\n¡Tu ataque falla!";
        isPlayerTurn = false;
      });
      Future.delayed(
        const Duration(milliseconds: 1200),
        () => setState(() => isPlayerTurn = true),
      );
      return;
    }

    setState(() {
      int baseDamage =
          _fullInventory.any((i) => i['item_id'] == 'hoja_reforzada') ? 23 : 15;
      int bonus = _flechaEcoActiva ? 5 : 0;
      int damage = baseDamage + (DateTime.now().millisecond % 10) + bonus;
      mireyaHP = (mireyaHP - damage).clamp(0, mireyaMaxHP);

      String log = "⚔️ ¡Golpeas a Mireya! -$damage HP";
      if (_flechaEcoActiva) {
        _turnosFlechaEco--;
        if (_turnosFlechaEco <= 0) {
          _flechaEcoActiva = false;
          log += "\n🏹 Flecha del Eco se ha agotado.";
        }
      }
      combatLog = log;
      isPlayerTurn = false;
      if (mireyaHP <= 0) {
        _endGame(true);
        return;
      }
    });
    Future.delayed(
      const Duration(milliseconds: 1200),
      () => setState(() => isPlayerTurn = true),
    );
  }

  // --- USAR ÍTEM ---
  void _useItem(Map<String, dynamic> item) {
    if (!isPlayerTurn || gameEnded) return;
    switch (item["type"]) {
      case "weapon":
        _playerAttack();
        break;
      case "heal":
        _usePocion(item);
        break;
      case "shield":
        _useEscudo(item);
        break;
      case "freeze":
        _useEsenciaGlacial(item);
        break;
      case "consumable":
        _useConsumible(item);
        break;
    }
  }

  Future<void> _usePocion(Map<String, dynamic> item) async {
    if (playerHP >= 100) {
      setState(() => combatLog = "¡Ya tienes el HP al máximo!");
      return;
    }
    try {
      final result = await ApiService.useItem(item['_id']);
      setState(() {
        playerHP = (result['newHp'] as int).clamp(0, 100);
        combatLog = "🧪 ¡Bebiste una poción! +${result['healed']} HP";
        final index = hotbar.indexWhere((h) => h['_id'] == item['_id']);
        if (index != -1)
          hotbar[index] = {"name": "", "icon": null, "type": "empty"};
        _fullInventory.removeWhere((i) => i['_id'] == item['_id']);
        isPlayerTurn = false;
      });
      Future.delayed(
        const Duration(milliseconds: 1000),
        () => setState(() => isPlayerTurn = true),
      );
    } catch (e) {
      setState(() => combatLog = "Error al usar poción: $e");
    }
  }

  void _useEscudo(Map<String, dynamic> item) {
    setState(() {
      combatLog =
          "🛡️ ¡Alzas el Fragmento de Manto!\nEl próximo golpe será absorbido.";
      isPlayerTurn = false;
    });
    Future.delayed(
      const Duration(milliseconds: 1000),
      () => setState(() => isPlayerTurn = true),
    );
  }

  Future<void> _useEsenciaGlacial(Map<String, dynamic> item) async {
    try {
      await ApiService.useItem(item['_id']);
      setState(() {
        _mireyaTimer?.cancel();
        _venenoTimer?.cancel();
        _jugadorEnvenenado = false;
        _turnosVeneno = 0;
        combatLog =
            "❄️ ¡La Esencia Glacial congela la niebla!\n¡Mireya está congelada y el veneno se detiene!";
        final index = hotbar.indexWhere((h) => h['_id'] == item['_id']);
        if (index != -1)
          hotbar[index] = {"name": "", "icon": null, "type": "empty"};
        _fullInventory.removeWhere((i) => i['_id'] == item['_id']);
        isPlayerTurn = false;
      });
      await Future.delayed(const Duration(seconds: 4));
      if (!gameEnded) {
        setState(() {
          combatLog = "🌫️ ¡La niebla de Mireya vuelve a espesarse!";
          isPlayerTurn = true;
        });
        _startMireyaAI();
      }
    } catch (e) {
      setState(() => combatLog = "No puedes congelar ahora.");
    }
  }

  Future<void> _useConsumible(Map<String, dynamic> item) async {
    if (item['item_id'] == 'flecha_eco') {
      try {
        await ApiService.useItem(item['_id']);
        setState(() {
          _flechaEcoActiva = true;
          _turnosFlechaEco = 2;
          combatLog = "🏹 ¡Flecha del Eco activa! +5 daño por 2 turnos.";
          final index = hotbar.indexWhere((h) => h['_id'] == item['_id']);
          if (index != -1)
            hotbar[index] = {"name": "", "icon": null, "type": "empty"};
          _fullInventory.removeWhere((i) => i['_id'] == item['_id']);
          isPlayerTurn = false;
        });
        Future.delayed(
          const Duration(milliseconds: 1000),
          () => setState(() => isPlayerTurn = true),
        );
      } catch (e) {
        setState(() => combatLog = "No puedes usar eso ahora.");
      }
    }
  }

  // --- FIN DEL JUEGO ---
  void _endGame(bool won) async {
    _mireyaTimer?.cancel();
    _venenoTimer?.cancel();
    setState(() => gameEnded = true);
    bool llaveOtorgada = false;
    if (won) {
      try {
        final result = await ApiService.saveProgress(
          nivelCompletado: 7,
          xpGanado: 750,
          nuevaLlave: true,
        );
        llaveOtorgada = result['llaveOtorgada'] ?? false;
        if (llaveOtorgada)
          await ApiService.addItem({
            'name': 'Llave del Pantano',
            'type': 'key',
            'item_id': 'key_07',
          });
        final inventory = await ApiService.getInventory();
        if (!inventory.any((i) => i['item_id'] == 'esencia_pesar')) {
          await ApiService.addItem({
            'name': 'Esencia del Pesar',
            'type': 'consumable',
            'item_id': 'esencia_pesar',
            'stats': {'poison_turns': 3, 'poison_damage': 5},
          });
        }
      } catch (e) {
        debugPrint('Error guardando progreso: $e');
      }
    }
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: Text(
          won ? "¡MIREYA HA SIDO LIBERADA!" : "HAS CAÍDO EN COMBATE",
          style: TextStyle(
            color: won ? Colors.tealAccent : Colors.redAccent,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              won ? Icons.water : Icons.dangerous,
              size: 80,
              color: won ? Colors.tealAccent : Colors.redAccent,
            ),
            const SizedBox(height: 15),
            Text(
              won
                  ? "Las lágrimas de Mireya se secan por primera vez.\nEl pantano respira en silencio."
                  : "La niebla del pesar te ha consumido.\nMireya sigue llorando eternamente.",
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, height: 1.5),
            ),
            if (won) ...[
              const SizedBox(height: 15),
              Text(
                llaveOtorgada
                    ? "+750 XP  •  +1 Llave del Pantano  •  Esencia del Pesar"
                    : "+750 XP  •  Esencia del Pesar  •  (llave ya obtenida)",
                style: const TextStyle(
                  color: Colors.tealAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
        actions: [
          Center(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: won ? Colors.teal[800] : Colors.red,
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 15,
                ),
              ),
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: Text(
                won ? "RECLAMAR RECOMPENSA" : "REINTENTAR DESDE EL MAPA",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: NetworkImage(
              "https://images.unsplash.com/photo-1511497584788-876760111969?q=80&w=1000&auto=format&fit=crop",
            ),
            fit: BoxFit.cover,
          ),
        ),
        child: Stack(
          children: [
            Container(color: Colors.teal.withOpacity(0.2)),
            if (_isWalking)
              AnimatedAlign(
                duration: const Duration(seconds: 2),
                alignment: Alignment(_playerX, 0.5),
                child: _playerSprite(),
              ),
            if (_isCombatActive) _buildCombatUI(),
            if (!_isWalking && !_isCombatActive) _buildLoreUI(),
          ],
        ),
      ),
    );
  }

  Widget _buildLoreUI() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        GestureDetector(
          onTap: _nextDialog,
          child: Container(
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(20),
            height: 200,
            decoration: BoxDecoration(
              color: const Color(0xFF16213E).withOpacity(0.9),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(color: Colors.tealAccent, width: 3),
              boxShadow: [
                BoxShadow(color: Colors.teal.withOpacity(0.3), blurRadius: 15),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "MIREYA",
                  style: TextStyle(
                    color: Colors.tealAccent,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
                const Divider(color: Colors.white24),
                const SizedBox(height: 10),
                Expanded(
                  child: Text(
                    _dialogs[_dialogIndex],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),
                ),
                const Align(
                  alignment: Alignment.bottomRight,
                  child: Icon(Icons.touch_app, color: Colors.white54),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCombatUI() {
    return Column(
      children: [
        const SizedBox(height: 20),
        _buildMireyaCard(),
        const SizedBox(height: 8),
        // Indicadores de estado activos
        if (_jugadorEnvenenado || _jugadorEnNiebla)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_jugadorEnvenenado)
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.greenAccent),
                    ),
                    child: Text(
                      "☠️ Veneno ($_turnosVeneno)",
                      style: const TextStyle(
                        color: Colors.greenAccent,
                        fontSize: 11,
                      ),
                    ),
                  ),
                if (_jugadorEnNiebla)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white38),
                    ),
                    child: const Text(
                      "🌫️ En niebla",
                      style: TextStyle(color: Colors.white54, fontSize: 11),
                    ),
                  ),
              ],
            ),
          ),
        const Spacer(),
        _playerSprite(),
        const SizedBox(height: 10),
        _buildCombatLogBox(),
        const Spacer(),
        _buildStatusCard(
          "PORTADOR DE LA PROMESA",
          playerHP,
          100,
          Colors.greenAccent,
          Icons.person,
        ),
        BattleHotbar(
          hotbar: hotbar,
          inventory: _fullInventory,
          active: isPlayerTurn && !gameEnded,
          onAttack: _playerAttack,
          onItemUsed: _useItem,
        ),
      ],
    );
  }

  Widget _buildMireyaCard() {
    double progress = (mireyaHP / mireyaMaxHP).clamp(0.0, 1.0);
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.water, color: Colors.tealAccent, size: 20),
            const SizedBox(width: 8),
            Text(
              "MIREYA — PLAÑIDERA ETERNA${_turnCounter > 0 ? ' (turno ${_turnCounter % 8 == 0 ? 8 : _turnCounter % 8}/8)' : ''}",
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 300,
              height: 20,
              decoration: BoxDecoration(
                color: Colors.black45,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            Positioned(
              left: 0,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                width: 300 * progress,
                height: 20,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.teal.withOpacity(0.5), Colors.tealAccent],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            Text(
              "$mireyaHP / $mireyaMaxHP",
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusCard(
    String name,
    int current,
    int total,
    Color color,
    IconData icon,
  ) {
    double progress = (current / total).clamp(0.0, 1.0);
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Text(
              name,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 300,
              height: 20,
              decoration: BoxDecoration(
                color: Colors.black45,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            Positioned(
              left: 0,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                width: 300 * progress,
                height: 20,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color.withOpacity(0.5), color],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            Text(
              "$current / $total",
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCombatLogBox() {
    Color borderColor = _jugadorEnvenenado
        ? Colors.greenAccent
        : _jugadorEnNiebla
        ? Colors.white38
        : Colors.white12;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
      margin: const EdgeInsets.symmetric(horizontal: 30),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: borderColor),
      ),
      child: Text(
        combatLog,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontStyle: FontStyle.italic,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _playerSprite() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 20, height: 5, color: Colors.grey[800]),
        Container(width: 20, height: 15, color: Colors.orange[200]),
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(width: 4, height: 25, color: Colors.grey),
            Container(width: 26, height: 40, color: Colors.blueGrey[700]),
          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 10, height: 15, color: Colors.brown[700]),
            const SizedBox(width: 4),
            Container(width: 10, height: 15, color: Colors.brown[700]),
          ],
        ),
      ],
    );
  }
}
