import 'package:coffee_app/auth/providers/auth_provider.dart';
import 'package:coffee_app/features/ai_assistant/data/ai_assistant_repository.dart';
import 'package:coffee_app/features/inventory/data/repositories/hive_inventory_repository.dart';
import 'package:coffee_app/features/sales/data/repositories/hive_sales_repository.dart';
import 'package:coffee_app/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    final inventoryRepo = HiveInventoryRepository();
    final salesRepo = HiveSalesRepository();
    final aiAssistantRepo = AiAssistantRepository();
    final authProvider = AuthProvider();

    await tester.pumpWidget(MyApp(
      authProvider: authProvider,
      inventoryRepository: inventoryRepo,
      salesRepository: salesRepo,
      aiAssistantRepository: aiAssistantRepo,
    ));

    // Verify that our counter starts at 0.
    expect(find.text('0'), findsOneWidget);
    expect(find.text('1'), findsNothing);

    // Tap the '+' icon and trigger a frame.
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    // Verify that our counter has incremented.
    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsOneWidget);
  });
}
