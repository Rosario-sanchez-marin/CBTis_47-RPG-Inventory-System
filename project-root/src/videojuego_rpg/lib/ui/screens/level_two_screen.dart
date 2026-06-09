import 'package:flutter/material.dart';
import 'dart:async';
import 'package:videojuego_rpg/data/services/api_service.dart';
import 'package:videojuego_rpg/ui/widgets/battle_hotbar.dart';

class LevelTwoScreen extends StatefulWidget {
  const LevelTwoScreen({super.key});

  @override
  State<LevelTwoScreen> createState() => _LevelTwoScreenState();
}

class _LevelTwoScreenState extends State<LevelTwoScreen> {
  static const int _maxPlayerHP = 100;

  int _dialogIndex = 0;
  bool _isCombatActive = false;
  bool gameEnded = false;
  bool _isWalking = false;
  double _playerX = -1.0;

  int kaelHP = 80;
  bool kaelDerrotado = false;
  int sombraHP = 40;
  bool sombraDerrotada = false;

  int playerHP = _maxPlayerHP;
  bool isPlayerTurn = true;
  String combatLog = "¡Dos Centinelas Sombríos bloquean el Paso!";
  bool tieneEscudo = false;

  Timer? _kaelTimer;
  Timer? _sombraTimer;

  // 3 slots visibles + inventario completo para la mochila
  List<Map<String, dynamic>> hotbar = [
    {"name": "", "icon": null, "type": "empty"},
    {"name": "", "icon": null, "type": "empty"},
    {"name": "", "icon": null, "type": "empty"},
  ];
  List<Map<String, dynamic>> _fullInventory = [];

  final List<String> _dialogs = [
    "El Paso de los Guardianes...\nmis soldados más leales descansan aquí,\ncorrompidos por la sombra de Malakor.",
    "No los odies, pequeño portador.\nEllos no eligieron esto.",
    "Derrótales con honor,\ny libera lo que queda de su alma.",
  ];

  @override
  void initState() {
    super.initState();
    _loadHotbar();
  }

  @override
  void dispose() {
    _kaelTimer?.cancel();
    _sombraTimer?.cancel();
    super.dispose();
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
          inventory.any((i) => i['type'] == 'shield')
              ? {
                  "name": "Manto",
                  "icon": Icons.shield,
                  "type": "shield",
                  "_id": inventory.firstWhere(
                    (i) => i['type'] == 'shield',
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
      if (_dialogIndex < _dialogs.length - 1) {
        _dialogIndex++;
      } else {
        _startWalking();
      }
    });
  }

  void _startWalking() {
    setState(() {
      _isWalking = true;
      _playerX = -1.0;
    });
    Future.delayed(const Duration(milliseconds: 50), () {
      setState(() => _playerX = 0.0);
    });
    Future.delayed(const Duration(seconds: 2), _showEnemyEncounter);
  }

