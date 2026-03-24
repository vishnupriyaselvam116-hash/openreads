import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import '../../services/auth_service.dart';

class UserHomeScreen extends StatefulWidget {
  const UserHomeScreen({super.key});

  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> {
  static const Color _bg     = Color(0xFF0F0F14);
  static const Color _card   = Color(0xFF1A1A24);
  static const Color _amber  = Color(0xFFE8A338);
  static const Color _cream  = Color(0xFFF2EDE6);
  static const Color _muted  = Color(0xFF6B6B7A);

  final List<String> _categories = [
    'All', 'Fiction', 'Romance', 'Mystery',
    'Science', 'Technology', 'History',
    'Children', 'Education', 'Self-Help',
  ];

  String _selectedCategory = 'All';
  List<dynamic> _books = [];
  List<dynamic> _featuredBooks = [];
  bool _loading = true;
  String _searchQuery = '';
  final _searchCtrl = TextEditingController();
  Map<String, dynamic>? _user;

  @override
  void initState() {
    super.initState();
    _loadUser();
    _fetchBooks();
  }

  Future<void> _loadUser() async {
    final user = await AuthService.getSavedUser();
    setState(() => _user = user);
  }

  Future<void> _fetchBooks({String? category, String? search}) async {
    setState(() => _loading = true);
    try {
      final token = await AuthService.getSavedToken();
      String url = '$kBaseUrl/books?limit=20';
      if (category != null && category != 'All') url += '&category=$category';
      if (search != null && search.isNotEmpty) url += '&search=$search';

      final res = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 15));

      final body = jsonDecode(res.body);
      if (body['success'] == true) {
        final books = body['data']['books'] ?? [];
        setState(() {
          _books = books;
          _featuredBooks = books.take(5).toList();
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
      }
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(color: _amber))
                  : RefreshIndicator(
                      color: _amber,
                      backgroundColor: _card,
                      onRefresh: () => _fetchBooks(
                        category: _selectedCategory == 'All'
                            ? null
                            : _selectedCategory,
                      ),
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSearchBar(),
                            _buildFeaturedSection(),
                            _buildCategorySection(),
                            _buildBooksGrid(),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Top Bar ────────────────────────────────────────────────────────────────
  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hello, ${_user?['name']?.split(' ')[0] ?? 'Reader'} 👋',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: _cream,
                ),
              ),
              Text(
                'What will you read today?',
                style: GoogleFonts.lato(fontSize: 12, color: _muted),
              ),
            ],
          ),
          // Avatar
          CircleAvatar(
            radius: 22,
            backgroundColor: _amber,
            child: Text(
              (_user?['name'] ?? 'R')[0].toUpperCase(),
              style: GoogleFonts.lato(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Search Bar ─────────────────────────────────────────────────────────────
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: TextField(
        controller: _searchCtrl,
        style: GoogleFonts.lato(fontSize: 14, color: _cream),
        onChanged: (val) {
          setState(() => _searchQuery = val);
          if (val.isEmpty) {
            _fetchBooks(
              category: _selectedCategory == 'All' ? null : _selectedCategory,
            );
          } else {
            _fetchBooks(search: val);
          }
        },
        decoration: InputDecoration(
          hintText: 'Search books, authors...',
          hintStyle: GoogleFonts.lato(fontSize: 13, color: _muted),
          filled: true,
          fillColor: _card,
          prefixIcon: const Icon(Icons.search_rounded, color: _muted, size: 18),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close_rounded,
                      color: _muted, size: 18),
                  onPressed: () {
                    _searchCtrl.clear();
                    setState(() => _searchQuery = '');
                    _fetchBooks(
                      category: _selectedCategory == 'All'
                          ? null
                          : _selectedCategory,
                    );
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  // ── Featured Section ───────────────────────────────────────────────────────
  Widget _buildFeaturedSection() {
    if (_featuredBooks.isEmpty) return const SizedBox();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 14),
          child: Text(
            'Featured Books',
            style: GoogleFonts.playfairDisplay(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: _cream,
            ),
          ),
        ),
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: _featuredBooks.length,
            itemBuilder: (context, index) {
              final book = _featuredBooks[index];
              return _FeaturedBookCard(book: book);
            },
          ),
        ),
      ],
    );
  }

  // ── Category Section ───────────────────────────────────────────────────────
  Widget _buildCategorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 14),
          child: Text(
            'Categories',
            style: GoogleFonts.playfairDisplay(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: _cream,
            ),
          ),
        ),
        SizedBox(
          height: 38,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: _categories.length,
            itemBuilder: (context, index) {
              final cat = _categories[index];
              final isSelected = cat == _selectedCategory;
              return GestureDetector(
                onTap: () {
                  setState(() => _selectedCategory = cat);
                  _fetchBooks(
                      category: cat == 'All' ? null : cat);
                },
                child: Container(
                  margin: const EdgeInsets.only(right: 10),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? _amber : _card,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? _amber
                          : _muted.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Text(
                    cat,
                    style: GoogleFonts.lato(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : _muted,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ── Books Grid ─────────────────────────────────────────────────────────────
  Widget _buildBooksGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _selectedCategory == 'All'
                    ? 'All Books'
                    : _selectedCategory,
                style: GoogleFonts.playfairDisplay(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: _cream,
                ),
              ),
              Text(
                '${_books.length} books',
                style: GoogleFonts.lato(fontSize: 12, color: _muted),
              ),
            ],
          ),
        ),
        if (_books.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Column(
                children: [
                  Icon(Icons.menu_book_rounded,
                      size: 48, color: _muted.withValues(alpha: 0.5)),
                  const SizedBox(height: 12),
                  Text(
                    'No books found',
                    style: GoogleFonts.lato(color: _muted, fontSize: 14),
                  ),
                ],
              ),
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: 0.65,
            ),
            itemCount: _books.length,
            itemBuilder: (context, index) {
              return _BookCard(book: _books[index]);
            },
          ),
      ],
    );
  }
}

