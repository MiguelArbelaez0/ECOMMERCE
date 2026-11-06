import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:ecommerce_clean_app/core/network/api_client.dart';
import 'package:ecommerce_clean_app/injection/injection_container.dart';
import 'package:ecommerce_clean_app/main.dart';
import '../test/support/fixtures.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('shopping flow and Hive reopen on Android with controlled HTTP',
      (tester) async {
    final dir = await Directory.systemTemp.createTemp('ecommerce_integration_');
    Future<void> start() async {
      await initDependencies(storagePath: dir.path);
      getIt<ApiClient>().dio.httpClientAdapter =
          FixtureAdapter(data: jsonEncode([productJson]));
      await tester.pumpWidget(const EcommerceApp());
      await tester.pumpAndSettle();
    }

    try {
      await start();
      expect(find.text('Test shirt'), findsOneWidget);
      await tester.tap(find.text('Test shirt'));
      await tester.pumpAndSettle();
      expect(find.text('A comfortable shirt'), findsOneWidget);
      await tester.tap(find.text('Add to cart'));
      await tester.pumpAndSettle();
      expect(find.text('Added to cart'), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Open cart'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Increase quantity'));
      await tester.pumpAndSettle();
      expect(find.text('Total: \$0.20'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      await getIt.reset();
      await start();
      await tester.tap(find.byTooltip('Open cart'));
      await tester.pumpAndSettle();
      expect(find.text('2'), findsOneWidget);
      expect(find.text('Total: \$0.20'), findsOneWidget);
      await tester.tap(find.byTooltip('Decrease quantity'));
      await tester.pumpAndSettle();
      expect(find.text('Total: \$0.10'), findsOneWidget);
      await tester.tap(find.text('Demo checkout'));
      await tester.pumpAndSettle();
      expect(
          find.text(
              'This is a demo. No payment is taken and no order is placed.'),
          findsOneWidget);
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Remove product'));
      await tester.pumpAndSettle();
      expect(find.text('Your cart is empty'), findsOneWidget);
      expect(tester.takeException(), isNull);
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      await getIt.reset();
      await dir.delete(recursive: true);
    }
  });
}
