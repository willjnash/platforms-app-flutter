import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_time_picker_spinner/flutter_time_picker_spinner.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:platforms_app_flutter/models/departures.dart';
import 'package:platforms_app_flutter/pages/ServiceDetailPage.dart';
import 'package:progress_dialog/progress_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class DeparturePage extends StatefulWidget {
  DeparturePage({Key key, this.title, this.sharedPreferences }) : super(key: key);
  final String title;
  final SharedPreferences sharedPreferences;

  @override
  _DeparturePageState createState() => _DeparturePageState();
}

class _DeparturePageState extends State<DeparturePage> {
  SharedPreferences prefs;
  String lastUpdated = new DateFormat('HH:mm').format(DateTime.now());
  String station;
  String stationDesc;
  String time;
  Text title;
  var services;
  bool showingArrivals = false;

  SimpleDialog stationMenu() {
    return new SimpleDialog(
      title: const Text('Select station'),
      children: <Widget>[
        new SimpleDialogOption(
          onPressed: () {
            _handleStationChange('BFR', 'Blackfriars');
          },
          child: const Text('Blackfriars'),
        ),
        new SimpleDialogOption(
          onPressed: () {
            _handleStationChange('CST', 'Cannon Street');
          },
          child: const Text('Cannon Street'),
        ),
        new SimpleDialogOption(
          onPressed: () {
            _handleStationChange('CHX', 'Charing Cross');
          },
          child: const Text('Charing Cross'),
        ),
        new SimpleDialogOption(
          onPressed: () {
            _handleStationChange('CTK', 'City Thameslink');
          },
          child: const Text('City Thameslink'),
        ),
        new SimpleDialogOption(
          onPressed: () {
            _handleStationChange('EUS', 'Euston');
          },
          child: const Text('Euston'),
        ),
        new SimpleDialogOption(
          onPressed: () {
            _handleStationChange('FST', 'Fenchurch Street');
          },
          child: const Text('Fenchurch Street'),
        ),
        new SimpleDialogOption(
          onPressed: () {
            _handleStationChange('KGX', 'Kings Cross');
          },
          child: const Text('Kings Cross'),
        ),
        new SimpleDialogOption(
          onPressed: () {
            _handleStationChange('LST', 'Liverpool Street');
          },
          child: const Text('Liverpool Street'),
        ),
        new SimpleDialogOption(
          onPressed: () {
            _handleStationChange('LBG', 'London Bridge');
          },
          child: const Text('London Bridge'),
        ),
        new SimpleDialogOption(
          onPressed: () {
            _handleStationChange('MYB', 'Marylebone');
          },
          child: const Text('Marylebone'),
        ),
        new SimpleDialogOption(
          onPressed: () {
            _handleStationChange('MOG', 'Moorgate');
          },
          child: const Text('Moorgate'),
        ),
        new SimpleDialogOption(
          onPressed: () {
            _handleStationChange('OLD', 'Old Street');
          },
          child: const Text('Old Street'),
        ),
        new SimpleDialogOption(
          onPressed: () {
            _handleStationChange('PAD', 'Paddington');
          },
          child: const Text('Paddington'),
        ),
        new SimpleDialogOption(
          onPressed: () {
            _handleStationChange('STP', 'St Pancras');
          },
          child: const Text('St Pancras (Domestic)'),
        ),
        new SimpleDialogOption(
          onPressed: () {
            _handleStationChange('VXH', 'Vauxhall');
          },
          child: const Text('Vauxhall'),
        ),
        new SimpleDialogOption(
          onPressed: () {
            _handleStationChange('VIC', 'Victoria');
          },
          child: const Text('Victoria'),
        ),
        new SimpleDialogOption(
          onPressed: () {
            _handleStationChange('WAT', 'Waterloo');
          },
          child: const Text('Waterloo'),
        ),
        new SimpleDialogOption(
          onPressed: () {
            _handleStationChange('WAE', 'Waterloo East');
          },
          child: const Text('Waterloo East'),
        ),
      ],
    );
  }

