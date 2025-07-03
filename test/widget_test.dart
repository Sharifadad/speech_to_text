import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:worldchat/main.dart';
//import 'package:worldchat_android/main.dart'; // Ensure this path is correct

void main() {
  testWidgets('MyApp renders correctly', (WidgetTester tester) async {
    // Build our app
    await tester.pumpWidget(const MyApp());

    // Verify GetMaterialApp is used
    expect(find.byType(GetMaterialApp), findsOneWidget);

    // Verify initial route is set
    final getMaterialApp = tester.widget<GetMaterialApp>(find.byType(GetMaterialApp));
    expect(getMaterialApp.initialRoute, '/splash');
  });

  testWidgets('AuthWrapper shows loading initially', (WidgetTester tester) async {
    // Build AuthWrapper directly
    await tester.pumpWidget(
      MaterialApp(
        home: AuthWrapper(),
      ),
    );

    // Verify loading indicator is shown
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}