// ── Featured Book Card ────────────────────────────────────────────────────────
class _FeaturedBookCard extends StatelessWidget {
  final Map<String, dynamic> book;

  static const Color _card  = Color(0xFF1A1A24);
  static const Color _amber = Color(0xFFE8A338);
  static const Color _cream = Color(0xFFF2EDE6);
  static const Color _muted = Color(0xFF6B6B7A);

  const _FeaturedBookCard({required this.book});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      margin: const EdgeInsets.only(right: 14),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          // Cover
          Container(
            width: 120,
            decoration: BoxDecoration(
              color: _amber.withValues(alpha: 0.15),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                bottomLeft: Radius.circular(16),
              ),
            ),
            child: book['coverImage'] != null
                ? ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      bottomLeft: Radius.circular(16),
                    ),
                    child: Image.network(
                      book['coverImage'],
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.menu_book_rounded,
                        size: 40,
                        color: _amber,
                      ),
                    ),
                  )
                : const Icon(
                    Icons.menu_book_rounded,
                    size: 40,
                    color: _amber,
                  ),
          ),
          // Info
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _amber.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      book['category'] ?? '',
                      style: GoogleFonts.lato(
                          fontSize: 10,
                          color: _amber,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    book['title'] ?? '',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: _cream,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    book['author'] ?? '',
                    style: GoogleFonts.lato(
                        fontSize: 12, color: _muted),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded,
                          size: 14, color: _amber),
                      const SizedBox(width: 4),
                      Text(
                        '${book['averageRating'] ?? 0}',
                        style: GoogleFonts.lato(
                          fontSize: 12,
                          color: _cream,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  book['isPaid'] == true
                      ? Text(
                          '₹${book['price']}',
                          style: GoogleFonts.lato(
                            fontSize: 14,
                            color: _amber,
                            fontWeight: FontWeight.w700,
                          ),
                        )
                      : Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4A8C7E)
                                .withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'FREE',
                            style: GoogleFonts.lato(
                              fontSize: 11,
                              color: const Color(0xFF4A8C7E),
                              fontWeight: FontWeight.w700,
                            ),
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

// ── Book Card ─────────────────────────────────────────────────────────────────
class _BookCard extends StatelessWidget {
  final Map<String, dynamic> book;

  static const Color _card  = Color(0xFF1A1A24);
  static const Color _amber = Color(0xFFE8A338);
  static const Color _cream = Color(0xFFF2EDE6);
  static const Color _muted = Color(0xFF6B6B7A);

  const _BookCard({required this.book});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cover image
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: _amber.withValues(alpha: 0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(14),
                  topRight: Radius.circular(14),
                ),
              ),
              child: book['coverImage'] != null
                  ? ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(14),
                        topRight: Radius.circular(14),
                      ),
                      child: Image.network(
                        book['coverImage'],
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.menu_book_rounded,
                          size: 36,
                          color: _amber,
                        ),
                      ),
                    )
                  : const Icon(
                      Icons.menu_book_rounded,
                      size: 36,
                      color: _amber,
                    ),
            ),
          ),
          // Info
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  book['title'] ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.lato(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _cream,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  book['author'] ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.lato(
                      fontSize: 11, color: _muted),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.star_rounded,
                            size: 12, color: _amber),
                        const SizedBox(width: 2),
                        Text(
                          '${book['averageRating'] ?? 0}',
                          style: GoogleFonts.lato(
                            fontSize: 11,
                            color: _cream,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    book['isPaid'] == true
                        ? Text(
                            '₹${book['price']}',
                            style: GoogleFonts.lato(
                              fontSize: 12,
                              color: _amber,
                              fontWeight: FontWeight.w700,
                            ),
                          )
                        : Text(
                            'FREE',
                            style: GoogleFonts.lato(
                              fontSize: 11,
                              color: const Color(0xFF4A8C7E),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}