import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:capstone_gabuya/main.dart';
import 'package:capstone_gabuya/widgets/book_list_item.dart';

Future<(http.Client, List<http.Request>)> _pumpApp(
  WidgetTester tester, {
  Object? books,
  Object? history,
}) async {
  final requests = <http.Request>[];
  final client = MockClient((request) async {
    requests.add(request);
    final path = request.url.path;

    if (request.method == 'GET' && path == '/books.json') {
      return http.Response(jsonEncode(books), 200);
    }
    if (request.method == 'GET' && path == '/borrowing-history.json') {
      return http.Response(jsonEncode(history), 200);
    }
    if (request.method == 'PUT' && path == '/books.json') {
      return http.Response(request.body, 200);
    }
    if (request.method == 'POST' && path == '/books.json') {
      return http.Response(jsonEncode({'name': 'created-book'}), 200);
    }
    if (request.method == 'POST' && path == '/borrowing-history.json') {
      return http.Response(jsonEncode({'name': 'history-entry'}), 200);
    }
    if (request.method == 'DELETE' && path.startsWith('/books/')) {
      return http.Response('null', 200);
    }
    if (request.method == 'PATCH' && path.startsWith('/books/')) {
      return http.Response('null', 200);
    }
    return http.Response('Not found', 404);
  });

  await tester.pumpWidget(BookTrackerApp(httpClient: client));
  await tester.pumpAndSettle();
  return (client, requests);
}

void main() {
  testWidgets('requires a title and author before adding a book', (
    WidgetTester tester,
  ) async {
    final (client, _) = await _pumpApp(tester);
    addTearDown(client.close);

    await tester.tap(find.byTooltip('Add book'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Add'));
    await tester.pumpAndSettle();

    expect(find.text('Enter a book title'), findsOneWidget);
    expect(find.text('Enter an author'), findsOneWidget);
    expect(find.byType(AlertDialog), findsOneWidget);
  });

  testWidgets('adds a book to the collection', (WidgetTester tester) async {
    final (client, requests) = await _pumpApp(tester);
    addTearDown(client.close);

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
    expect(
      requests.any(
        (request) =>
            request.method == 'POST' && request.url.path == '/books.json',
      ),
      isTrue,
    );
  });

  testWidgets('navigates to borrowing history and back', (
    WidgetTester tester,
  ) async {
    final (client, _) = await _pumpApp(tester);
    addTearDown(client.close);

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
    final (client, _) = await _pumpApp(tester);
    addTearDown(client.close);

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

  testWidgets('seeds sample books only when the database is empty', (
    WidgetTester tester,
  ) async {
    final (client, requests) = await _pumpApp(tester);
    addTearDown(client.close);

    final seedRequest = requests.singleWhere(
      (request) => request.method == 'PUT' && request.url.path == '/books.json',
    );
    final seededBooks = jsonDecode(seedRequest.body) as Map<String, dynamic>;
    expect(seededBooks, hasLength(10));
  });

  testWidgets('does not overwrite books already in the database', (
    WidgetTester tester,
  ) async {
    final (client, requests) = await _pumpApp(
      tester,
      books: {
        'stored-book': {
          'title': 'Stored Book',
          'author': 'Database Author',
          'isBorrowed': false,
          'dueDate': null,
        },
      },
    );
    addTearDown(client.close);

    expect(find.text('Stored Book'), findsOneWidget);
    expect(
      requests.any(
        (request) =>
            request.method == 'PUT' && request.url.path == '/books.json',
      ),
      isFalse,
    );
  });

  testWidgets('persists borrowing status and history', (
    WidgetTester tester,
  ) async {
    final (client, requests) = await _pumpApp(tester);
    addTearDown(client.close);

    await tester.tap(find.widgetWithText(ElevatedButton, 'Borrow').first);
    await tester.pumpAndSettle();

    final updateRequest = requests.singleWhere(
      (request) =>
          request.method == 'PATCH' && request.url.path == '/books/1.json',
    );
    final update = jsonDecode(updateRequest.body) as Map<String, dynamic>;
    expect(update['isBorrowed'], isTrue);
    expect(update['dueDate'], isA<String>());

    final historyRequest = requests.singleWhere(
      (request) =>
          request.method == 'POST' &&
          request.url.path == '/borrowing-history.json',
    );
    final event = jsonDecode(historyRequest.body) as Map<String, dynamic>;
    expect(event['message'], startsWith('Borrowed "Flutter in Action" on '));
  });

  testWidgets('returning a book clears its due date in the database', (
    WidgetTester tester,
  ) async {
    final (client, requests) = await _pumpApp(
      tester,
      books: {
        'stored-book': {
          'title': 'Stored Book',
          'author': 'Database Author',
          'isBorrowed': true,
          'dueDate': '2026-12-09T12:00:00.000Z',
        },
      },
    );
    addTearDown(client.close);

    await tester.tap(find.widgetWithText(ElevatedButton, 'Return'));
    await tester.pumpAndSettle();

    final updateRequest = requests.singleWhere(
      (request) =>
          request.method == 'PATCH' &&
          request.url.path == '/books/stored-book.json',
    );
    final update = jsonDecode(updateRequest.body) as Map<String, dynamic>;
    expect(update['isBorrowed'], isFalse);
    expect(update['dueDate'], isNull);
  });

  testWidgets('editing a book updates its database record', (
    WidgetTester tester,
  ) async {
    final (client, requests) = await _pumpApp(tester);
    addTearDown(client.close);

    await tester.tap(find.byTooltip('Book options').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(0), 'Updated Title');
    await tester.enterText(find.byType(TextFormField).at(1), 'Updated Author');
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();

    final updateRequest = requests.singleWhere(
      (request) =>
          request.method == 'PATCH' && request.url.path == '/books/1.json',
    );
    final update = jsonDecode(updateRequest.body) as Map<String, dynamic>;
    expect(update['title'], 'Updated Title');
    expect(update['author'], 'Updated Author');
    expect(find.text('Updated Title'), findsOneWidget);
  });

  testWidgets('deleting a book removes its database record', (
    WidgetTester tester,
  ) async {
    final (client, requests) = await _pumpApp(tester);
    addTearDown(client.close);

    await tester.tap(find.byTooltip('Book options').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();

    expect(
      requests.any(
        (request) =>
            request.method == 'DELETE' && request.url.path == '/books/1.json',
      ),
      isTrue,
    );
    expect(find.text('Flutter in Action'), findsNothing);
  });
}
