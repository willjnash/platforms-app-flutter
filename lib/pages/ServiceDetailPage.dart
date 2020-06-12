import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:platforms_app_flutter/models/servicedetail.dart';
import 'package:progress_dialog/progress_dialog.dart';
import 'package:http/http.dart' as http;

class ServiceDetailPage extends StatefulWidget {
  final String serviceUid;

  ServiceDetailPage({Key key, @required this.serviceUid}) : super(key: key);

  @override
  _ServiceDetailPageState createState() => _ServiceDetailPageState();
}

class _ServiceDetailPageState extends State<ServiceDetailPage> {
  ServiceDetail serviceDetail;

  @override
  void initState() {
    super.initState();
    new Future.delayed(Duration.zero, () {
      _getJson();
    });
  }

  String _getTimeExtension() {
    DateTime today = new DateTime.now();
    String year = new DateFormat("yyyy").format(today);
    String month = new DateFormat("MM").format(today);
    String day = new DateFormat("dd").format(today);
    return '/' + year + '/' + month + '/' + day;
  }

  void _getJson() async {
    ProgressDialog pr = new ProgressDialog(context);
    await pr.show();
    var response;
    response = await http.get(
        'https://api.rtt.io/api/v1/json/service/' +
            widget.serviceUid +
            _getTimeExtension(),
        headers: {
          HttpHeaders.authorizationHeader:
              "Basic cnR0YXBpX3duYXNoOTA6YjIxOTUyNDMyYWRlODU5OWE1NGM0NzZhYWQzNWM5N2U2MmNiOTk1ZA=="
        });
    if (response.statusCode == 200) {
      setState(() {
        serviceDetail = new ServiceDetail.fromJson(jsonDecode(response.body));
      });
      await pr.hide();
    } else {
      await pr.hide();
      throw Exception('Failed to load service detail');
    }
  }

  Container getContent() {
    if (serviceDetail != null) {
      return new Container(
          child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          FittedBox(
              child: Text(
            serviceDetail.trainIdentity + ' ' + serviceDetail.atocName,
            style: TextStyle(fontSize: 15),
          )),
          FittedBox(child: Text(' ')),
          FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                  serviceDetail.origin[0].publicTime +
                      ' to ' +
                      serviceDetail.destination[0].description,
                  style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold))),
          FittedBox(child: Text(' ')),
          FittedBox(
              child: Text('Calling points:', style: TextStyle(fontSize: 20))),
          FittedBox(child: Text(' ')),
          Flexible(child: getDepartureList())
        ],
      ));
    } else
      return null;
  }

  ListView getDepartureList() {
    return new ListView(
        children: serviceDetail.locations
            .map<Widget>((item) => item.isPublicCall &&
                    (item.origin[0].description != item.description) &&
                    item.gbttBookedArrival != null
                ? new Text(
                    item.description +
                        ' (' +
                        item.gbttBookedArrival +
                        ')' +
                        (item.destination[0].description != item.description
                            ? ', '
                            : ''),
                    style: TextStyle(fontSize: 20),
                  )
                : Container())
            .toList());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Service Detail'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: getContent(),
      ),
    );
  }
}
