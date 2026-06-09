import 'package:flutter/material.dart';
import 'dart:async';
import 'package:videojuego_rpg/data/services/api_service.dart';
import 'package:videojuego_rpg/ui/widgets/battle_hotbar.dart';

class LevelSixScreen extends StatefulWidget {
  const LevelSixScreen({super.key});

  @override
  State<LevelSixScreen> createState() => _LevelSixScreenState();
}

class _LevelSixScreenState extends State<LevelSixScreen> {
  int _dialogIndex = 0;
  bool _isCombatActive = false;
  bool gameEnded = false;
  bool _isWalking = false;
  double _playerX = -1.0;
  bool _flechaEcoActiva = false;
  int _turnosFlechaEco = 0;

  int ignarHP = 130;
  int ignarMaxHP = 130;
  int _turnCounter = 0;

  int playerHP = 100;
  bool isPlayerTurn = true;
  bool tieneHojaReforzada = false;
  String combatLog = "¡Ignar, el Herrero de Ceniza, emerge de las llamas!";

  Timer? _ignarTimer;

  List<Map<String, dynamic>> hotbar = [
    {"name": "", "icon": null, "type": "empty"},
    {"name": "", "icon": null, "type": "empty"},
    {"name": "", "icon": null, "type": "empty"},
  ];
  List<Map<String, dynamic>> _fullInventory = [];

  final List<String> _dialogs = [
    "Ignar forjó las armas que defendieron\nel reino durante siglos...",
    "Ahora usa ese mismo fuego para destruir.\nSu calor es insoportable.",
    "El secreto es la velocidad —\nno le des tiempo de recuperarse.",
  ];

  @override
  void initState() {
    super.initState();
    _loadHotbar();
  }

