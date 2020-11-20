import 'package:platforms_app_flutter/pages/DeparturePage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('getDateExtension parses string correctly', () {
    expect(result, '/2020/01/01');
  });
  test('formatTime parses string correctly', () {
    var result = formatTime("1515");
    expect(result, '15:15');
  });
}