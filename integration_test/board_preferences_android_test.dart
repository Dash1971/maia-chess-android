import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:maia_chess/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../test/board_input_preferences_test.dart' as input;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('Android plugin persists and reloads board preferences', (
    tester,
  ) async {
    final storage = await SharedPreferences.getInstance();
    final before = storage.getString(boardPreferenceKey);
    final controller = BoardPreferencesController();
    try {
      await controller.initialize();
      const choice = BoardPreferences(
        board: BoardDesign.blue,
        pieces: PieceDesign.merida,
        coordinates: false,
        animation: false,
        lastMove: false,
      );
      await controller.select(choice);
      expect(controller.persistenceFailed, isFalse);
      await storage.reload();
      final reloaded = BoardPreferencesController();
      await reloaded.initialize();
      expect(reloaded.value.encode(), choice.encode());
      await reloaded.select(const BoardPreferences());
      reloaded.dispose();
    } finally {
      controller.dispose();
      if (before == null) {
        await storage.remove(boardPreferenceKey);
      } else {
        await storage.setString(boardPreferenceKey, before);
      }
    }
  });
  input.main();
}
