
String getDateExtension(String serviceDate) {
  return '/' + serviceDate.substring(0,4) + '/' + serviceDate.substring(5, 7)
      + '/' + serviceDate.substring(8);
}

String formatTime(String time){
  return time.substring(0,2) + ':' + time.substring(2,4);
}
