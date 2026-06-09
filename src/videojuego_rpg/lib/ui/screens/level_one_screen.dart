import 'package:flutter/material.dart';
import 'package:videojuego_rpg/data/services/api_service.dart';
import 'package:videojuego_rpg/ui/widgets/battle_hotbar.dart';
import 'dart:async';

class LevelOneScreen extends StatefulWidget {
  const LevelOneScreen({super.key});

  @override
  State<LevelOneScreen> createState() => _LevelOneScreenState();
}

class _LevelOneScreenState extends State<LevelOneScreen> {
  static const int _maxPlayerHP = 100;
  static const int _maxEnemyHP = 50;

  int _dialogIndex = 0;
  bool _isCombatActive = false;
  bool gameEnded = false;

  int playerHP = _maxPlayerHP;
  int enemyHP = _maxEnemyHP;
  String combatLog = "";
  bool isPlayerTurn = true;

  bool _isWalking = false;
  double _playerX = -1.0;
  Timer? _enemyTimer;
  bool _enemyAttackPending = false;

  final List<String> _dialogs = [
    "Despierta... El mundo que conocías se ha fragmentado.",
    "Soy la Reina de Aethelgard. Lo que ves no es más que un eco de nuestro hogar.",
    "Malakor ha robado los 9 fragmentos de esperanza. Sin ellos, la oscuridad será eterna.",
    "Toma esto. Es el 'Regalo de la Reina'. Úsala para abrirte paso entre los corruptos.",
  ];

  // 3 slots visibles en la barra + inventario completo para la mochila
  List<Map<String, dynamic>> hotbar = [
    {"name": "", "icon": null, "type": "empty"},
    {"name": "", "icon": null, "type": "empty"},
    {"name": "", "icon": null, "type": "empty"},
  ];
  List<Map<String, dynamic>> _fullInventory = [];

  @override
  void initState() {
    super.initState();
    _loadHotbar();
  }

  @override
  void dispose() {
    _enemyTimer?.cancel();
    super.dispose();
  }

  Future<bool> _yaTenesEspada() async {
    try {
      final inventory = await ApiService.getInventory();
      return inventory.any((item) => item['type'] == 'weapon');
    } catch (e) {
      return false;
    }
  }

