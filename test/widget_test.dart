import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:capstone_gabuya/main.dart';

void main() {
  testWidgets('requires a title and author before adding a book', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const BookTrackerApp());

    await tester.tap(find.byTooltip('Add book'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Add'));
    await tester.pumpAndSettle();

    expect(find.text('Enter a book title'), findsOneWidget);
    expect(find.text('Enter an author'), findsOneWidget);
    expect(find.byType(AlertDialog), findsOneWidget);
  });

  testWidgets('adds a book to the collection', (WidgetTester tester) async {
    await tester.pumpWidget(const BookTrackerApp());

    await tester.tap(find.byTooltip('Add book'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextFormField).at(0),
      '  Domain-Driven Design  ',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'Eric Evans');
    await tester.tap(find.widgetWithText(FilledButton, 'Add'));
    await tester.pumpAndSettle();

    expect(find.text('Domain-Driven Design'), findsOneWidget);
    expect(find.text('Author: Eric Evans'), findsOneWidget);
    expect(
      find.text('"Domain-Driven Design" added to your collection'),
      findsOneWidget,
    );
  });
}
