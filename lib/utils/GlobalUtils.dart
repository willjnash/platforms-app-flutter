import 'package:intl/intl.dart';

String getTimeExtension() {
  DateTime today = new DateTime.now();
  String year = new DateFormat("yyyy").format(today);
  String month = new DateFormat("MM").format(today);
  String day = new DateFormat("dd").format(today);
  return '/' + year + '/' + month + '/' + day;
}
