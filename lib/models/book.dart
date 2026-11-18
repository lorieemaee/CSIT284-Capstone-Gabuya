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
}