import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_todo/core/constants/app_constants.dart';
import 'package:smart_todo/core/theme/app_theme.dart';
import 'package:smart_todo/core/utils/prefs_helper.dart';
import 'package:smart_todo/presentation/providers/theme_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;

  Future<ThemeProvider> buildProvider([
    Map<String, Object> stored = const <String, Object>{},
  ]) async {
    SharedPreferences.setMockInitialValues(stored);
    prefs = await SharedPreferences.getInstance();
    return ThemeProvider(PrefsHelper(prefs));
  }

  Widget harness(ThemeProvider provider) {
    return ChangeNotifierProvider<ThemeProvider>.value(
      value: provider,
      child: Consumer<ThemeProvider>(
        builder: (context, theme, _) => MaterialApp(
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: theme.flutterThemeMode,
          home: Scaffold(
            body: Builder(
              builder: (context) => Column(
                children: [
                  Text('brightness:${Theme.of(context).brightness.name}'),
                  TextButton(
                    onPressed: () => theme.setThemeMode(AppThemeMode.dark),
                    child: const Text('switch to dark'),
                  ),
                  TextButton(
                    onPressed: () => theme.setThemeMode(AppThemeMode.light),
                    child: const Text('switch to light'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('defaults to following the system when nothing is stored', (
    tester,
  ) async {
    final provider = await buildProvider();

    expect(provider.themeMode, AppThemeMode.system);
    expect(provider.flutterThemeMode, ThemeMode.system);

    await tester.pumpWidget(harness(provider));
    expect(find.text('brightness:light'), findsOneWidget);
  });

  testWidgets('switching to dark repaints the whole app', (tester) async {
    final provider = await buildProvider();
    await tester.pumpWidget(harness(provider));

    await tester.tap(find.text('switch to dark'));
    await tester.pumpAndSettle();

    expect(find.text('brightness:dark'), findsOneWidget);
    expect(provider.themeMode, AppThemeMode.dark);
  });

  testWidgets('switching back to light repaints again', (tester) async {
    final provider = await buildProvider({
      AppConstants.themeModeKey: 'dark',
    });
    await tester.pumpWidget(harness(provider));
    expect(find.text('brightness:dark'), findsOneWidget);

    await tester.tap(find.text('switch to light'));
    await tester.pumpAndSettle();

    expect(find.text('brightness:light'), findsOneWidget);
  });

  testWidgets('persists the choice for the next launch', (tester) async {
    final provider = await buildProvider();
    await tester.pumpWidget(harness(provider));

    await tester.tap(find.text('switch to dark'));
    await tester.pumpAndSettle();

    expect(prefs.getString(AppConstants.themeModeKey), 'dark');

    // A fresh provider over the same store is what the next cold start does.
    final restored = ThemeProvider(PrefsHelper(prefs));
    expect(restored.themeMode, AppThemeMode.dark);
  });

  testWidgets('an unknown stored value falls back to system', (tester) async {
    // Guards against a renamed or corrupted preference leaving the app with no
    // usable theme at all.
    final provider = await buildProvider({
      AppConstants.themeModeKey: 'hotdog-stand',
    });

    expect(provider.themeMode, AppThemeMode.system);
  });

  testWidgets('ignores a redundant selection', (tester) async {
    final provider = await buildProvider();
    var notifications = 0;
    provider.addListener(() => notifications++);

    provider.setThemeMode(AppThemeMode.system);
    expect(notifications, 0, reason: 'no change means no rebuild');

    provider.setThemeMode(AppThemeMode.dark);
    expect(notifications, 1);
  });
}
