import 'package:flutter/material.dart';

import '../models/book.dart';

class BookListItem extends StatelessWidget {
  const BookListItem({
    required this.book,
    required this.onToggleBorrowStatus,
    super.key,
  });

  final Book book;
  final VoidCallback onToggleBorrowStatus;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        title: Text(
          book.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Author: ${book.author}'),
            if (book.isBorrowed && book.dueDate != null)
              Text(
                'Due: ${book.dueDate!.toLocal().toString().split(' ')[0]}',
                style: const TextStyle(color: Colors.red),
              ),
          ],
        ),
        trailing: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: book.isBorrowed ? Colors.red : Colors.teal,
            foregroundColor: Colors.white,
          ),
          onPressed: onToggleBorrowStatus,
          child: Text(book.isBorrowed ? 'Return' : 'Borrow'),
        ),
      ),
    );
  }
}
