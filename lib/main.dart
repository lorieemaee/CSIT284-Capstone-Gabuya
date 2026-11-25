import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'screens/book_list_screen.dart';

void main() {
  runApp(const BookTrackerApp());
}

class BookTrackerApp extends StatelessWidget {
  const BookTrackerApp({super.key, this.httpClient});

  final http.Client? httpClient;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Book Borrowing Tracker',
      theme: ThemeData(
        primarySwatch: Colors.teal,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: BookListScreen(httpClient: httpClient),
    );
  }
}
