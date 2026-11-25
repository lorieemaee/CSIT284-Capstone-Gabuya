class Book {
  Book({
    required this.id,
    required this.title,
    required this.author,
    required this.isBorrowed,
    this.dueDate,
  });

  final String id;
  final String title;
  final String author;
  bool isBorrowed;
  DateTime? dueDate;

  factory Book.fromRealtimeDatabase({
    required String id,
    required Object? value,
  }) {
    if (value is! Map<String, dynamic>) {
      throw const FormatException('A book record must be a JSON object.');
    }

    final title = value['title'];
    final author = value['author'];
    final isBorrowed = value['isBorrowed'];
    final rawDueDate = value['dueDate'];

    if (title is! String || author is! String || isBorrowed is! bool) {
      throw const FormatException('A book record has invalid fields.');
    }
    if (rawDueDate != null && rawDueDate is! String) {
      throw const FormatException('A book due date must be a string.');
    }

    final dueDate = rawDueDate == null ? null : DateTime.tryParse(rawDueDate);
    if (rawDueDate != null && dueDate == null) {
      throw const FormatException('A book due date is invalid.');
    }

    return Book(
      id: id,
      title: title,
      author: author,
      isBorrowed: isBorrowed,
      dueDate: dueDate,
    );
  }

  Map<String, Object?> toRealtimeDatabaseJson() => {
    'title': title,
    'author': author,
    'isBorrowed': isBorrowed,
    'dueDate': dueDate?.toUtc().toIso8601String(),
  };
}