  SimpleDialog selectTimeMenu() {
    return new SimpleDialog(
        title: const Text('Select time (today)'),
        children: <Widget>[
          new TimePickerSpinner(
            is24HourMode: true,
            normalTextStyle: TextStyle(fontSize: 24),
            highlightedTextStyle:
                TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            spacing: 50,
            itemHeight: 80,
            isForce2Digits: true,
            onTimeChange: (chosenTime) {
              time = new DateFormat("HHmm").format(chosenTime);
            },
          ),
          new FlatButton(
              child: const Text('Reset to now', style: TextStyle(fontSize: 20)),
              onPressed: _handleResetTime),
          new FlatButton(
              child: const Text('Apply', style: TextStyle(fontSize: 20)),
              onPressed: _handleTimeChange)
        ]);
  }

  SimpleDialog aboutDialog() {
    return new SimpleDialog(
        title: const Text(
          'London Platforms',
          textAlign: TextAlign.center,
        ),
        children: <Widget>[
          Padding(
            padding: EdgeInsets.only(left: 16.0, right: 16.0, bottom: 16.0),
            child:
                Text('Data used with the kind permission of RealTimeTrains.'),
          ),
          Padding(
            padding: EdgeInsets.only(left: 16.0, right: 16.0, bottom: 16.0),
            child: Text('Feedback appreciated! platformfeedback@icloud.com'),
          ),
          Padding(
            padding: EdgeInsets.only(left: 16.0, right: 16.0),
            child: GestureDetector(
                child: Text("Privacy Policy",
                    style: TextStyle(
                        decoration: TextDecoration.underline,
                        color: Colors.blue)),
                onTap: () {
                  launch(
                      'https://platformsapp.wordpress.com/london-platforms-privacy-notice/');
                }),
          ),
          new FlatButton(
              child: const Text('OK', style: TextStyle(fontSize: 20)),
              onPressed: () {
                Navigator.of(context).pop();
              })
        ]);
  }

  @override
  Future<void> initState() {
    super.initState();
    populateVariables();
    new Future.delayed(Duration.zero, () {
      _getJson();
    });
  }

  void populateVariables(){
    prefs = widget.sharedPreferences;
    station = prefs.getString('savedStation') ?? 'EUS';
    stationDesc = prefs.getString('savedStationDesc') ?? 'Euston';
  }

  void _handleStationChange(String newStationCode, String newStationDesc) {
    station = newStationCode;
    stationDesc = newStationDesc;
    prefs.setString('savedStation', newStationCode);
    prefs.setString('savedStationDesc', newStationDesc);
    Navigator.of(context).pop();
    _getJson();
  }

  void _handleResetTime() {
    time = null;
    Navigator.of(context).pop();
    _getJson();
  }

  void _handleTimeChange() {
    Navigator.of(context).pop();
    _getJson();
  }

  String _getTimeExtension() {
    if (time != null) {
      DateTime today = new DateTime.now();
      String year = new DateFormat("yyyy").format(today);
      String month = new DateFormat("MM").format(today);
      String day = new DateFormat("dd").format(today);
      return '/' + year + '/' + month + '/' + day + '/' + time;
    } else
      return '';
  }

  void _toggleDeparturesOrArrivals() {
    showingArrivals = !showingArrivals;
    _getJson();
  }

  void _getJson() async {
    ProgressDialog pr = new ProgressDialog(context);
    await pr.show();
    var response;
    if (showingArrivals) {
      response = await http.get(
          'https://api.rtt.io/api/v1/json/search/' +
              station +
              _getTimeExtension() +
              '/arrivals',
          headers: {
            HttpHeaders.authorizationHeader:
                "Basic cnR0YXBpX3duYXNoOTA6YjIxOTUyNDMyYWRlODU5OWE1NGM0NzZhYWQzNWM5N2U2MmNiOTk1ZA=="
          });
    } else {
      response = await http.get(
          'https://api.rtt.io/api/v1/json/search/' +
              station +
              _getTimeExtension(),
          headers: {
            HttpHeaders.authorizationHeader:
                "Basic cnR0YXBpX3duYXNoOTA6YjIxOTUyNDMyYWRlODU5OWE1NGM0NzZhYWQzNWM5N2U2MmNiOTk1ZA=="
          });
    }
    if (response.statusCode == 200) {
      services = new Departures.fromJson(jsonDecode(response.body));
      this.setState(() {
        lastUpdated = new DateFormat('HH:mm').format(DateTime.now());
      });
      await pr.hide();
    } else {
      await pr.hide();
      throw Exception('Failed to load departures');
    }
  }

