import 'package:flutter/material.dart';
import 'dart:async';
import 'package:videojuego_rpg/data/services/api_service.dart';
import 'package:videojuego_rpg/ui/widgets/battle_hotbar.dart';

class LevelFourScreen extends StatefulWidget {
  const LevelFourScreen({super.key});

  @override
  State<LevelFourScreen> createState() => _LevelFourScreenState();
}

class _LevelFourScreenState extends State<LevelFourScreen> {
  int _dialogIndex = 0;
  bool _isCombatActive = false;
  bool gameEnded = false;
  bool _isWalking = false;
  double _playerX = -1.0;
  bool _flechaEcoActiva = false;
  int _turnosFlechaEco = 0;

  int sylvaraHP = 100;
  int _turnCounter = 0;
  bool sylvaraInvisible = false;

  int playerHP = 100;
  bool isPlayerTurn = true;
  String combatLog =
      "¡Sylvara, la Cazadora Silenciosa, emerge entre los árboles!";

  Timer? _sylvaraTimer;

  List<Map<String, dynamic>> hotbar = [
    {"name": "", "icon": null, "type": "empty"},
    {"name": "", "icon": null, "type": "empty"},
    {"name": "", "icon": null, "type": "empty"},
  ];
  List<Map<String, dynamic>> _fullInventory = [];

  final List<String> _dialogs = [
    "Escucha... los árboles aún recuerdan\ncuando este lugar era sagrado.",
    "Sylvara era nuestra mejor exploradora...\nahora caza a los vivos por orden de Malakor.",
    "Muévete rápido. En el silencio del bosque,\nella siempre ataca primero.",
  ];

  @override
  void initState() {
    super.initState();
    _loadHotbar();
  }

