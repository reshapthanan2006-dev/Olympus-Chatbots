import 'package:flutter/material.dart';

import 'Screens/launcher_screen.dart';

void main() {
  runApp(const NearFixApp());
}

class NearFixApp extends StatelessWidget {
  final Widget? home;

  const NearFixApp({super.key, this.home});

  @override
  Widget build(BuildContext context) {
    const primaryOrange = Color(0xFFEA900B);
    const darkNavy = Color(0xFF161B35);
    const offWhite = Color(0xFFF9F8F5);
    const pureWhite = Color(0xFFFFFFFF);
    const softCream = Color(0xFFFBF2E9);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'NearFix',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: offWhite,
        colorScheme: const ColorScheme(
          brightness: Brightness.light,
          primary: primaryOrange,
          onPrimary: darkNavy,
          secondary: darkNavy,
          onSecondary: pureWhite,
          error: Color(0xFFB3261E),
          onError: pureWhite,
          surface: pureWhite,
          onSurface: darkNavy,
          surfaceContainerHighest: softCream,
        ),
      ),
      home: home ?? const NearFixLauncherScreen(),
    );
  }
}
