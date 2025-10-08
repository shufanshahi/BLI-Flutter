import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'features/note/views/home_page.dart';
import 'features/settings/providers/settings_providers.dart';

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final fontSize = ref.watch(fontSizeProvider);

    return MaterialApp(
      title: 'Notes App',
      themeMode: themeMode,
      theme: _buildTheme(Brightness.light, fontSize),
      darkTheme: _buildTheme(Brightness.dark, fontSize),
      home: const HomePage(),
      debugShowCheckedModeBanner: false,
    );
  }

  ThemeData _buildTheme(Brightness brightness, double fontSize) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: Colors.deepPurple,
      brightness: brightness,
    );

    return ThemeData(
      colorScheme: colorScheme,
      useMaterial3: true,
      textTheme: _buildTextTheme(fontSize),
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.inversePrimary,
        foregroundColor: colorScheme.onInverseSurface,
        elevation: 0,
        centerTitle: true,
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
      ),
    );
  }

  TextTheme _buildTextTheme(double baseFontSize) {
    return TextTheme(
      displayLarge: TextStyle(fontSize: baseFontSize + 20),
      displayMedium: TextStyle(fontSize: baseFontSize + 16),
      displaySmall: TextStyle(fontSize: baseFontSize + 12),
      headlineLarge: TextStyle(fontSize: baseFontSize + 16),
      headlineMedium: TextStyle(fontSize: baseFontSize + 12),
      headlineSmall: TextStyle(fontSize: baseFontSize + 8),
      titleLarge: TextStyle(fontSize: baseFontSize + 6),
      titleMedium: TextStyle(fontSize: baseFontSize + 4),
      titleSmall: TextStyle(fontSize: baseFontSize + 2),
      bodyLarge: TextStyle(fontSize: baseFontSize + 2),
      bodyMedium: TextStyle(fontSize: baseFontSize),
      bodySmall: TextStyle(fontSize: baseFontSize - 2),
      labelLarge: TextStyle(fontSize: baseFontSize),
      labelMedium: TextStyle(fontSize: baseFontSize - 1),
      labelSmall: TextStyle(fontSize: baseFontSize - 2),
    );
  }
}
