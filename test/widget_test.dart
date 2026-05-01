import 'package:arab_mashreq_app/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('يبني التطبيق بنجاح', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: ArabMashreqApp(enableNotifications: false),
      ),
    );

    await tester.pump(const Duration(seconds: 2));
    expect(find.byType(MaterialApp), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });
}