  @override
  void dispose() {
    _ignarTimer?.cancel();
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
        // FIX: tieneHojaReforzada dentro del setState
        tieneHojaReforzada = inventory.any(
          (i) => i['item_id'] == 'hoja_reforzada',
        );
        _fullInventory = List<Map<String, dynamic>>.from(inventory);
        hotbar = [
          inventory.any((i) => i['type'] == 'weapon')
              ? {
                  "name": tieneHojaReforzada ? "Hoja Ref." : "Espada",
                  "icon": tieneHojaReforzada
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
                    i['item_id'] != 'frasco_nostalgia',
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
                        i['item_id'] != 'frasco_nostalgia',
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
          "¡IGNAR golpea su yunque!\n¡El calor de la forja te envuelve!",
    );
    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        _isWalking = false;
        _isCombatActive = true;
      });
      _startIgnarAI();
    });
  }

  void _startIgnarAI() {
    _ignarTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (gameEnded || !_isCombatActive) {
        timer.cancel();
        return;
      }
      _turnCounter++;
      if (_turnCounter % 3 == 0)
        _ignarRegeneracion();
      else
        _ignarAtaque();
    });
  }

  void _ignarRegeneracion() {
    if (gameEnded) return;
    final hpAntes = ignarHP;
    setState(() {
      ignarHP = (ignarHP + 15).clamp(0, ignarMaxHP);
      final recuperado = ignarHP - hpAntes;
      combatLog =
          "🔥 ¡Ignar absorbe el calor de la forja!\n+$recuperado HP recuperados";
    });
  }

  void _ignarAtaque() {
    if (gameEnded) return;
    setState(() {
      int damage = 14 + (DateTime.now().millisecond % 10);
      combatLog = "⚒️ ¡Ignar te golpea con su martillo de ceniza! -$damage HP";
      playerHP = (playerHP - damage).clamp(0, 100);
      if (playerHP <= 0) _endGame(false);
    });
    ApiService.resetHp(playerHP).catchError((_) {});
  }

  void _playerAttack() {
    if (!isPlayerTurn || gameEnded) return;
    setState(() {
      int baseDamage = tieneHojaReforzada ? 23 : 15;
      int bonus = _flechaEcoActiva ? 5 : 0;
      int damage = baseDamage + (DateTime.now().millisecond % 10) + bonus;
      ignarHP = (ignarHP - damage).clamp(0, ignarMaxHP);

      String log = tieneHojaReforzada
          ? "⚔️ ¡La Hoja Reforzada corta a Ignar! -$damage HP"
          : "⚔️ ¡Golpeas a Ignar! -$damage HP";

      if (_flechaEcoActiva) {
        _turnosFlechaEco--;
        if (_turnosFlechaEco <= 0) {
          _flechaEcoActiva = false;
          log += "\n🏹 Flecha del Eco se ha agotado.";
        }
      }

      combatLog = log;
      isPlayerTurn = false;
      if (ignarHP <= 0) {
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
      case "shield":
        _useEscudo(item);
        break;
      case "consumable":
        _useConsumible(item);
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
        _ignarTimer?.cancel();
        combatLog =
            "❄️ ¡La Esencia Glacial apaga el fuego de Ignar!\n¡Congelado — no puede regenerarse!";
        final index = hotbar.indexWhere((h) => h['_id'] == item['_id']);
        if (index != -1)
          hotbar[index] = {"name": "", "icon": null, "type": "empty"};
        _fullInventory.removeWhere((i) => i['_id'] == item['_id']);
        isPlayerTurn = false;
      });
      await Future.delayed(const Duration(seconds: 4));
      if (!gameEnded) {
        setState(() {
          combatLog = "🔥 ¡El fuego de Ignar vuelve a arder!";
          isPlayerTurn = true;
        });
        _startIgnarAI();
      }
    } catch (e) {
      setState(() => combatLog = "No puedes congelar ahora.");
    }
  }

  void _endGame(bool won) async {
    _ignarTimer?.cancel();
    setState(() => gameEnded = true);
    bool llaveOtorgada = false;
    if (won) {
      try {
        final result = await ApiService.saveProgress(
          nivelCompletado: 6,
          xpGanado: 650,
          nuevaLlave: true,
        );
        llaveOtorgada = result['llaveOtorgada'] ?? false;
        if (llaveOtorgada)
          await ApiService.addItem({
            'name': 'Llave de la Forja',
            'type': 'key',
            'item_id': 'key_06',
          });
        final inventory = await ApiService.getInventory();
        if (!inventory.any((i) => i['item_id'] == 'hoja_reforzada')) {
          final espada = inventory.firstWhere(
            (i) => i['type'] == 'weapon',
            orElse: () => {},
          );
          if (espada.isNotEmpty) await ApiService.useItem(espada['_id']);
          await ApiService.addItem({
            'name': 'Hoja Reforzada',
            'type': 'weapon',
            'item_id': 'hoja_reforzada',
            'stats': {'damage': 18, 'damage_bonus': 8, 'durability': 100},
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
          won ? "¡IGNAR HA SIDO LIBERADO!" : "HAS CAÍDO EN COMBATE",
          style: TextStyle(
            color: won ? Colors.orangeAccent : Colors.redAccent,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              won ? Icons.hardware : Icons.dangerous,
              size: 80,
              color: won ? Colors.orangeAccent : Colors.redAccent,
            ),
            const SizedBox(height: 15),
            Text(
              won
                  ? "El fuego de la forja se apaga en paz.\nIgnar descansa entre sus creaciones."
                  : "El calor de Ignar te ha consumido.\nLa forja sigue ardiendo.",
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, height: 1.5),
            ),
            if (won) ...[
              const SizedBox(height: 15),
              Text(
                llaveOtorgada
                    ? "+650 XP  •  +1 Llave de la Forja  •  ⚔️ Hoja Reforzada"
                    : "+650 XP  •  ⚔️ Hoja Reforzada  •  (llave ya obtenida)",
                style: const TextStyle(
                  color: Colors.orangeAccent,
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
                backgroundColor: won ? Colors.orange[800] : Colors.red,
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
              "https://images.unsplash.com/photo-1504307651254-35680f356dfd?q=80&w=1000&auto=format&fit=crop",
            ),
            fit: BoxFit.cover,
          ),
        ),
        child: Stack(
          children: [
            Container(color: Colors.orange.withOpacity(0.15)),
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
              border: Border.all(color: Colors.orangeAccent, width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.orange.withOpacity(0.3),
                  blurRadius: 15,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "ECO DE LA FORJA",
                  style: TextStyle(
                    color: Colors.orangeAccent,
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
        _buildIgnarCard(),
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

  Widget _buildIgnarCard() {
    double progress = (ignarHP / ignarMaxHP).clamp(0.0, 1.0);
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.local_fire_department,
              color: Colors.orangeAccent,
              size: 20,
            ),
            const SizedBox(width: 8),
            const Text(
              "IGNAR — HERRERO DE CENIZA",
              style: TextStyle(
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
                    colors: [
                      Colors.orange.withOpacity(0.5),
                      Colors.orangeAccent,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            Text(
              "$ignarHP / $ignarMaxHP",
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
        border: Border.all(color: Colors.white12),
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
