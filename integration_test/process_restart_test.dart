import 'dart:convert';
import 'dart:io';

import 'package:ecommerce_clean_app/core/network/api_client.dart';
import 'package:ecommerce_clean_app/injection/injection_container.dart';
import 'package:ecommerce_clean_app/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';

import '../test/support/fixtures.dart';

/// Run seed and verify in separate app processes using the same unique run ID.
/// A dedicated documents subdirectory never points to the user's normal cart.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  const runId = String.fromEnvironment('PERSISTENCE_RUN_ID');
  const phase = String.fromEnvironment('PERSISTENCE_PHASE');

  testWidgets('cart survives process restart: $phase', (tester) async {
    expect(RegExp(r'^[a-zA-Z0-9_-]{8,80}$').hasMatch(runId), isTrue,
        reason: 'Provide a unique PERSISTENCE_RUN_ID for both executions.');
    expect(['seed', 'verify'], contains(phase));
    final documents = await getApplicationDocumentsDirectory();
    final directory = Directory('${documents.path}/ecommerce_restart_$runId');
    final cartFile = File('${directory.path}/cart_box.hive');
    expect(await cartFile.exists(), phase == 'verify',
        reason: phase == 'seed'
            ? 'Seed requires a fresh run ID.'
            : 'The previous process must have persisted this run in documents.');
    await directory.create(recursive: true);
    await initDependencies(storagePath: directory.path);
    getIt<ApiClient>().dio.httpClientAdapter = FixtureAdapter(
      data: jsonEncode([
        {...productJson, 'price': 19.99}
      ]),
    );
    try {
      await tester.pumpWidget(const EcommerceApp());
      await tester.pumpAndSettle();
      expect(find.text('Test shirt'), findsOneWidget);
      if (phase == 'seed') {
        await tester.tap(find.text('Test shirt'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Add to cart'));
        await tester.pumpAndSettle();
        expect(find.text('Added to cart'), findsOneWidget);
        await tester.pageBack();
        await tester.pumpAndSettle();
      }
      await tester.tap(find.byTooltip('Open cart'));
      await tester.pumpAndSettle();
      if (phase == 'seed') {
        await tester.tap(find.byTooltip('Increase quantity'));
        await tester.pumpAndSettle();
        await tester.tap(find.byTooltip('Increase quantity'));
        await tester.pumpAndSettle();
      }
      expect(find.text('Test shirt'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      expect(find.text('Total: \$59.97'), findsOneWidget);
      expect(tester.takeException(), isNull);
    } finally {
      // Leave this run's files for the next process; close handles cleanly.
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      await getIt.reset();
    }
  });
}
