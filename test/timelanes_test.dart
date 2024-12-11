import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timelanes/timelanes.dart';

void main() {
  testWidgets('Verify add user button present on ActiveUsers page', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(home: Column(children: [Expanded(child: Timelanes(earliestDate: DateTime.now(), latestDate: DateTime.now()))])));
  });
}
