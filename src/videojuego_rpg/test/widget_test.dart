import 'package:flutter_test/flutter_test.dart';

// 1. Asegúrate de que este import coincida con el nombre de tu proyecto
import 'package:videojuego_rpg/main.dart';

void main() {
  testWidgets('Nexus RPG login smoke test', (WidgetTester tester) async {
    // 2. Cambiamos MyApp() por NexusRPG()
    await tester.pumpWidget(const NexusRPG());

    // 3. Como ya no tenemos un contador, buscamos el título del juego
    // Esto verificará que la pantalla de Login cargó correctamente
    expect(find.text('NEXUS RPG'), findsOneWidget);
    expect(find.text('CREAR PERFIL'), findsOneWidget);
  });
}
