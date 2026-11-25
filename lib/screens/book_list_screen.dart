import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../models/book.dart';
import '../widgets/book_list_item.dart';
import 'borrowing_history_screen.dart';

class BookListScreen extends StatefulWidget {
  const BookListScreen({super.key, this.httpClient});

  final http.Client? httpClient;

  @override
  State<BookListScreen> createState() => _BookListScreenState();
}

class _BookListScreenState extends State<BookListScreen> {
  static const _databaseHost =
      'gabuya-capstone-default-rtdb.asia-southeast1.firebasedatabase.app';
  static final _booksUri = Uri.https(_databaseHost, 'books.json');
  static final _historyUri = Uri.https(_databaseHost, 'borrowing-history.json');

  late final http.Client _httpClient;
  late final bool _ownsHttpClient;
  final List<Book> _books = [];
  final List<String> _history = [];
  final Set<String> _pendingBookIds = {};
  String _searchQuery = '';
  String? _loadError;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _ownsHttpClient = widget.httpClient == null;
    _httpClient = widget.httpClient ?? http.Client();
    unawaited(_loadData());
  }

  @override
  void dispose() {
    if (_ownsHttpClient) {
      _httpClient.close();
    }
    super.dispose();
  }

  Future<Object?> _requestJson(String method, Uri uri, {Object? body}) async {
    final request = http.Request(method, uri);
    if (body != null) {
      request.headers['Content-Type'] = 'application/json';
      request.body = jsonEncode(body);
    }

    final streamedResponse = await _httpClient.send(request);
    final response = await http.Response.fromStream(streamedResponse);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw _DatabaseRequestException(
        'Database request failed (${response.statusCode}).',
      );
    }

    final responseBody = response.body.trim();
    return responseBody.isEmpty ? null : jsonDecode(responseBody);
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      final books = await _loadBooks();
      final history = await _loadHistory();
      if (!mounted) {
        return;
      }

      setState(() {
        _books
          ..clear()
          ..addAll(books);
        _history
          ..clear()
          ..addAll(history);
        _isLoading = false;
      });
    } on _DatabaseRequestException catch (error) {
      _setLoadError(error.message);
    } on http.ClientException catch (error) {
      _setLoadError(error.message);
    } on FormatException catch (error) {
      _setLoadError(
        'Invalid data returned from the database: ${error.message}',
      );
    }
  }

  void _setLoadError(String message) {
    if (!mounted) {
      return;
    }
    setState(() {
      _loadError = message;
      _isLoading = false;
    });
  }

  Future<List<Book>> _loadBooks() async {
    final data = await _requestJson('GET', _booksUri);
    if (data == null ||
        (data is Map && data.isEmpty) ||
        (data is List && data.every((value) => value == null))) {
      final books = _initialBooks();
      await _requestJson(
        'PUT',
        _booksUri,
        body: {
          for (final book in books) book.id: book.toRealtimeDatabaseJson(),
        },
      );
      return books;
    }

    if (data is Map<String, dynamic>) {
      return [
        for (final entry in data.entries)
          Book.fromRealtimeDatabase(id: entry.key, value: entry.value),
      ];
    }

    if (data is List) {
      return [
        for (var index = 0; index < data.length; index++)
          if (data[index] != null)
            Book.fromRealtimeDatabase(id: index.toString(), value: data[index]),
      ];
    }

    throw const FormatException(
      'The books path must contain a JSON object or array.',
    );
  }

  Future<List<String>> _loadHistory() async {
    final data = await _requestJson('GET', _historyUri);
    if (data == null) {
      return [];
    }
    if (data is! Map<String, dynamic>) {
      throw const FormatException(
        'The borrowing history path must contain a JSON object.',
      );
    }

    final records = <_HistoryRecord>[];
    for (final entry in data.entries) {
      final value = entry.value;
      if (value is! Map<String, dynamic> ||
          value['message'] is! String ||
          value['timestamp'] is! String) {
        throw const FormatException('A borrowing history record is invalid.');
      }

      final timestamp = DateTime.tryParse(value['timestamp'] as String);
      if (timestamp == null) {
        throw const FormatException(
          'A borrowing history timestamp is invalid.',
        );
      }
      records.add(
        _HistoryRecord(
          message: value['message'] as String,
          timestamp: timestamp,
        ),
      );
    }
    records.sort(
      (first, second) => second.timestamp.compareTo(first.timestamp),
    );
    return records.map((record) => record.message).toList();
  }

  List<Book> _initialBooks() => [
    Book(
      id: 'sample-1',
      title: 'Flutter in Action',
      author: 'Eric Windmill',
      isBorrowed: false,
    ),
    Book(
      id: 'sample-2',
      title: 'Clean Code',
      author: 'Robert C. Martin',
      isBorrowed: false,
    ),
    Book(
      id: 'sample-3',
      title: 'Pragmatic Programmer',
      author: 'Andrew Hunt',
      isBorrowed: false,
    ),
    Book(
      id: 'sample-4',
      title: 'Designing Data-Intensive Applications',
      author: 'Martin Kleppmann',
      isBorrowed: false,
    ),
    Book(
      id: 'sample-5',
      title: 'The Hobbit',
      author: 'J.R.R. Tolkien',
      isBorrowed: false,
    ),
    Book(
      id: 'sample-6',
      title: 'To Kill a Mockingbird',
      author: 'Harper Lee',
      isBorrowed: false,
    ),
    Book(
      id: 'sample-7',
      title: '1984',
      author: 'George Orwell',
      isBorrowed: false,
    ),
    Book(
      id: 'sample-8',
      title: 'The Great Gatsby',
      author: 'F. Scott Fitzgerald',
      isBorrowed: false,
    ),
    Book(
      id: 'sample-9',
      title: 'The Alchemist',
      author: 'Paulo Coelho',
      isBorrowed: false,
    ),
    Book(
      id: 'sample-10',
      title: 'The Lord of the Rings',
      author: 'J.R.R. Tolkien',
      isBorrowed: false,
    ),
  ];

  Future<void> _toggleBorrowStatus(Book book) async {
    if (!_pendingBookIds.add(book.id)) {
      return;
    }
    setState(() {});

    final isBorrowed = !book.isBorrowed;
    final actionTime = DateTime.now();
    final dueDate = isBorrowed
        ? actionTime.add(const Duration(days: 14))
        : null;

    try {
      await _requestJson(
        'PATCH',
        Uri.https(_databaseHost, 'books/${Uri.encodeComponent(book.id)}.json'),
        body: {
          'isBorrowed': isBorrowed,
          'dueDate': dueDate?.toUtc().toIso8601String(),
        },
      );
      if (!mounted) {
        return;
      }

      setState(() {
        book.isBorrowed = isBorrowed;
        book.dueDate = dueDate;
      });

      final date = actionTime.toLocal().toString().split(' ')[0];
      final message =
          '${isBorrowed ? 'Borrowed' : 'Returned'} "${book.title}" on $date';
      try {
        await _requestJson(
          'POST',
          _historyUri,
          body: {
            'message': message,
            'timestamp': actionTime.toUtc().toIso8601String(),
          },
        );
        if (mounted) {
          setState(() => _history.insert(0, message));
        }
      } on _DatabaseRequestException catch (error) {
        _showRequestError(
          'Book status saved, but history could not be saved',
          error.message,
        );
      } on http.ClientException catch (error) {
        _showRequestError(
          'Book status saved, but history could not be saved',
          error.message,
        );
      } on FormatException catch (error) {
        _showRequestError(
          'Book status saved, but history could not be saved',
          error.message,
        );
      }
    } on _DatabaseRequestException catch (error) {
      _showRequestError('Could not update the book', error.message);
    } on http.ClientException catch (error) {
      _showRequestError('Could not update the book', error.message);
    } on FormatException catch (error) {
      _showRequestError('Could not update the book', error.message);
    } finally {
      if (mounted) {
        setState(() => _pendingBookIds.remove(book.id));
      }
    }
  }

  Future<void> _showBookDialog([Book? existingBook]) async {
    final formKey = GlobalKey<FormState>();
    var title = existingBook?.title ?? '';
    var author = existingBook?.author ?? '';

    final book = await showDialog<Book>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(existingBook == null ? 'Add a book' : 'Edit book'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  autofocus: existingBook == null,
                  initialValue: existingBook?.title,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(labelText: 'Title'),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Enter a book title'
                      : null,
                  onSaved: (value) => title = value!.trim(),
                ),
                TextFormField(
                  initialValue: existingBook?.author,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(labelText: 'Author'),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Enter an author'
                      : null,
                  onSaved: (value) => author = value!.trim(),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (!formKey.currentState!.validate()) {
                return;
              }
              formKey.currentState!.save();

              Navigator.pop(
                dialogContext,
                Book(
                  id: existingBook?.id ?? '',
                  title: title,
                  author: author,
                  isBorrowed: existingBook?.isBorrowed ?? false,
                  dueDate: existingBook?.dueDate,
                ),
              );
            },
            child: Text(existingBook == null ? 'Add' : 'Save'),
          ),
        ],
      ),
    );

    if (book != null && mounted) {
      if (existingBook == null) {
        await _addBook(book);
      } else {
        await _updateBook(existingBook, book);
      }
    }
  }

  Future<void> _addBook(Book book) async {
    try {
      final response = await _requestJson(
        'POST',
        _booksUri,
        body: book.toRealtimeDatabaseJson(),
      );
      if (response is! Map<String, dynamic> || response['name'] is! String) {
        throw const FormatException('The database did not return a book ID.');
      }

      final savedBook = Book(
        id: response['name'] as String,
        title: book.title,
        author: book.author,
        isBorrowed: false,
      );
      if (!mounted) {
        return;
      }

      setState(() => _books.add(savedBook));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('"${savedBook.title}" added to your collection'),
        ),
      );
    } on _DatabaseRequestException catch (error) {
      _showRequestError('Could not add the book', error.message);
    } on http.ClientException catch (error) {
      _showRequestError('Could not add the book', error.message);
    } on FormatException catch (error) {
      _showRequestError('Could not add the book', error.message);
    }
  }

  Future<void> _updateBook(Book currentBook, Book editedBook) async {
    if (!_pendingBookIds.add(currentBook.id)) {
      return;
    }
    setState(() {});

    try {
      await _requestJson(
        'PATCH',
        Uri.https(
          _databaseHost,
          'books/${Uri.encodeComponent(currentBook.id)}.json',
        ),
        body: {'title': editedBook.title, 'author': editedBook.author},
      );
      if (!mounted) {
        return;
      }

      setState(() {
        final index = _books.indexWhere((book) => book.id == currentBook.id);
        if (index >= 0) {
          _books[index] = editedBook;
        }
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('"${editedBook.title}" updated')));
    } on _DatabaseRequestException catch (error) {
      _showRequestError('Could not update the book', error.message);
    } on http.ClientException catch (error) {
      _showRequestError('Could not update the book', error.message);
    } on FormatException catch (error) {
      _showRequestError('Could not update the book', error.message);
    } finally {
      if (mounted) {
        setState(() => _pendingBookIds.remove(currentBook.id));
      }
    }
  }

  Future<void> _confirmDeleteBook(Book book) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete book?'),
        content: Text('Delete "${book.title}" from your collection?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (shouldDelete == true && mounted) {
      await _deleteBook(book);
    }
  }

  Future<void> _deleteBook(Book book) async {
    if (!_pendingBookIds.add(book.id)) {
      return;
    }
    setState(() {});

    try {
      await _requestJson(
        'DELETE',
        Uri.https(_databaseHost, 'books/${Uri.encodeComponent(book.id)}.json'),
      );
      if (!mounted) {
        return;
      }

      setState(() => _books.removeWhere((item) => item.id == book.id));
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('"${book.title}" deleted')));
    } on _DatabaseRequestException catch (error) {
      _showRequestError('Could not delete the book', error.message);
    } on http.ClientException catch (error) {
      _showRequestError('Could not delete the book', error.message);
    } on FormatException catch (error) {
      _showRequestError('Could not delete the book', error.message);
    } finally {
      if (mounted) {
        setState(() => _pendingBookIds.remove(book.id));
      }
    }
  }

  void _showRequestError(String action, String details) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('$action: $details')));
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
            onPressed: _isLoading || _loadError != null
                ? null
                : () {
                    Navigator.of(context).push<void>(
                      MaterialPageRoute<void>(
                        builder: (context) => BorrowingHistoryScreen(
                          history: List<String>.unmodifiable(_history),
                        ),
                      ),
                    );
                  },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _loadError != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Could not load books: $_loadError'),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: _loadData,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            )
          : Column(
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
                            return BookListItem(
                              book: book,
                              isUpdating: _pendingBookIds.contains(book.id),
                              onEdit: () => _showBookDialog(book),
                              onDelete: () => _confirmDeleteBook(book),
                              onToggleBorrowStatus: () =>
                                  _toggleBorrowStatus(book),
                            );
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _isLoading || _loadError != null ? null : _showBookDialog,
        tooltip: 'Add book',
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _HistoryRecord {
  const _HistoryRecord({required this.message, required this.timestamp});

  final String message;
  final DateTime timestamp;
}

class _DatabaseRequestException implements Exception {
  const _DatabaseRequestException(this.message);

  final String message;
}
