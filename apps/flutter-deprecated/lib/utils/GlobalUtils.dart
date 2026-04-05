
import 'package:intl/intl.dart';

String getDateExtension(String serviceDate) {
  return '/' + serviceDate.substring(0,4) + '/' + serviceDate.substring(5, 7)
      + '/' + serviceDate.substring(8);
}

String formatTime(String time){
  return time.substring(0,2) + ':' + time.substring(2,4);
}

String getTimeExtension(String time) {
  if (time != null) {
    DateTime today = new DateTime.now();
    String year = new DateFormat("yyyy").format(today);
    String month = new DateFormat("MM").format(today);
    String day = new DateFormat("dd").format(today);
    return '/' + year + '/' + month + '/' + day + '/' + time;
  } else
    return '';
}
