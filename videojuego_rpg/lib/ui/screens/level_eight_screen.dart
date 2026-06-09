import 'package:flutter/material.dart';
import 'dart:async';
import 'package:videojuego_rpg/data/services/api_service.dart';
import 'package:videojuego_rpg/ui/widgets/battle_hotbar.dart';

class LevelEightScreen extends StatefulWidget {
  const LevelEightScreen({super.key});

  @override
  State<LevelEightScreen> createState() => _LevelEightScreenState();
}

class _LevelEightScreenState extends State<LevelEightScreen> {
  int _dialogIndex = 0;
  bool _isCombatActive = false;
  bool gameEnded = false;
  bool _isWalking = false;
  double _playerX = -1.0;

  int seraphelHP = 250;
  int seraphelMaxHP = 250;
  // FIX #4: se pone true inmediatamente al detectar 50% para evitar doble fragmentación
  bool seraphelFragmentado = false;
  int _turnCounter = 0;

  int copiaAHP = 125;
  int copiaBHP = 125;
  bool copiaADerrotada = false;
  bool copiaBDerrotada = false;

  int playerHP = 100;
  bool isPlayerTurn = true;
  String combatLog = "¡Seraphel, el Archivista Corrompido, abre su grimorio!";

  bool _anticipacionActiva = false;
  bool _maldicionActiva = false;
  int _turnosMaldicion = 0;
  bool _flechaEcoActiva = false;
  int _turnosFlechaEco = 0;

  Timer? _seraphelTimer;
  Timer? _copiaATimer;
  Timer? _copiaBTimer;

  List<Map<String, dynamic>> hotbar = [
    {"name": "", "icon": null, "type": "empty"},
    {"name": "", "icon": null, "type": "empty"},
    {"name": "", "icon": null, "type": "empty"},
  ];
  List<Map<String, dynamic>> _fullInventory = [];

  final List<String> _dialogs = [
    "Bienvenido... a la Gran Biblioteca de Cristal.\nAquí el conocimiento toma forma.",
    "Seraphel lo leyó todo.\nCada guerra, cada traición, cada secreto oscuro...",
    "El peso de tanto saber lo quebró.\nAhora usa ese conocimiento para consumir almas.",
    "Cuidado, portador.\nÉl ya sabe cómo atacas.\nYa sabe cómo piensas.",
    "La única forma de vencerlo...\nes ser impredecible.",
  ];

  @override
  void initState() {
    super.initState();
    _loadHotbar();
  }

