import 'package:flutter/material.dart';

import '../models/book.dart';

class BookListItem extends StatelessWidget {
  const BookListItem({
    required this.book,
    required this.onToggleBorrowStatus,
    required this.onEdit,
    required this.onDelete,
    this.isUpdating = false,
    super.key,
  });

  final Book book;
  final VoidCallback onToggleBorrowStatus;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final bool isUpdating;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.surfaceContainerHigh,
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
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            PopupMenuButton<String>(
              tooltip: 'Book options',
              enabled: !isUpdating,
              onSelected: (value) {
                if (value == 'edit') {
                  onEdit();
                } else if (value == 'delete') {
                  onDelete();
                }
              },
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'edit', child: Text('Edit')),
                PopupMenuItem(value: 'delete', child: Text('Delete')),
              ],
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: book.isBorrowed ? Colors.red : Colors.teal,
                foregroundColor: Colors.white,
              ),
              onPressed: isUpdating ? null : onToggleBorrowStatus,
              child: isUpdating
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(book.isBorrowed ? 'Return' : 'Borrow'),
            ),
          ],
        ),
      ),
    );
  }
}
