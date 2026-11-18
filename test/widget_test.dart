import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:capstone_gabuya/main.dart';
import 'package:capstone_gabuya/widgets/book_list_item.dart';

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
    await tester.enterText(
      find.byType(TextField).first,
      'Domain-Driven Design',
    );
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byType(BookListItem),
        matching: find.text('Domain-Driven Design'),
      ),
      findsOneWidget,
    );
    expect(find.text('Author: Eric Evans'), findsOneWidget);
    expect(
      find.text('"Domain-Driven Design" added to your collection'),
      findsOneWidget,
    );
  });

  testWidgets('navigates to borrowing history and back', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const BookTrackerApp());

    await tester.tap(find.byIcon(Icons.history));
    await tester.pumpAndSettle();

    expect(find.text('Borrowing History'), findsOneWidget);
    expect(find.text('No history yet.'), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    expect(find.text('Book Borrowing Tracker'), findsOneWidget);
  });

  testWidgets('shows the tenth sample book in the collection', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const BookTrackerApp());

    await tester.enterText(
      find.byType(TextField).first,
      'The Lord of the Rings',
    );
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byType(BookListItem),
        matching: find.text('The Lord of the Rings'),
      ),
      findsOneWidget,
    );
    expect(find.text('Author: J.R.R. Tolkien'), findsOneWidget);
  });
}
