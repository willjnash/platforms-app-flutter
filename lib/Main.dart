import 'package:flutter/material.dart';
import 'package:flutter_config/flutter_config.dart';
import 'package:platforms_app_flutter/pages/DeparturePage.dart';
import 'package:shared_preferences/shared_preferences.dart';

SharedPreferences sharedPreferences;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  sharedPreferences =
      await SharedPreferences.getInstance();
  await FlutterConfig.loadEnvVariables();
  runApp(PlatformsApp());
}

class PlatformsApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Platforms App',
      theme: ThemeData(
          primarySwatch: Colors.blueGrey,
          visualDensity: VisualDensity.adaptivePlatformDensity),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
      ),
      home: DeparturePage(title: 'Departures from EUS', sharedPreferences: sharedPreferences,),
    );
  }
}