  @override
  void dispose() {
    _seraphelTimer?.cancel();
    _copiaATimer?.cancel();
    _copiaBTimer?.cancel();
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
                    i['item_id'] != 'esencia_pesar' &&
                    i['item_id'] != 'pagina_maldita',
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
                        i['item_id'] != 'esencia_pesar' &&
                        i['item_id'] != 'pagina_maldita',
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
          "¡SERAPHEL abre su grimorio!\n¡Las páginas cobran vida a su alrededor!",
    );
    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        _isWalking = false;
        _isCombatActive = true;
      });
      _startSeraphelAI();
    });
  }

  void _startSeraphelAI() {
    _seraphelTimer?.cancel();
    _seraphelTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (gameEnded || !_isCombatActive || seraphelFragmentado) {
        timer.cancel();
        return;
      }
      _turnCounter++;
      if (_turnCounter % 2 == 0)
        _ultimateSeraphel();
      else
        _seraphelAtaqueNormal();
    });
  }

  void _ultimateSeraphel() {
    if (gameEnded) return;
    setState(() {
      _anticipacionActiva = true;
      _maldicionActiva = true;
      _turnosMaldicion = 2;
      int damage = 12;
      playerHP = (playerHP - damage).clamp(0, 100);
      combatLog =
          "📚 ¡SERAPHEL LEE TU DESTINO!\n¡Anticipación + Maldición activas! -$damage HP\n¡Tu próximo ataque fallará y te dañará!";
      if (playerHP <= 0) _endGame(false);
    });
    ApiService.resetHp(playerHP).catchError((_) {});
  }

  void _seraphelAtaqueNormal() {
    if (gameEnded) return;
    setState(() {
      int damage = 14 + (DateTime.now().millisecond % 10);
      combatLog = "📖 ¡Seraphel lanza páginas afiladas! -$damage HP";
      playerHP = (playerHP - damage).clamp(0, 100);
      if (playerHP <= 0) _endGame(false);
    });
    ApiService.resetHp(playerHP).catchError((_) {});
  }

  void _fragmentarSeraphel() {
    _seraphelTimer?.cancel();
    // FIX #5: resetea el contador para que las copias empiecen desde 0
    _turnCounter = 0;
    setState(() {
      copiaAHP = 125;
      copiaBHP = 125;
      combatLog =
          "💎 ¡SERAPHEL SE FRAGMENTA!\n¡Dos copias emergen con toda su energía renovada!\n¡Derrota a ambas para ganar!";
    });
    Future.delayed(const Duration(seconds: 2), () {
      _startCopiaAAI();
      _startCopiaBAI();
    });
  }

  void _startCopiaAAI() {
    _copiaATimer?.cancel();
    _copiaATimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (gameEnded || copiaADerrotada) {
        timer.cancel();
        return;
      }
      _turnCounter++;
      if (_turnCounter % 2 == 0) {
        setState(() {
          _anticipacionActiva = true;
          combatLog = "📚 ¡Copia A lee tu mente!\n¡Tu próximo ataque fallará!";
        });
      } else {
        _copiaAAtaque();
      }
    });
  }

  void _copiaAAtaque() {
    if (gameEnded || copiaADerrotada) return;
    setState(() {
      int damage = 10 + (DateTime.now().millisecond % 8);
      combatLog = "📄 ¡Copia A te ataca con páginas! -$damage HP";
      playerHP = (playerHP - damage).clamp(0, 100);
      if (playerHP <= 0) _endGame(false);
    });
    ApiService.resetHp(playerHP).catchError((_) {});
  }

  void _startCopiaBAI() {
    _copiaBTimer?.cancel();
    _copiaBTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (gameEnded || copiaBDerrotada) {
        timer.cancel();
        return;
      }
      _turnCounter++;
      if (_turnCounter % 4 == 0) {
        setState(() {
          _maldicionActiva = true;
          _turnosMaldicion = 2;
          combatLog =
              "📜 ¡Copia B te maldice!\n¡Tus ataques te dañarán por 2 turnos!";
        });
      } else {
        _copiaBAtaque();
      }
    });
  }

  void _copiaBAtaque() {
    if (gameEnded || copiaBDerrotada) return;
    setState(() {
      int damage = 8 + (DateTime.now().millisecond % 8);
      combatLog = "📜 ¡Copia B lanza un conjuro! -$damage HP";
      playerHP = (playerHP - damage).clamp(0, 100);
      if (playerHP <= 0) _endGame(false);
    });
    ApiService.resetHp(playerHP).catchError((_) {});
  }

  void _playerAttack() {
    if (!isPlayerTurn || gameEnded) return;

    if (_anticipacionActiva) {
      setState(() {
        _anticipacionActiva = false;
        int selfDamage = _maldicionActiva ? 5 : 0;
        if (_maldicionActiva) {
          playerHP = (playerHP - selfDamage).clamp(0, 100);
          _turnosMaldicion--;
          if (_turnosMaldicion <= 0) _maldicionActiva = false;
        }
        combatLog =
            "👁️ ¡Seraphel anticipó tu ataque!\n¡Fallas completamente!${selfDamage > 0 ? '\n☠️ La maldición te hace -$selfDamage HP' : ''}";
        isPlayerTurn = false;
        if (playerHP <= 0) _endGame(false);
      });
      ApiService.resetHp(playerHP).catchError((_) {});
      Future.delayed(
        const Duration(milliseconds: 1200),
        () => setState(() => isPlayerTurn = true),
      );
      return;
    }

    setState(() {
      bool tieneHoja = _fullInventory.any(
        (i) => i['item_id'] == 'hoja_reforzada',
      );
      int baseDamage = tieneHoja ? 23 : 15;
      int bonus = _flechaEcoActiva ? 5 : 0;
      int damage = baseDamage + (DateTime.now().millisecond % 10) + bonus;

      int selfDamage = 0;
      if (_maldicionActiva) {
        selfDamage = 5;
        playerHP = (playerHP - selfDamage).clamp(0, 100);
        _turnosMaldicion--;
        if (_turnosMaldicion <= 0) _maldicionActiva = false;
      }

      String log;

      if (!seraphelFragmentado) {
        seraphelHP = (seraphelHP - damage).clamp(0, seraphelMaxHP);
        log = "⚔️ ¡Golpeas a Seraphel! -$damage HP";

        // FIX #4: seraphelFragmentado = true inmediatamente para evitar doble fragmentación
        if (seraphelHP <= 125) {
          seraphelFragmentado = true;
          isPlayerTurn = false;
          if (selfDamage > 0)
            log += "\n☠️ La maldición te hace -$selfDamage HP";
          combatLog = log;
          Future.delayed(
            const Duration(milliseconds: 500),
            _fragmentarSeraphel,
          );
          return;
        }
      } else if (!copiaADerrotada) {
        copiaAHP = (copiaAHP - damage).clamp(0, 125);
        log = "⚔️ ¡Golpeas a Copia A! -$damage HP";
        if (copiaAHP <= 0) {
          copiaADerrotada = true;
          _copiaATimer?.cancel();
          log = "✨ ¡Copia A ha sido destruida!";
        }
      } else {
        copiaBHP = (copiaBHP - damage).clamp(0, 125);
        log = "⚔️ ¡Golpeas a Copia B! -$damage HP";
        if (copiaBHP <= 0) {
          copiaBDerrotada = true;
          _copiaBTimer?.cancel();
        }
      }

      if (_flechaEcoActiva) {
        _turnosFlechaEco--;
        if (_turnosFlechaEco <= 0) {
          _flechaEcoActiva = false;
          log += "\n🏹 Flecha del Eco agotada.";
        }
      }
      if (selfDamage > 0) log += "\n☠️ La maldición te hace -$selfDamage HP";
      combatLog = log;
      isPlayerTurn = false;

      if (playerHP <= 0) {
        _endGame(false);
        return;
      }
      if (copiaADerrotada && copiaBDerrotada) {
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
        _seraphelTimer?.cancel();
        _copiaATimer?.cancel();
        _copiaBTimer?.cancel();
        _anticipacionActiva = false;
        combatLog =
            "❄️ ¡La Esencia Glacial congela las páginas!\n¡Seraphel y sus copias están congelados!";
        final index = hotbar.indexWhere((h) => h['_id'] == item['_id']);
        if (index != -1)
          hotbar[index] = {"name": "", "icon": null, "type": "empty"};
        _fullInventory.removeWhere((i) => i['_id'] == item['_id']);
        isPlayerTurn = false;
      });
      await Future.delayed(const Duration(seconds: 4));
      if (!gameEnded) {
        setState(() {
          combatLog = "📚 ¡Las páginas vuelven a moverse!";
          isPlayerTurn = true;
        });
        if (!seraphelFragmentado)
          _startSeraphelAI();
        else {
          if (!copiaADerrotada) _startCopiaAAI();
          if (!copiaBDerrotada) _startCopiaBAI();
        }
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
    } else if (item['item_id'] == 'pagina_maldita') {
      try {
        await ApiService.useItem(item['_id']);
        setState(() {
          _anticipacionActiva = false;
          combatLog =
              "📄 ¡Lanzas la Página Maldita!\n¡Seraphel queda confundido!\n¡Sus anticipaciones fallan!";
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
    } else if (item['item_id'] == 'esencia_pesar') {
      try {
        await ApiService.useItem(item['_id']);
        setState(() {
          combatLog =
              "☠️ ¡Lanzas la Esencia del Pesar!\n¡Seraphel está envenenado por 3 turnos!";
          final index = hotbar.indexWhere((h) => h['_id'] == item['_id']);
          if (index != -1)
            hotbar[index] = {"name": "", "icon": null, "type": "empty"};
          _fullInventory.removeWhere((i) => i['_id'] == item['_id']);
          isPlayerTurn = false;
        });
        int turnosVeneno = 3;
        Timer.periodic(const Duration(seconds: 3), (timer) {
          // FIX #3: verifica gameEnded antes de actuar
          if (gameEnded || turnosVeneno <= 0) {
            timer.cancel();
            return;
          }
          setState(() {
            if (!seraphelFragmentado) {
              seraphelHP = (seraphelHP - 5).clamp(0, seraphelMaxHP);
              if (seraphelHP <= 0) {
                _endGame(true);
                timer.cancel();
                return;
              }
            } else if (!copiaADerrotada) {
              copiaAHP = (copiaAHP - 5).clamp(0, 125);
              if (copiaAHP <= 0) {
                copiaADerrotada = true;
                _copiaATimer?.cancel();
              }
            }
            turnosVeneno--;
            combatLog =
                "☠️ El veneno corroe a Seraphel... ($turnosVeneno turnos restantes)";
            if (copiaADerrotada && copiaBDerrotada && !gameEnded) {
              _endGame(true);
              timer.cancel();
            }
          });
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

  void _endGame(bool won) async {
    if (gameEnded) return; // FIX #3: evita llamadas dobles a _endGame
    _seraphelTimer?.cancel();
    _copiaATimer?.cancel();
    _copiaBTimer?.cancel();
    setState(() => gameEnded = true);
    bool llaveOtorgada = false;
    if (won) {
      try {
        final result = await ApiService.saveProgress(
          nivelCompletado: 8,
          xpGanado: 850,
          nuevaLlave: true,
        );
        llaveOtorgada = result['llaveOtorgada'] ?? false;
        if (llaveOtorgada)
          await ApiService.addItem({
            'name': 'Llave de la Biblioteca',
            'type': 'key',
            'item_id': 'key_08',
          });
        // FIX #1: la Página Maldita se da al GANAR el nivel 8, para usarla en niveles siguientes
        final inventory = await ApiService.getInventory();
        if (!inventory.any((i) => i['item_id'] == 'pagina_maldita')) {
          await ApiService.addItem({
            'name': 'Página Maldita',
            'type': 'consumable',
            'item_id': 'pagina_maldita',
            'stats': {'damage_bonus': 0, 'confusion_turns': 2},
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
          won ? "¡SERAPHEL HA SIDO LIBERADO!" : "HAS CAÍDO EN COMBATE",
          style: TextStyle(
            color: won ? Colors.indigoAccent : Colors.redAccent,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              won ? Icons.menu_book : Icons.dangerous,
              size: 80,
              color: won ? Colors.indigoAccent : Colors.redAccent,
            ),
            const SizedBox(height: 15),
            Text(
              won
                  ? "Las páginas caen en silencio.\nSeraphel recuerda por qué amaba el conocimiento."
                  : "El conocimiento de Seraphel te ha consumido.\nLa biblioteca permanece sellada.",
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, height: 1.5),
            ),
            if (won) ...[
              const SizedBox(height: 15),
              Text(
                llaveOtorgada
                    ? "+850 XP  •  +1 Llave de la Biblioteca  •  Página Maldita"
                    : "+850 XP  •  Página Maldita  •  (llave ya obtenida)",
                style: const TextStyle(
                  color: Colors.indigoAccent,
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
                backgroundColor: won ? Colors.indigo[800] : Colors.red,
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
              "https://images.unsplash.com/photo-1481627834876-b7833e8f5570?q=80&w=1000&auto=format&fit=crop",
            ),
            fit: BoxFit.cover,
          ),
        ),
        child: Stack(
          children: [
            Container(color: Colors.indigo.withOpacity(0.2)),
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
              border: Border.all(color: Colors.indigoAccent, width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.indigo.withOpacity(0.3),
                  blurRadius: 15,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "ECO DE LA BIBLIOTECA",
                  style: TextStyle(
                    color: Colors.indigoAccent,
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
        if (!seraphelFragmentado)
          _buildEnemyCard(
            "SERAPHEL — ARCHIVISTA CORROMPIDO",
            seraphelHP,
            seraphelMaxHP,
            Colors.indigoAccent,
            Icons.menu_book,
          )
        else ...[
          _buildEnemyCard(
            "SERAPHEL A${copiaADerrotada ? ' ✓' : ''}",
            copiaAHP,
            125,
            copiaADerrotada ? Colors.grey : Colors.indigoAccent,
            Icons.book,
          ),
          const SizedBox(height: 6),
          _buildEnemyCard(
            "SERAPHEL B${copiaBDerrotada ? ' ✓' : ''}",
            copiaBHP,
            125,
            copiaBDerrotada ? Colors.grey : Colors.deepPurpleAccent,
            Icons.auto_stories,
          ),
        ],
        const SizedBox(height: 8),
        if (_anticipacionActiva || _maldicionActiva)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_anticipacionActiva)
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.indigo.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.indigoAccent),
                    ),
                    child: const Text(
                      "👁️ Anticipación",
                      style: TextStyle(
                        color: Colors.indigoAccent,
                        fontSize: 11,
                      ),
                    ),
                  ),
                if (_maldicionActiva)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.purple.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.purpleAccent),
                    ),
                    child: Text(
                      "☠️ Maldición ($_turnosMaldicion)",
                      style: const TextStyle(
                        color: Colors.purpleAccent,
                        fontSize: 11,
                      ),
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

  Widget _buildEnemyCard(
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
    Color borderColor = _anticipacionActiva
        ? Colors.indigoAccent
        : _maldicionActiva
        ? Colors.purpleAccent
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
