import 'package:flutter/material.dart';

class BorrowingHistoryScreen extends StatelessWidget {
  const BorrowingHistoryScreen({required this.history, super.key});

  final List<String> history;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Borrowing History')),
      body: history.isEmpty
          ? const Center(child: Text('No history yet.'))
          : ListView.builder(
              itemCount: history.length,
              itemBuilder: (context, index) => ListTile(
                leading: const Icon(Icons.book),
                title: Text(history[index]),
              ),
            ),
    );
  }
}
