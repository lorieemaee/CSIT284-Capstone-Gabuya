import 'package:flutter/material.dart';
import '../models/book.dart';

class BookListScreen extends StatefulWidget {
  const BookListScreen({super.key});

  @override
  State<BookListScreen> createState() => _BookListScreenState();
}

class _BookListScreenState extends State<BookListScreen> {
  final List<Book> _books = [
    Book(id: '1', title: 'Flutter in Action', author: 'Eric Windmill', isBorrowed: false),
    Book(id: '2', title: 'Clean Code', author: 'Robert C. Martin', isBorrowed: false),
    Book(id: '3', title: 'Pragmatic Programmer', author: 'Andrew Hunt', isBorrowed: false),
    Book(id: '4', title: 'Designing Data-Intensive Applications', author: 'Martin Kleppmann', isBorrowed: false),
  ];

  String _searchQuery = '';
  final List<String> _history = [];

  void _toggleBorrowStatus(Book book) {
    setState(() {
      book.isBorrowed = !book.isBorrowed;
      if (book.isBorrowed) {
        book.dueDate = DateTime.now().add(const Duration(days: 14));
        _history.insert(0, 'Borrowed "${book.title}" on ${DateTime.now().toLocal().toString().split(' ')[0]}');
      } else {
        book.dueDate = null;
        _history.insert(0, 'Returned "${book.title}" on ${DateTime.now().toLocal().toString().split(' ')[0]}');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final filteredBooks = _books.where((book) {
      return book.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          book.author.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Borrowing Tracker'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                builder: (ctx) => Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Borrowing History', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      Expanded(
                        child: _history.isEmpty
                            ? const Center(child: Text('No history yet.'))
                            : ListView.builder(
                                itemCount: _history.length,
                                itemBuilder: (c, i) => ListTile(
                                  leading: const Icon(Icons.book),
                                  title: Text(_history[i]),
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'Search books or authors',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          Expanded(
            child: filteredBooks.isEmpty
                ? const Center(child: Text('No books found.'))
                : ListView.builder(
                    itemCount: filteredBooks.length,
                    itemBuilder: (ctx, index) {
                      final book = filteredBooks[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        child: ListTile(
                          title: Text(book.title, style: const TextStyle(fontWeight: FontWeight.bold)),
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
                            onPressed: () => _toggleBorrowStatus(book),
                            child: Text(book.isBorrowed ? 'Return' : 'Borrow'),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}