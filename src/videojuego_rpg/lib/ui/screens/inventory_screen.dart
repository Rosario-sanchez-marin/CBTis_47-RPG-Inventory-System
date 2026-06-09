import 'package:flutter/material.dart';
import 'package:videojuego_rpg/data/services/api_service.dart';

class InventoryScreen extends StatefulWidget {
  // era StatelessWidget
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  // Future que se recarga tras cada acción (RF-08)
  late Future<List<dynamic>> _inventoryFuture;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    setState(() {
      _inventoryFuture = ApiService.getInventory();
    });
  }

  String _descripcionItem(Map<String, dynamic> item) {
    switch (item['item_id']) {
      case 'flecha_eco':
        return "+5 de daño extra por 2 turnos al atacar.";
      case 'frasco_nostalgia':
        return "Una poción misteriosa. Guárdala para el nivel final.";
      case 'esencia_pesar':
        return "Envenena al enemigo 5 HP por turno durante 3 turnos.";
      case 'esencia_glacial':
        return "Congela al enemigo por 2 turnos.";
      case 'manto_01':
        return "Absorbe el próximo golpe recibido a la mitad.";
      case 'hoja_reforzada':
        return "Arma reforzada. +8 de daño base al atacar.";
      case 'pagina_maldita':
        return "Confunde al enemigo — sus anticipaciones fallan.";
      default:
        if (item['type'] == 'consumable')
          return "+${item['stats']?['heal'] ?? 0} HP al usarla en combate.";
        if (item['type'] == 'weapon') return "Tu arma principal de combate.";
        return "Ítem de equipamiento.";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        title: const Text("MOCHILA DEL SOBREVIVIENTE"),
        backgroundColor: const Color(0xFF16213E),
      ),
      body: FutureBuilder<List<dynamic>>(
        // RF-08: FutureBuilder recomendado en SRS
        future: _inventoryFuture,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFFE94560)),
            );
          }
          if (snap.hasError) {
            return Center(
              child: Text(
                'Error: ${snap.error}',
                style: const TextStyle(color: Colors.redAccent),
              ),
            );
          }

          final inventory = snap.data ?? [];
          print('INVENTARIO COMPLETO: $inventory'); //temporal
          final keys = inventory.where((i) => i['type'] == 'key').toList();
          final equipment = inventory.where((i) => i['type'] != 'key').toList();
          print('EQUIPMENT: $equipment'); //temporal

          if (inventory.isEmpty) {
            return const Center(
              child: Text(
                'Tu mochila está vacía.',
                style: TextStyle(color: Colors.white54),
              ),
            );
          }

          return Column(
            children: [
              _buildKeySection(keys),
              const Divider(color: Colors.white24),
              Expanded(child: _buildEquipmentGrid(equipment)),
            ],
          );
        },
      ),
    );
  }

  // SECCIÓN DE LLAVES
  Widget _buildKeySection(List<dynamic> keys) {
    return Container(
      padding: const EdgeInsets.all(15),
      color: const Color(0xFFE94560).withOpacity(0.1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "RELIQUIAS DE LA REINA (${keys.length}/9)",
            style: const TextStyle(
              color: Color(0xFFE94560),
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 60,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 9,
              itemBuilder: (context, index) {
                final hasKey = index < keys.length;
                return Container(
                  width: 50,
                  margin: const EdgeInsets.only(right: 10),
                  decoration: BoxDecoration(
                    color: hasKey ? const Color(0xFFE94560) : Colors.white10,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: hasKey ? Colors.white : Colors.white24,
                    ),
                  ),
                  child: Icon(
                    Icons.vpn_key,
                    color: hasKey ? Colors.white : Colors.white10,
                    size: 20,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // CUADRÍCULA DE EQUIPO
  Widget _buildEquipmentGrid(List<dynamic> itemsList) {
    return GridView.builder(
      padding: const EdgeInsets.all(15),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 15,
        crossAxisSpacing: 15,
      ),
      itemCount: itemsList.length,
      itemBuilder: (context, index) {
        final item = itemsList[index];

        // Ícono y color según item_id o type
        IconData icon;
        Color color;
        switch (item['item_id']) {
          case 'hoja_reforzada':
            icon = Icons.auto_fix_high;
            color = Colors.orangeAccent;
            break;
          case 'manto_01':
            icon = Icons.shield;
            color = Colors.purpleAccent;
            break;
          case 'esencia_glacial':
            icon = Icons.ac_unit;
            color = Colors.cyanAccent;
            break;
          case 'flecha_eco':
            icon = Icons.arrow_upward;
            color = Colors.greenAccent;
            break;
          case 'frasco_nostalgia':
            icon = Icons.water_drop;
            color = Colors.pinkAccent;
            break;
          case 'pagina_maldita':
            icon = Icons.auto_stories;
            color = Colors.indigoAccent;
            break;
          case 'esencia_pesar':
            icon = Icons.coronavirus;
            color = Colors.tealAccent;
            break;
          default:
            switch (item['type']) {
              case 'weapon':
                icon = Icons.colorize;
                color = Colors.orangeAccent;
                break;
              case 'shield':
                icon = Icons.shield;
                color = Colors.purpleAccent;
                break;
              case 'consumable':
                icon = Icons.health_and_safety;
                color = Colors.greenAccent;
                break;
              default:
                icon = Icons.help_outline;
                color = Colors.white54;
            }
        }

        // Descripción según tipo
        String descripcion;
        switch (item['item_id']) {
          case 'flecha_eco':
            descripcion = "+5 daño por 2 turnos.";
            break;
          case 'frasco_nostalgia':
            descripcion = "Guárdalo para el nivel final.";
            break;
          case 'esencia_pesar':
            descripcion = "Envenena al enemigo 3 turnos.";
            break;
          case 'esencia_glacial':
            descripcion = "Congela al enemigo 2 turnos.";
            break;
          case 'manto_01':
            descripcion = "Absorbe el próximo golpe.";
            break;
          case 'hoja_reforzada':
            descripcion = "+8 daño base al atacar.";
            break;
          case 'pagina_maldita':
            descripcion = "Confunde al enemigo — sus anticipaciones fallan.";
            break;
          default:
            descripcion = item['type'] == 'consumable'
                ? "+${item['stats']?['heal'] ?? 0} HP"
                : item['type'] == 'weapon'
                ? "Arma principal."
                : "Ítem de equipamiento.";
        }

        return GestureDetector(
          onTap: () => _showItemAction(context, item),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF0F3460),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: color.withOpacity(0.5), width: 2),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: 30),
                const SizedBox(height: 8),
                Text(
                  item['name'] ?? '',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  descripcion,
                  style: TextStyle(color: color.withOpacity(0.7), fontSize: 9),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // MENÚ DE ACCIÓN
  void _showItemAction(BuildContext context, Map<String, dynamic> item) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF16213E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                (item['name'] ?? '').toUpperCase(),
                style: const TextStyle(
                  color: Color(0xFFE94560),
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                _descripcionItem(item),
                style: const TextStyle(color: Colors.white70),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE94560),
                ),
                onPressed: () async {
                  Navigator.pop(context);
                  await _handleItemAction(item);
                },
                child: Text(
                  item['type'] == 'weapon' || item['type'] == 'shield'
                      ? "EQUIPAR"
                      : item['type'] == 'consumable' || item['type'] == 'freeze'
                      ? "VER INFO"
                      : "OK",
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  // Lógica real: $pull en Atlas + feedback visual (RNF-04)
  Future<void> _handleItemAction(Map<String, dynamic> item) async {
    if (!mounted) return;

    String mensaje;
    Color color;

    switch (item['type']) {
      case 'consumable':
        mensaje = 'Las pociones solo se usan en combate.';
        color = Colors.orangeAccent;
        break;
      case 'weapon':
        mensaje = '¡Arma lista! Estará en tu hotbar al entrar al nivel.';
        color = Colors.orangeAccent;
        break;
      case 'shield':
        mensaje = '¡Escudo listo! Estará en tu hotbar al entrar al nivel.';
        color = Colors.purpleAccent;
        break;
      case 'freeze':
        mensaje = '¡Esencia lista! Estará en tu hotbar al entrar al nivel.';
        color = Colors.cyanAccent;
        break;
      default:
        mensaje = 'Este ítem no se puede usar desde la mochila.';
        color = Colors.blueAccent;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
