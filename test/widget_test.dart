import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:billing_app/main.dart';

void main() {
  testWidgets('BillingApp UI Smoke Test', (WidgetTester tester) async {
    // Set typical desktop dimensions for Windows and Mac
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(const BillingApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Verify app loaded with navigation destinations
    expect(find.text('Create Bill'), findsWidgets);
    expect(find.text('Invoices Archive'), findsWidgets);
    expect(find.text('Products Catalog'), findsWidgets);
    expect(find.text('Settings'), findsWidgets);
  });
}