  ListView getDepartures(Departures departures) {
    if (departures != null && departures.services == null) {
      return ListView(
        children: <Widget>[
          ListTile(
            title: Text('No services at this time',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                )),
          )
        ],
      );
    } else if (departures != null && departures.services.isNotEmpty) {
      return ListView(
        children: <Widget>[
          for (var item in departures.services)
            showingArrivals ? getArrivalTile(item) : getDepartureTile(item),
        ],
      );
    } else
      return null;
  }

  Container getDepartureTile(Services item) {
    if (item.locationDetail.platformConfirmed != null &&
        item.locationDetail.platformConfirmed) {
      return new Container(
          color: Colors.lightGreenAccent,
          child: ListTile(
            leading: Text(item.locationDetail.gbttBookedDeparture,
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.black)),
            title: Text(item.locationDetail.destination[0].description,
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.black)),
            subtitle: Text(item.atocName + ', Platform Confirmed',
                style: TextStyle(color: Colors.black)),
            trailing: Text(item.locationDetail.platform,
                textAlign: TextAlign.center,
                style: item.locationDetail.platformConfirmed
                    ? TextStyle(
                        fontSize: 40.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.black)
                    : TextStyle(fontSize: 40.0, color: Colors.black)),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      ServiceDetailPage(serviceUid: item.serviceUid),
                ),
              );
            },
          ));
    } else {
      return new Container(
          child: ListTile(
        leading: Text(item.locationDetail.gbttBookedDeparture,
            style: TextStyle(fontWeight: FontWeight.bold)),
        title: Text(item.locationDetail.destination[0].description,
            style: TextStyle(
              fontWeight: FontWeight.bold,
            )),
        subtitle: Text(item.atocName +
            (item.locationDetail.platform != null
                ? ', Platform Pending (expected ' +
                    item.locationDetail.platform +
                    ')'
                : '')),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  ServiceDetailPage(serviceUid: item.serviceUid),
            ),
          );
        },
      ));
    }
  }

  Container getArrivalTile(Services item) {
    return new Container(
      child: ListTile(
        leading: Text(item.locationDetail.destination[0].publicTime),
        title: Text(item.locationDetail.origin[0].description,
            style: TextStyle(
              fontWeight: FontWeight.bold,
            )),
        subtitle: Text(item.atocName),
        trailing: Text(
          item.locationDetail.platform,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 40.0),
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  ServiceDetailPage(serviceUid: item.serviceUid),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    title = showingArrivals
        ? Text('Arrivals into ' +
            stationDesc +
            (time != null ? ' at ' + time : ''))
        : Text('Departures from ' +
            stationDesc +
            (time != null ? ' at ' + time : ''));
    return Scaffold(
        appBar: AppBar(
          title: FittedBox(fit: BoxFit.fitWidth, child: title),
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
          child: getDepartures(services),
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
                onPressed: _toggleDeparturesOrArrivals,
              ),
              IconButton(
                icon: Icon(Icons.timer),
                onPressed: () {
                  showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return selectTimeMenu();
                      });
                },
              ),
              IconButton(
                icon: Icon(Icons.edit_location),
                onPressed: () {
                  showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return stationMenu();
                      });
                },
              ),
              IconButton(
                icon: Icon(Icons.info),
                onPressed: () {
                  showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return aboutDialog();
                      });
                },
              )
            ],
          ), // This trailing comma makes auto-formatting nicer for build methods.
        ));
  }
}
