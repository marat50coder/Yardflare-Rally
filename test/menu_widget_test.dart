import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rallygame/screens/main_menu_screen.dart';
import 'package:rallygame/screens/settings_screen.dart';
import 'package:rallygame/services/game_data.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await GameData.instance.resetProgress();
    await GameData.instance.load();
  });

  testWidgets('main menu shows all primary buttons', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: MainMenuScreen()));
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Play'), findsOneWidget);
    expect(find.text('Upgrades'), findsOneWidget);
    expect(find.text('Skins'), findsOneWidget);
    expect(find.text('Daily Tasks'), findsOneWidget);
    // Endless is locked until level 40 is finished.
    expect(find.textContaining('Endless'), findsOneWidget);
  });

  testWidgets('settings screen shows toggles and links', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: SettingsScreen()));
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Music'), findsOneWidget);
    expect(find.text('Sound Effects'), findsOneWidget);
    expect(find.text('Vibration'), findsOneWidget);
    expect(find.text('Drag to Move'), findsOneWidget);
    // Joystick control has been retired; only drag-to-move remains.
    expect(find.text('Joystick'), findsNothing);
    expect(find.text('Privacy Policy'), findsOneWidget);
    expect(find.text('Support'), findsOneWidget);
    expect(find.text('Reset Progress'), findsOneWidget);
  });

  testWidgets('control mode is always drag to move', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: SettingsScreen()));
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Drag to Move'), findsOneWidget);
    expect(GameData.instance.controlMode.name, 'drag');
  });
}
