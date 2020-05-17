import 'package:flutter/material.dart';
import 'package:platforms_app_flutter/pages/DeparturePage.dart';

void main() {
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
      home: DeparturePage(title: 'Departures from EUS'),
    );
  }
}