  Future<void> _loadHotbar() async {
    try {
      await ApiService.resetHp(100);
      final player = await ApiService.getPlayer();
      final inventory = await ApiService.getInventory();
      setState(() {
        playerHP = (player['stats']?['hp'] as int? ?? _maxPlayerHP).clamp(
          0,
          _maxPlayerHP,
        );
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
          inventory.any((i) => i['type'] == 'consumable')
              ? {
                  "name": "Poción",
                  "icon": Icons.health_and_safety,
                  "type": "heal",
                  "_id": inventory.firstWhere(
                    (i) => i['type'] == 'consumable',
                  )['_id'],
                }
              : {"name": "", "icon": null, "type": "empty"},
          {"name": "", "icon": null, "type": "empty"},
        ];
      });
    } catch (e) {
      debugPrint('Error cargando hotbar: $e');
    }
  }

  void _startWalking() {
    setState(() {
      _isWalking = true;
      _isCombatActive = false;
      _playerX = -1.0;
    });
    Future.delayed(const Duration(milliseconds: 50), () {
      setState(() => _playerX = 0.0);
    });
    Future.delayed(const Duration(seconds: 2), _showEnemyEncounter);
  }

  void _showEnemyEncounter() {
    setState(() {
      combatLog = "¡ALTO AHÍ! Un Guardia Corrupto emerge de las sombras...";
    });
    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        _isWalking = false;
        _isCombatActive = true;
      });
      _startEnemyAi();
    });
  }

  void _startEnemyAi() {
    _enemyTimer?.cancel();
    _enemyTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (!gameEnded && _isCombatActive && !_enemyAttackPending) {
        _enemyAttack();
      } else if (gameEnded) {
        timer.cancel();
      }
    });
  }

  void _nextDialog() {
    setState(() {
      if (_dialogIndex < _dialogs.length - 1) {
        _dialogIndex++;
      } else {
        _showItemReceived();
      }
    });
  }

  void _showItemReceived() async {
    final tieneEspada = await _yaTenesEspada();
    if (!mounted) return;
    if (tieneEspada) {
      _startWalking();
      return;
    }
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text(
          "¡ÍTEM RECIBIDO!",
          style: TextStyle(
            color: Colors.orangeAccent,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.colorize, size: 60, color: Colors.orangeAccent),
            SizedBox(height: 15),
            Text(
              "Has obtenido la 'Espada de Hierro'.",
              style: TextStyle(color: Colors.white),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          Center(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE94560),
              ),
              onPressed: () async {
                Navigator.pop(context);
                await _loadHotbar();
                _startWalking();
              },
              child: const Text(
                "IR AL COMBATE",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _playerAttack() {
    if (!isPlayerTurn || gameEnded) return;
    setState(() {
      _enemyAttackPending = true;
      int damage = 15 + (DateTime.now().millisecond % 10);
      enemyHP = (enemyHP - damage).clamp(0, _maxEnemyHP);
      combatLog = "¡ZAS! Golpeaste al Guardia por $damage de daño";
      isPlayerTurn = false;
    });
    if (enemyHP <= 0) {
      _enemyAttackPending = false;
      _endGame(true);
    } else {
      Future.delayed(const Duration(milliseconds: 1200), () {
        _enemyAttackPending = false;
        _enemyAttack();
      });
    }
  }

  void _enemyAttack() {
    if (gameEnded) return;
    setState(() {
      int monsterDamage = 10 + (DateTime.now().millisecond % 15);
      playerHP = (playerHP - monsterDamage).clamp(0, _maxPlayerHP);
      if (playerHP > 0) {
        combatLog = "¡EL GUARDIA TE IMPACTA! Recibes $monsterDamage de daño.";
        isPlayerTurn = true;
      } else {
        combatLog = "Has recibido un golpe mortal...";
        _endGame(false);
      }
    });
    ApiService.resetHp(playerHP).catchError((_) {});
  }

  void _useItem(Map<String, dynamic> item) {
    if (!isPlayerTurn || gameEnded) return;
    if (item["type"] == "weapon") {
      _playerAttack();
    } else if (item["type"] == "heal") {
      _usePocion(item);
    }
  }

  Future<void> _usePocion(Map<String, dynamic> item) async {
    if (playerHP >= _maxPlayerHP) {
      setState(() => combatLog = "¡Ya tienes el HP al máximo!");
      return;
    }
    try {
      final result = await ApiService.useItem(item['_id']);
      setState(() {
        playerHP = (result['newHp'] as int).clamp(0, _maxPlayerHP);
        combatLog = "¡Bebiste una poción! +${result['healed']} HP";
        final index = hotbar.indexWhere((h) => h['_id'] == item['_id']);
        if (index != -1)
          hotbar[index] = {"name": "", "icon": null, "type": "empty"};
        // También la quita del inventario completo
        _fullInventory.removeWhere((i) => i['_id'] == item['_id']);
        isPlayerTurn = false;
      });
      Future.delayed(const Duration(milliseconds: 1000), _enemyAttack);
    } catch (e) {
      setState(() => combatLog = "Error al usar poción: $e");
    }
  }

  void _endGame(bool won) async {
    _enemyTimer?.cancel();
    setState(() => gameEnded = true);
    bool llaveOtorgada = false;
    if (won) {
      try {
        final result = await ApiService.saveProgress(
          nivelCompletado: 1,
          xpGanado: 150,
          nuevaLlave: true,
        );
        llaveOtorgada = result['llaveOtorgada'] ?? false;
        if (llaveOtorgada) {
          await ApiService.addItem({
            'name': 'Llave del Jardín',
            'type': 'key',
            'item_id': 'key_01',
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
          won ? "¡VICTORIA ÉPICA!" : "HAS CAÍDO EN COMBATE",
          style: TextStyle(
            color: won ? Colors.greenAccent : Colors.redAccent,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              won ? Icons.emoji_events : Icons.dangerous,
              size: 80,
              color: won ? Colors.yellowAccent : Colors.redAccent,
            ),
            const SizedBox(height: 20),
            Text(
              won
                  ? "El Guardia ha sido derrotado.\nNivel 2 desbloqueado."
                  : "Tu viaje termina aquí. La oscuridad ha reclamado tu alma.",
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white),
            ),
            if (won) ...[
              const SizedBox(height: 10),
              Text(
                llaveOtorgada
                    ? "+150 XP  •  +1 Llave"
                    : "+150 XP  •  (llave ya obtenida)",
                style: const TextStyle(
                  color: Colors.yellowAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ],
        ),
        actions: [
          Center(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: won ? Colors.green : Colors.red,
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
              "https://images.unsplash.com/photo-1518531933037-91b2f5f229cc?q=80&w=1000&auto=format&fit=crop",
            ),
            fit: BoxFit.cover,
          ),
        ),
        child: Stack(
          children: [
            if (_isWalking)
              AnimatedAlign(
                duration: const Duration(seconds: 2),
                alignment: Alignment(_playerX, 0.5),
                child: _playerSprite(),
              ),
            if (_isCombatActive) _buildCombatUI(),
            if (!_isWalking && !_isCombatActive) _buildLoreUI(),
            if (_isWalking && _playerX == 0.0)
              Align(
                alignment: Alignment.topCenter,
                child: Container(
                  margin: const EdgeInsets.only(top: 100),
                  padding: const EdgeInsets.all(10),
                  color: Colors.black87,
                  child: Text(
                    combatLog,
                    style: const TextStyle(color: Colors.redAccent),
                  ),
                ),
              ),
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
              border: Border.all(color: const Color(0xFFE94560), width: 3),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 15),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "LA REINA",
                  style: TextStyle(
                    color: Color(0xFFE94560),
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
                      fontSize: 17,
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

  Widget _buildCombatUI() {
    return Column(
      children: [
        const SizedBox(height: 20),
        _buildStatusCard(
          "GUARDIA CORRUPTO",
          enemyHP,
          _maxEnemyHP,
          Colors.redAccent,
          Icons.shield,
        ),
        const Spacer(),
        _playerSprite(),
        const SizedBox(height: 10),
        _buildCombatLogBox(),
        const Spacer(),
        _buildStatusCard(
          "SOBREVIVIENTE",
          playerHP,
          _maxPlayerHP,
          Colors.greenAccent,
          Icons.person,
        ),
        // ← BattleHotbar reemplaza hotbar viejo + botones de acción
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
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 10),
            Text(
              name,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 300,
              height: 25,
              decoration: BoxDecoration(
                color: Colors.black45,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white10),
              ),
            ),
            Positioned(
              left: 0,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                width: 300 * progress,
                height: 25,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color.withOpacity(0.5), color],
                  ),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(color: color.withOpacity(0.3), blurRadius: 8),
                  ],
                ),
              ),
            ),
            Text(
              "$current / $total",
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
                shadows: [Shadow(blurRadius: 2, color: Colors.black)],
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
          fontSize: 16,
          fontStyle: FontStyle.italic,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
