import 'package:flutter/material.dart';

// Callback que el nivel llama cuando el jugador usa un ítem
typedef OnItemUsed = void Function(Map<String, dynamic> item);

class BattleHotbar extends StatefulWidget {
  final List<Map<String, dynamic>> hotbar; // exactamente 3 slots
  final List<Map<String, dynamic>> inventory; // todos los ítems del jugador
  final OnItemUsed onItemUsed;
  final VoidCallback onAttack;
  final bool active; // false cuando no es turno del jugador

  const BattleHotbar({
    super.key,
    required this.hotbar,
    required this.inventory,
    required this.onItemUsed,
    required this.onAttack,
    required this.active,
  });

  @override
  State<BattleHotbar> createState() => _BattleHotbarState();
}

class _BattleHotbarState extends State<BattleHotbar>
    with SingleTickerProviderStateMixin {
  bool _bagOpen = false;
  late AnimationController _animController;
  late Animation<double> _slideAnim;

  // Copia local mutable de los slots
  late List<Map<String, dynamic>> _slots;

  @override
  void initState() {
    super.initState();
    _slots = List.from(widget.hotbar);
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _slideAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void didUpdateWidget(BattleHotbar old) {
    super.didUpdateWidget(old);
    // Sincroniza si el padre cambia el hotbar (ej: poción usada)
    _slots = List.from(widget.hotbar);
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _toggleBag() {
    setState(() => _bagOpen = !_bagOpen);
    if (_bagOpen) {
      _animController.forward();
    } else {
      _animController.reverse();
    }
  }

  // Cuando sueltan un ítem del inventario en un slot
  void _dropItemIntoSlot(int slotIndex, Map<String, dynamic> item) {
    setState(() {
      // Si el ítem ya estaba en otro slot, lo limpia
      for (int i = 0; i < _slots.length; i++) {
        if (_slots[i]['_id'] != null && _slots[i]['_id'] == item['_id']) {
          _slots[i] = {"name": "", "icon": null, "type": "empty"};
        }
      }
      _slots[slotIndex] = item;
    });
    // Propaga el cambio al padre
    for (int i = 0; i < _slots.length; i++) {
      widget.hotbar[i] = _slots[i];
    }
  }

  IconData _iconForItem(Map<String, dynamic> item) {
    // Primero revisa por item_id específico
    switch (item['item_id']) {
      case 'esencia_glacial':
        return Icons.ac_unit;
      case 'flecha_eco':
        return Icons.arrow_upward;
      case 'frasco_nostalgia':
        return Icons.water_drop;
      case 'manto_01':
        return Icons.shield;
      case 'hoja_reforzada':
        return Icons.auto_fix_high;
    }
    // Luego por type genérico
    switch (item['type']) {
      case 'weapon':
        return Icons.colorize;
      case 'heal':
        return Icons.health_and_safety;
      case 'shield':
        return Icons.shield;
      case 'freeze':
        return Icons.ac_unit;
      case 'consumable':
        return Icons.science;
      default:
        return Icons.help_outline;
    }
  }

  Color _colorForItem(Map<String, dynamic> item) {
    switch (item['item_id']) {
      case 'esencia_glacial':
        return Colors.cyanAccent;
      case 'flecha_eco':
        return Colors.greenAccent;
      case 'frasco_nostalgia':
        return Colors.pinkAccent;
      case 'manto_01':
        return Colors.purpleAccent;
      case 'hoja_reforzada':
        return Colors.orangeAccent;
    }
    switch (item['type']) {
      case 'weapon':
        return Colors.orangeAccent;
      case 'heal':
        return Colors.greenAccent;
      case 'shield':
        return Colors.purpleAccent;
      case 'freeze':
        return Colors.cyanAccent;
      case 'consumable':
        return Colors.greenAccent;
      default:
        return Colors.white54;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Panel del inventario (aparece al abrir la mochila)
        SizeTransition(
          sizeFactor: _slideAnim,
          axisAlignment: -1,
          child: _buildInventoryPanel(),
        ),
        const SizedBox(height: 6),
        // Barra principal
        _buildMainBar(),
        const SizedBox(height: 10),
      ],
    );
  }

  // ── BARRA PRINCIPAL ──────────────────────────────────────────────────────
  Widget _buildMainBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // ATACAR fijo
        _attackButton(),
        const SizedBox(width: 6),
        // 3 slots de ítems equipados
        ...List.generate(3, (i) => _equippedSlot(i)),
        const SizedBox(width: 6),
        // Botón mochila
        _bagButton(),
      ],
    );
  }

  Widget _attackButton() {
    return GestureDetector(
      onTap: widget.active ? widget.onAttack : null,
      child: Container(
        width: 60,
        height: 56,
        decoration: BoxDecoration(
          color: widget.active
              ? Colors.orangeAccent.withOpacity(0.2)
              : Colors.grey[900],
          border: Border.all(
            color: widget.active ? Colors.orangeAccent : Colors.grey,
            width: 2.5,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.sports_martial_arts,
              color: widget.active ? Colors.orangeAccent : Colors.grey,
              size: 20,
            ),
            const SizedBox(height: 2),
            Text(
              "ATACAR",
              style: TextStyle(
                color: widget.active ? Colors.white : Colors.grey,
                fontSize: 8,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _equippedSlot(int index) {
    final item = index < _slots.length ? _slots[index] : <String, dynamic>{};
    final isEmpty = item['type'] == 'empty' || item['type'] == null;

    return DragTarget<Map<String, dynamic>>(
      onAcceptWithDetails: (details) => _dropItemIntoSlot(index, details.data),
      builder: (context, candidateData, rejectedData) {
        final isHovering = candidateData.isNotEmpty;
        return GestureDetector(
          onTap: () {
            if (!isEmpty && widget.active) {
              widget.onItemUsed(item);
            }
          },
          child: Container(
            width: 56,
            height: 56,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            decoration: BoxDecoration(
              color: isHovering
                  ? Colors.white24
                  : isEmpty
                  ? Colors.grey[900]
                  : _colorForItem(item).withOpacity(0.15),
              border: Border.all(
                color: isHovering
                    ? Colors.white
                    : isEmpty
                    ? Colors.grey[700]!
                    : _colorForItem(item),
                width: 2.5,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: isEmpty
                ? null
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _iconForItem(item),
                        color: _colorForItem(item),
                        size: 22,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item['name'] ?? '',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 7,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
          ),
        );
      },
    );
  }

  Widget _bagButton() {
    return GestureDetector(
      onTap: _toggleBag,
      child: Container(
        width: 50,
        height: 56,
        decoration: BoxDecoration(
          color: _bagOpen
              ? const Color(0xFFE94560).withOpacity(0.3)
              : Colors.grey[850],
          border: Border.all(
            color: _bagOpen ? const Color(0xFFE94560) : Colors.grey[600]!,
            width: 2.5,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _bagOpen ? Icons.close : Icons.backpack,
              color: _bagOpen ? const Color(0xFFE94560) : Colors.white54,
              size: 22,
            ),
            if (!_bagOpen)
              const Text(
                "...",
                style: TextStyle(color: Colors.white38, fontSize: 10),
              ),
          ],
        ),
      ),
    );
  }

  // ── PANEL DE INVENTARIO ──────────────────────────────────────────────────
  Widget _buildInventoryPanel() {
    // Filtra ítems que no son llaves (no tienen uso en combate)
    final usableItems = widget.inventory
        .where((i) => i['type'] != 'key' && i['type'] != 'empty')
        .toList();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF16213E).withOpacity(0.95),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE94560), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 12,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            "MOCHILA — arrastra al slot para equipar",
            style: TextStyle(
              color: Color(0xFFE94560),
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 10),
          usableItems.isEmpty
              ? const Text(
                  "Tu mochila está vacía.",
                  style: TextStyle(color: Colors.white38, fontSize: 12),
                )
              : Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: usableItems
                      .map((item) => _draggableItem(item))
                      .toList(),
                ),
        ],
      ),
    );
  }

  Widget _draggableItem(Map<String, dynamic> item) {
    final color = _colorForItem(item);
    return Draggable<Map<String, dynamic>>(
      data: item,
      feedback: Material(
        color: Colors.transparent,
        child: _itemChip(item, color, dragging: true),
      ),
      childWhenDragging: Opacity(opacity: 0.3, child: _itemChip(item, color)),
      child: _itemChip(item, color),
    );
  }

  Widget _itemChip(
    Map<String, dynamic> item,
    Color color, {
    bool dragging = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(dragging ? 0.4 : 0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_iconForItem(item), color: color, size: 16),
          const SizedBox(width: 6),
          Text(
            item['name'] ?? '',
            style: TextStyle(
              color: dragging ? color : Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
