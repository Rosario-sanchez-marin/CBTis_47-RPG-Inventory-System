import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String base = 'http://localhost:3000';

  static Future<void> saveSession(String playerId, String username) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('playerId', playerId);
    await prefs.setString('username', username);
  }

  static Future<List<dynamic>> getLevels() async {
    final res = await http.get(Uri.parse('$base/levels'));
    if (res.statusCode != 200) throw jsonDecode(res.body)['error'];
    return jsonDecode(res.body);
  }

  static Future<String?> getPlayerId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('playerId');
  }

  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  static Future<Map<String, dynamic>> register(
    String username,
    String email,
    String password,
  ) async {
    final res = await http.post(
      Uri.parse('$base/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'email': email,
        'password': password,
      }),
    );
    if (res.statusCode != 200) throw jsonDecode(res.body)['error'];
    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> login(
    String email,
    String password,
  ) async {
    final res = await http.post(
      Uri.parse('$base/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    if (res.statusCode != 200) throw jsonDecode(res.body)['error'];
    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> getPlayer() async {
    final playerId = await getPlayerId();
    final res = await http.get(Uri.parse('$base/player/$playerId'));
    if (res.statusCode != 200) throw jsonDecode(res.body)['error'];
    return jsonDecode(res.body);
  }

  static Future<List<dynamic>> getInventory() async {
    final playerId = await getPlayerId();
    final res = await http.get(Uri.parse('$base/inventory/$playerId'));
    if (res.statusCode != 200) throw jsonDecode(res.body)['error'];
    return jsonDecode(res.body);
  }

  static Future<List<dynamic>> addItem(Map<String, dynamic> item) async {
    final playerId = await getPlayerId();
    final res = await http.post(
      Uri.parse('$base/inventory/item'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'playerId': playerId, 'item': item}),
    );
    if (res.statusCode != 200) throw jsonDecode(res.body)['error'];
    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> useItem(String itemId) async {
    final playerId = await getPlayerId();
    final res = await http.delete(
      Uri.parse('$base/inventory/$playerId/$itemId'),
    );
    if (res.statusCode != 200) throw jsonDecode(res.body)['error'];
    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> saveProgress({
    required int nivelCompletado,
    required int xpGanado,
    bool nuevaLlave = false,
  }) async {
    final playerId = await getPlayerId();
    final res = await http.patch(
      Uri.parse('$base/player/level'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'playerId': playerId,
        'nivelCompletado': nivelCompletado,
        'xpGanado': xpGanado,
        'nuevaLlave': nuevaLlave,
      }),
    );
    if (res.statusCode != 200) throw jsonDecode(res.body)['error'];
    return jsonDecode(res.body);
  }

  // Actualiza el HP del jugador en Atlas.
  // Llámalo con 100 al iniciar un nivel (reset),
  // o con el HP actual después de recibir daño.
  static Future<void> resetHp(int hp) async {
    final playerId = await getPlayerId();
    final res = await http.patch(
      Uri.parse('$base/player/reset-hp'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'playerId': playerId, 'hp': hp}),
    );
    if (res.statusCode != 200) throw jsonDecode(res.body)['error'];
  }
}
