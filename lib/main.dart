import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:platforms_app_flutter/models/departures.dart';
import 'package:progress_dialog/progress_dialog.dart';

void main() {
  runApp(PlatformsApp());
}

class PlatformsApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
          // This is the theme of your application.
          //
          // Try running your application with "flutter run". You'll see the
          // application has a blue toolbar. Then, without quitting the app, try
          // changing the primarySwatch below to Colors.green and then invoke
          // "hot reload" (press "r" in the console where you ran "flutter run",
          // or simply save your changes to "hot reload" in a Flutter IDE).
          // Notice that the counter didn't reset back to zero; the application
          // is not restarted.
          primarySwatch: Colors.blueGrey,
          // This makes the visual density adapt to the platform that you run
          // the app on. For desktop platforms, the controls will be smaller and
          // closer together (more dense) than on mobile platforms.
          visualDensity: VisualDensity.adaptivePlatformDensity),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        // additional settings go here
      ),
      home: DeparturePage(title: 'Departures from EUS'),
    );
  }
}

class DeparturePage extends StatefulWidget {
  DeparturePage({Key key, this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  _DeparturePageState createState() => _DeparturePageState();
}

class _DeparturePageState extends State<DeparturePage> {
  String lastUpdated = new DateFormat('HH:mm').format(DateTime.now());
  var departures;

  void _getJson() async {
    ProgressDialog pr = new ProgressDialog(context);
    pr.show();
    final response =
        await http.get('https://api.rtt.io/api/v1/json/search/EUS', headers: {
      HttpHeaders.authorizationHeader:
          "Basic cnR0YXBpX3duYXNoOTA6YjIxOTUyNDMyYWRlODU5OWE1NGM0NzZhYWQzNWM5N2U2MmNiOTk1ZA=="
    });
    if (response.statusCode == 200) {
      departures = new Departures.fromJson(jsonDecode(response.body));
      this.setState(() {
        lastUpdated = new DateFormat('HH:mm').format(DateTime.now());
      });
      pr.hide();
    } else {
      pr.hide();
      throw Exception('Failed to load album');
    }
  }

  ListView getDepartures(Departures departures) {
    if (departures != null && departures.services.isNotEmpty) {
      return ListView(
        children: <Widget>[
          for (var item in departures.services) getDepartureTile(item),
        ],
      );
    } else
      return null;
  }

  Container getDepartureTile(Services item) {
    if (item.locationDetail.platformConfirmed) {
      return new Container(
          color: Colors.lightGreenAccent,
          child: ListTile(
            leading: Text(item.locationDetail.gbttBookedDeparture),
            title: Text(item.locationDetail.destination[0].description,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                )),
            subtitle: Text(item.atocName + ', Platform Confirmed'),
            trailing: Text(item.locationDetail.platform,
                textAlign: TextAlign.center,
                style: item.locationDetail.platformConfirmed
                    ? TextStyle(fontSize: 40.0, fontWeight: FontWeight.bold)
                    : TextStyle(
                        fontSize: 40.0,
                      )),
          ));
    } else {
      return new Container(
          child: ListTile(
            leading: Text(item.locationDetail.gbttBookedDeparture),
            title: Text(item.locationDetail.destination[0].description,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                )),
            subtitle: Text(item.atocName + ', Platform Pending'),
          ));
    }
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
        appBar: AppBar(
          // Here we take the value from the MyHomePage object that was created by
          // the App.build method, and use it to set our appbar title.
          title: Text(widget.title),
          actions: <Widget>[
            // action button
            IconButton(
              icon: Icon(Icons.refresh),
              onPressed: _getJson,
            )
          ],
        ),
        body: Center(
          // Center is a layout widget. It takes a single child and positions it
          // in the middle of the parent.
          child: getDepartures(departures),
        ),
        bottomNavigationBar: BottomAppBar(
          child: new Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Padding(
                padding: EdgeInsets.all(8.0),
                child: Text(
                  'Last updated at $lastUpdated',
                ),
              ),
              IconButton(
                icon: Icon(Icons.compare_arrows),
                onPressed: () {},
              ),
              IconButton(
                icon: Icon(Icons.timer),
                onPressed: () {},
              ),
              IconButton(
                icon: Icon(Icons.edit_location),
                onPressed: () {},
              )
            ],
          ), // This trailing comma makes auto-formatting nicer for build methods.
        ));
  }
}
