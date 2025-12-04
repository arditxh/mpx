import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mpx/views/home_screen.dart';
import 'package:mpx/viewmodels/weather_viewmodel.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('Shows empty state text when no cities added', (tester) async {
    final vm = WeatherViewModel();

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: vm,
        child: const MaterialApp(home: HomeScreen()),
      ),
    );

    expect(find.text('No cities yet'), findsOneWidget);
  });
}