  void _showEnemyEncounter() {
    setState(() {
      combatLog = "¡Kael y la Sombra del Umbral emergen de la oscuridad!";
    });
    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        _isWalking = false;
        _isCombatActive = true;
      });
      _startEnemyAI();
    });
  }

  void _startEnemyAI() {
    _kaelTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (gameEnded || !_isCombatActive || kaelDerrotado) {
        timer.cancel();
        return;
      }
      _kaelAttack();
    });
    _sombraTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (gameEnded || !_isCombatActive || sombraDerrotada) {
        timer.cancel();
        return;
      }
      _sombraAttack();
    });
  }

  void _kaelAttack() {
    if (gameEnded) return;
    setState(() {
      int damage = 15 + (DateTime.now().millisecond % 15);
      if (tieneEscudo) {
        damage = (damage / 2).round();
        tieneEscudo = false;
        combatLog = "¡Kael ataca! El Manto absorbe el golpe. -$damage HP";
      } else {
        combatLog = "¡KAEL TE GOLPEA con su lanza oscura! -$damage HP";
      }
      playerHP = (playerHP - damage).clamp(0, _maxPlayerHP);
      if (playerHP <= 0) _endGame(false);
    });
    ApiService.resetHp(playerHP).catchError((_) {});
  }

  void _sombraAttack() {
    if (gameEnded) return;
    setState(() {
      int damage = 8 + (DateTime.now().millisecond % 12);
      combatLog = "¡La Sombra te atraviesa velozmente! -$damage HP";
      playerHP = (playerHP - damage).clamp(0, _maxPlayerHP);
      if (playerHP <= 0) _endGame(false);
    });
    ApiService.resetHp(playerHP).catchError((_) {});
  }

  void _playerAttack() {
    if (!isPlayerTurn || gameEnded) return;
    setState(() {
      int damage = 15 + (DateTime.now().millisecond % 10);
      if (!sombraDerrotada) {
        sombraHP = (sombraHP - damage).clamp(0, 40);
        combatLog = "¡Golpeas a la Sombra del Umbral! -$damage HP";
        if (sombraHP <= 0) {
          sombraDerrotada = true;
          combatLog = "¡La Sombra del Umbral ha sido liberada! ✨";
          _sombraTimer?.cancel();
        }
      } else {
        kaelHP = (kaelHP - damage).clamp(0, 80);
        combatLog = "¡Golpeas a Kael, el Centinela Roto! -$damage HP";
        if (kaelHP <= 0) {
          kaelDerrotado = true;
          combatLog = "¡Kael ha sido liberado! Su alma descansa en paz. ✨";
          _kaelTimer?.cancel();
          _endGame(true);
          return;
        }
      }
      isPlayerTurn = false;
    });
    Future.delayed(
      const Duration(milliseconds: 1200),
      () => setState(() => isPlayerTurn = true),
    );
  }

  void _useItem(Map<String, dynamic> item) {
    if (!isPlayerTurn || gameEnded) return;
    if (item["type"] == "weapon") {
      _playerAttack();
    } else if (item["type"] == "heal") {
      _usePocion(item);
    } else if (item["type"] == "shield") {
      _useEscudo(item);
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
        _fullInventory.removeWhere((i) => i['_id'] == item['_id']);
        isPlayerTurn = false;
      });
      Future.delayed(const Duration(milliseconds: 1000), () {
        setState(() => isPlayerTurn = true);
      });
    } catch (e) {
      setState(() => combatLog = "Error al usar poción: $e");
    }
  }

  void _useEscudo(Map<String, dynamic> item) {
    setState(() {
      tieneEscudo = true;
      combatLog =
          "¡Alzas el Fragmento de Manto! El próximo golpe será absorbido.";
      isPlayerTurn = false;
    });
    Future.delayed(const Duration(milliseconds: 1000), () {
      setState(() => isPlayerTurn = true);
    });
  }

  void _endGame(bool won) async {
    _kaelTimer?.cancel();
    _sombraTimer?.cancel();
    setState(() => gameEnded = true);
    bool llaveOtorgada = false;
    if (won) {
      try {
        final result = await ApiService.saveProgress(
          nivelCompletado: 2,
          xpGanado: 250,
          nuevaLlave: true,
        );
        llaveOtorgada = result['llaveOtorgada'] ?? false;
        if (llaveOtorgada) {
          await ApiService.addItem({
            'name': 'Llave del Paso',
            'type': 'key',
            'item_id': 'key_02',
          });
        }
        final inventory = await ApiService.getInventory();
        final tieneManto = inventory.any((i) => i['item_id'] == 'manto_01');
        if (!tieneManto) {
          await ApiService.addItem({
            'name': 'Fragmento de Manto Dorado',
            'type': 'shield',
            'item_id': 'manto_01',
            'stats': {'absorcion': 50},
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
          won ? "¡CENTINELAS LIBERADOS!" : "HAS CAÍDO EN COMBATE",
          style: TextStyle(
            color: won ? Colors.greenAccent : Colors.redAccent,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              won ? Icons.auto_awesome : Icons.dangerous,
              size: 80,
              color: won ? Colors.yellowAccent : Colors.redAccent,
            ),
            const SizedBox(height: 15),
            Text(
              won
                  ? "Kael y la Sombra descansan en paz.\nEl Paso de los Guardianes ha sido restaurado."
                  : "La oscuridad te ha reclamado.\nEl Paso permanece sellado.",
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, height: 1.5),
            ),
            if (won) ...[
              const SizedBox(height: 15),
              Text(
                llaveOtorgada
                    ? "+250 XP  •  +1 Llave del Paso  •  Fragmento de Manto"
                    : "+250 XP  •  Fragmento de Manto  •  (llave ya obtenida)",
                style: const TextStyle(
                  color: Colors.yellowAccent,
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
            Container(color: Colors.black.withOpacity(0.5)),
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
          "KAEL — CENTINELA ROTO",
          kaelHP,
          80,
          kaelDerrotado ? Colors.grey : Colors.redAccent,
          Icons.shield,
        ),
        const SizedBox(height: 8),
        _buildStatusCard(
          "SOMBRA DEL UMBRAL",
          sombraHP,
          40,
          sombraDerrotada ? Colors.grey : Colors.purpleAccent,
          Icons.blur_on,
        ),
        const Spacer(),
        _playerSprite(),
        const SizedBox(height: 10),
        _buildCombatLogBox(),
        const Spacer(),
        _buildStatusCard(
          "PORTADOR DE LA PROMESA",
          playerHP,
          _maxPlayerHP,
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
                border: Border.all(color: Colors.white10),
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
}
