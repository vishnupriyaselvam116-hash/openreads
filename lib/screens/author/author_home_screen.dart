import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import '../../services/auth_service.dart';
import 'add_book_screen.dart';

class AuthorHomeScreen extends StatefulWidget {
  const AuthorHomeScreen({super.key});

  @override
  State<AuthorHomeScreen> createState() => _AuthorHomeScreenState();
}

class _AuthorHomeScreenState extends State<AuthorHomeScreen> {
  static const Color _bg    = Color(0xFF0F0F14);
  static const Color _card  = Color(0xFF1A1A24);
  static const Color _indigo = Color(0xFF5E6AD2);
  static const Color _cream = Color(0xFFF2EDE6);
  static const Color _muted = Color(0xFF6B6B7A);
  static const Color _amber = Color(0xFFE8A338);

  List<dynamic> _books = [];
  bool _loading = true;
  Map<String, dynamic>? _user;

  @override
  void initState() {
    super.initState();
    _loadUser();
    _fetchMyBooks();
  }

  Future<void> _loadUser() async {
    final user = await AuthService.getSavedUser();
    setState(() => _user = user);
  }

  Future<void> _fetchMyBooks() async {
    setState(() => _loading = true);
    try {
      final token = await AuthService.getSavedToken();
      final res = await http.get(
        Uri.parse('$kBaseUrl/books/my/books'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 15));

      final body = jsonDecode(res.body);
      if (body['success'] == true) {
        setState(() {
          _books = body['data']['books'] ?? [];
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
      }
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'approved': return const Color(0xFF4A8C7E);
      case 'rejected': return const Color(0xFFCC4E2A);
      default:         return _amber;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'approved': return Icons.check_circle_rounded;
      case 'rejected': return Icons.cancel_rounded;
      default:         return Icons.hourglass_top_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(context),
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: Color(0xFF5E6AD2)))
                  : RefreshIndicator(
                      color: _indigo,
                      backgroundColor: _card,
                      onRefresh: _fetchMyBooks,
                      child: _books.isEmpty
                          ? _buildEmpty()
                          : ListView.builder(
                              padding: const EdgeInsets.all(20),
                              itemCount: _books.length,
                              itemBuilder: (context, index) =>
                                  _BookTile(
                                    book: _books[index],
                                    statusColor: _statusColor(
                                        _books[index]['status'] ?? 'pending'),
                                    statusIcon: _statusIcon(
                                        _books[index]['status'] ?? 'pending'),
                                    onDelete: () =>
                                        _confirmDelete(context, _books[index]),
                                  ),
                            ),
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => const AddBookScreen()),
          );
          _fetchMyBooks();
        },
        backgroundColor: _indigo,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text(
          'Add Book',
          style: GoogleFonts.lato(
              fontWeight: FontWeight.w700, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hello, ${_user?['name']?.split(' ')[0] ?? 'Author'} ✍️',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: _cream,
                ),
              ),
              Text(
                '${_books.length} book${_books.length == 1 ? '' : 's'} published',
                style: GoogleFonts.lato(fontSize: 12, color: _muted),
              ),
            ],
          ),
          PopupMenuButton(
            icon: CircleAvatar(
              radius: 22,
              backgroundColor: _indigo,
              child: Text(
                (_user?['name'] ?? 'A')[0].toUpperCase(),
                style: GoogleFonts.lato(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
            color: _card,
            itemBuilder: (_) => [
              PopupMenuItem(
                child: Text('Logout',
                    style: GoogleFonts.lato(color: Colors.redAccent)),
                onTap: () async {
                  await AuthService.logout();
                  if (context.mounted) {
                    Navigator.pushReplacementNamed(
                        context, '/role-select');
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.menu_book_rounded,
              size: 64, color: _muted.withOpacity(0.4)),
          const SizedBox(height: 16),
          Text(
            'No books yet',
            style: GoogleFonts.playfairDisplay(
                fontSize: 20, color: _cream, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap + Add Book to publish your first book',
            style: GoogleFonts.lato(fontSize: 13, color: _muted),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, Map<String, dynamic> book) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _card,
        title: Text('Delete Book',
            style: GoogleFonts.playfairDisplay(
                color: _cream, fontWeight: FontWeight.w700)),
        content: Text(
          'Are you sure you want to delete "${book['title']}"?',
          style: GoogleFonts.lato(color: _muted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel',
                style: GoogleFonts.lato(color: _muted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete',
                style: GoogleFonts.lato(color: const Color(0xFFCC4E2A))),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _deleteBook(book['_id']);
    }
  }

  Future<void> _deleteBook(String bookId) async {
    try {
      final token = await AuthService.getSavedToken();
      final res = await http.delete(
        Uri.parse('$kBaseUrl/books/$bookId'),
        headers: {'Authorization': 'Bearer $token'},
      );
      final body = jsonDecode(res.body);
      if (body['success'] == true) {
        _fetchMyBooks();
      }
    } catch (_) {}
  }
}

// ── Book Tile ─────────────────────────────────────────────────────────────────
class _BookTile extends StatelessWidget {
  final Map<String, dynamic> book;
  final Color statusColor;
  final IconData statusIcon;
  final VoidCallback onDelete;

  static const Color _card  = Color(0xFF1A1A24);
  static const Color _amber = Color(0xFFE8A338);
  static const Color _cream = Color(0xFFF2EDE6);
  static const Color _muted = Color(0xFF6B6B7A);

  const _BookTile({
    required this.book,
    required this.statusColor,
    required this.statusIcon,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          // Cover
          Container(
            width: 56,
            height: 72,
            decoration: BoxDecoration(
              color: _amber.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: book['coverImage'] != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      book['coverImage'],
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                          Icons.menu_book_rounded,
                          color: _amber, size: 24),
                    ),
                  )
                : const Icon(Icons.menu_book_rounded,
                    color: _amber, size: 24),
          ),
          const SizedBox(width: 14),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  book['title'] ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.lato(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _cream,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  book['category'] ?? '',
                  style: GoogleFonts.lato(fontSize: 12, color: _muted),
                ),
                const SizedBox(height: 8),
                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 11, color: statusColor),
                      const SizedBox(width: 4),
                      Text(
                        (book['status'] ?? 'pending')
                            .toString()
                            .toUpperCase(),
                        style: GoogleFonts.lato(
                          fontSize: 10,
                          color: statusColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Price + Delete
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                book['isPaid'] == true ? '₹${book['price']}' : 'FREE',
                style: GoogleFonts.lato(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: book['isPaid'] == true
                      ? _amber
                      : const Color(0xFF4A8C7E),
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: onDelete,
                child: const Icon(Icons.delete_outline_rounded,
                    size: 20, color: Color(0xFFCC4E2A)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}