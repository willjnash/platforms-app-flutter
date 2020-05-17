import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:platforms_app_flutter/models/departures.dart';
import 'package:progress_dialog/progress_dialog.dart';


class DeparturePage extends StatefulWidget {
  DeparturePage({Key key, this.title}) : super(key: key);
  final String title;
  @override
  _DeparturePageState createState() => _DeparturePageState();
}

class _DeparturePageState extends State<DeparturePage> {
  String lastUpdated = new DateFormat('HH:mm').format(DateTime.now());
  var departures;

  @override
  void initState() {
    super.initState();
    new Future.delayed(Duration.zero, () {
      _getJson();
    });
  }

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
    return Scaffold(
        appBar: AppBar(
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