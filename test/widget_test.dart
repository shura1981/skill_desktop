import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:desktop_app/windows/main_window.dart';

void main() {
  testWidgets('MainWindowPage renders MenuBar with Abrir and Ayuda',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: MainWindowPage()),
      ),
    );

    // MenuBar labels should be present
    expect(find.text('Abrir'), findsOneWidget);
    expect(find.text('Ayuda'), findsOneWidget);
  });

  testWidgets('Abrir submenu has 3 ventana items', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: MainWindowPage()),
      ),
    );

    // Open the Abrir submenu
    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();

    expect(find.text('Ventana 1'), findsOneWidget);
    expect(find.text('Ventana 2'), findsOneWidget);
    expect(find.text('Ventana 3'), findsOneWidget);
  });
}
