import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({
    required this.totalBooks,
    required this.borrowedBooks,
    required this.statisticsAvailable,
    super.key,
  });

  final int totalBooks;
  final int borrowedBooks;
  final bool statisticsAvailable;

  @override
  Widget build(BuildContext context) {
    final availableBooks = totalBooks - borrowedBooks;
    final total = statisticsAvailable ? '$totalBooks' : '—';
    final borrowed = statisticsAvailable ? '$borrowedBooks' : '—';
    final available = statisticsAvailable ? '$availableBooks' : '—';

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 40,
                    child: Icon(Icons.person, size: 44),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Sample User',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const Text('Library Member'),
                  const Divider(height: 32),
                  const ListTile(
                    leading: Icon(Icons.badge_outlined),
                    title: Text('Name'),
                    subtitle: Text('Sample User'),
                  ),
                  const ListTile(
                    leading: Icon(Icons.email_outlined),
                    title: Text('Email'),
                    subtitle: Text('sample.user@example.com'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Library overview',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
              child: Row(
                children: [
                  Expanded(
                    child: _ProfileStat(
                      icon: Icons.menu_book_outlined,
                      label: 'Total',
                      value: total,
                    ),
                  ),
                  Expanded(
                    child: _ProfileStat(
                      icon: Icons.bookmark_added_outlined,
                      label: 'Borrowed',
                      value: borrowed,
                    ),
                  ),
                  Expanded(
                    child: _ProfileStat(
                      icon: Icons.library_books_outlined,
                      label: 'Available',
                      value: available,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileStat extends StatelessWidget {
  const _ProfileStat({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon),
        const SizedBox(height: 8),
        Text(value, style: Theme.of(context).textTheme.titleLarge),
        Text(label, textAlign: TextAlign.center),
      ],
    );
  }
}
