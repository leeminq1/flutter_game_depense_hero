import 'package:depense_game/app/bootstrap/app_bootstrap.dart';
import 'package:depense_game/app/depense_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  final bootstrap = AppBootstrap();
  await bootstrap.initialize();

  runApp(DepenseApp(bootstrap: bootstrap));
}
