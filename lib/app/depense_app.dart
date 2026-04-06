import 'package:depense_game/app/bootstrap/app_bootstrap.dart';
import 'package:depense_game/app/screens/title_screen.dart';
import 'package:depense_game/app/theme/app_theme.dart';
import 'package:flutter/material.dart';

class DepenseApp extends StatelessWidget {
  const DepenseApp({super.key, required this.bootstrap});

  final AppBootstrap bootstrap;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Depense Game',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: TitleScreen(bootstrap: bootstrap),
    );
  }
}
