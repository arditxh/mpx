import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mpx/views/home_screen.dart';
import 'package:mpx/viewmodels/weather_viewmodel.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('HomeScreen shows app title', (tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => WeatherViewModel(),
        child: const MaterialApp(
          home: HomeScreen(),
        ),
      ),
    );

    expect(find.text('Weather'), findsOneWidget);
  });
}