  @override
  void dispose() {
    _sylvaraTimer?.cancel();
    super.dispose();
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
                  "name": "Espada",
                  "icon": Icons.colorize,
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
                    i['item_id'] != 'flecha_eco',
              )
              ? {
                  "name": "Poción",
                  "icon": Icons.health_and_safety,
                  "type": "heal",
                  "_id": inventory.firstWhere(
                    (i) =>
                        i['type'] == 'consumable' &&
                        i['item_id'] != 'esencia_glacial' &&
                        i['item_id'] != 'flecha_eco',
                  )['_id'],
                }
              : {"name": "", "icon": null, "type": "empty"},
          inventory.any((i) => i['item_id'] == 'manto_01')
              ? {
                  "name": "Manto",
                  "icon": Icons.shield,
                  "type": "shield",
                  "_id": inventory.firstWhere(
                    (i) => i['item_id'] == 'manto_01',
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
          "¡Sylvara emerge entre las sombras del bosque!\n¡Sus ojos brillan como estrellas muertas!",
    );
    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        _isWalking = false;
        _isCombatActive = true;
      });
      _startSylvaraAI();
    });
  }

  void _startSylvaraAI() {
    _sylvaraTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (gameEnded || !_isCombatActive) {
        timer.cancel();
        return;
      }
      _turnCounter++;
      if (_turnCounter % 3 == 0) {
        setState(() {
          sylvaraInvisible = true;
          combatLog =
              "👁️ ¡Sylvara desaparece entre las sombras!\n¡Tu próximo ataque fallará!";
        });
      } else {
        _sylvaraAtaque();
      }
    });
  }

  void _sylvaraAtaque() {
    if (gameEnded) return;
    setState(() {
      int damage = 12 + (DateTime.now().millisecond % 10);
      combatLog = "🏹 ¡Sylvara te dispara desde las sombras! -$damage HP";
      playerHP = (playerHP - damage).clamp(0, 100);
      if (playerHP <= 0) _endGame(false);
    });
    ApiService.resetHp(playerHP).catchError((_) {});
  }

  void _playerAttack() {
    if (!isPlayerTurn || gameEnded) return;
    if (sylvaraInvisible) {
      setState(() {
        combatLog =
            "💨 ¡Tu ataque atraviesa el aire!\n¡Sylvara era un fantasma!";
        sylvaraInvisible = false;
        isPlayerTurn = false;
      });
      Future.delayed(
        const Duration(milliseconds: 1200),
        () => setState(() => isPlayerTurn = true),
      );
      return;
    }
    setState(() {
      int bonus = _flechaEcoActiva ? 5 : 0;
      int damage = 15 + (DateTime.now().millisecond % 10) + bonus;
      if (_flechaEcoActiva) {
        _turnosFlechaEco--;
        if (_turnosFlechaEco <= 0) {
          _flechaEcoActiva = false;
          combatLog += "\n🏹 Flecha del Eco se ha agotado.";
        }
      }
      sylvaraHP = (sylvaraHP - damage).clamp(0, 100);
      combatLog = "⚔️ ¡Golpeas a Sylvara! -$damage HP";
      isPlayerTurn = false;
      if (sylvaraHP <= 0) {
        _endGame(true);
        return;
      }
    });
    Future.delayed(
      const Duration(milliseconds: 1200),
      () => setState(() => isPlayerTurn = true),
    );
  }

  void _useItem(Map<String, dynamic> item) {
    if (!isPlayerTurn || gameEnded) return;
    switch (item["type"]) {
      case "weapon":
        _playerAttack();
        break;
      case "heal":
        _usePocion(item);
        break;
      case "consumable":
        _useConsumible(item);
        break;
      case "shield":
        _useEscudo(item);
        break;
      case "freeze":
        _useEsenciaGlacial(item);
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
        sylvaraInvisible = false;
        combatLog =
            "❄️ ¡La Esencia Glacial congela el aire!\n¡Sylvara ha sido revelada y congelada!";
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
      setState(() => combatLog = "No puedes usar la Esencia ahora.");
    }
  }

  void _endGame(bool won) async {
    _sylvaraTimer?.cancel();
    setState(() => gameEnded = true);
    bool llaveOtorgada = false;
    if (won) {
      try {
        final result = await ApiService.saveProgress(
          nivelCompletado: 4,
          xpGanado: 450,
          nuevaLlave: true,
        );
        llaveOtorgada = result['llaveOtorgada'] ?? false;
        if (llaveOtorgada)
          await ApiService.addItem({
            'name': 'Llave del Bosque',
            'type': 'key',
            'item_id': 'key_04',
          });
        final inventory = await ApiService.getInventory();
        if (!inventory.any((i) => i['item_id'] == 'flecha_eco')) {
          await ApiService.addItem({
            'name': 'Flecha del Eco',
            'type': 'consumable',
            'item_id': 'flecha_eco',
            'stats': {'damage_bonus': 5, 'turns': 2},
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
          won ? "¡SYLVARA HA SIDO LIBERADA!" : "HAS CAÍDO EN COMBATE",
          style: TextStyle(
            color: won ? Colors.greenAccent : Colors.redAccent,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              won ? Icons.forest : Icons.dangerous,
              size: 80,
              color: won ? Colors.greenAccent : Colors.redAccent,
            ),
            const SizedBox(height: 15),
            Text(
              won
                  ? "El bosque exhala.\nSylvara descansa entre los árboles que tanto amó."
                  : "Las sombras del bosque te han consumido.\nSylvara sigue cazando.",
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, height: 1.5),
            ),
            if (won) ...[
              const SizedBox(height: 15),
              Text(
                llaveOtorgada
                    ? "+450 XP  •  +1 Llave del Bosque  •  Flecha del Eco"
                    : "+450 XP  •  Flecha del Eco  •  (llave ya obtenida)",
                style: const TextStyle(
                  color: Colors.greenAccent,
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
                backgroundColor: won ? Colors.green[800] : Colors.red,
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
              "https://images.unsplash.com/photo-1448375240586-882707db888b?q=80&w=1000&auto=format&fit=crop",
            ),
            fit: BoxFit.cover,
          ),
        ),
        child: Stack(
          children: [
            Container(color: Colors.green.withOpacity(0.15)),
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
              border: Border.all(color: Colors.greenAccent, width: 3),
              boxShadow: [
                BoxShadow(color: Colors.green.withOpacity(0.3), blurRadius: 15),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "VOZ DEL BOSQUE",
                  style: TextStyle(
                    color: Colors.greenAccent,
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
                      fontSize: 16,
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
        _buildSylvaraCard(),
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

  Widget _buildSylvaraCard() {
    double progress = (sylvaraHP / 100).clamp(0.0, 1.0);
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              sylvaraInvisible ? Icons.visibility_off : Icons.person,
              color: sylvaraInvisible ? Colors.grey : Colors.greenAccent,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              sylvaraInvisible
                  ? "SYLVARA — INVISIBLE 👁️"
                  : "SYLVARA — CAZADORA SILENCIOSA",
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
                    colors: sylvaraInvisible
                        ? [Colors.grey.withOpacity(0.5), Colors.grey]
                        : [Colors.green.withOpacity(0.5), Colors.greenAccent],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            Text(
              "$sylvaraHP / 100",
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
      margin: const EdgeInsets.symmetric(horizontal: 30),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: sylvaraInvisible ? Colors.grey : Colors.white12,
        ),
      ),
      child: Text(
        combatLog,
        style: TextStyle(
          color: sylvaraInvisible ? Colors.grey : Colors.white,
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
