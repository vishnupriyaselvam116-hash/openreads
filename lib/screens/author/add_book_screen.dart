import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import '../../services/auth_service.dart';

class AddBookScreen extends StatefulWidget {
  const AddBookScreen({super.key});

  @override
  State<AddBookScreen> createState() => _AddBookScreenState();
}

class _AddBookScreenState extends State<AddBookScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _coverCtrl = TextEditingController();
  final _fileCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();

  String _selectedCategory = 'Fiction';
  bool _isPaid = false;
  bool _loading = false;
  String? _error;
  String? _success;

  static const Color _bg = Color(0xFF0F0F14);
  static const Color _card = Color(0xFF1A1A24);
  static const Color _amber = Color(0xFFE8A338);
  static const Color _cream = Color(0xFFF2EDE6);
  static const Color _muted = Color(0xFF6B6B7A);
  static const Color _border = Color(0xFF2A2A36);

  final List<String> _categories = [
    'Fiction', 'Non-Fiction', 'Romance', 'Mystery',
    'Science', 'Technology', 'History', 'Children',
    'Education', 'Self-Help', 'Biography', 'Art',
  ];

  Future<void> _submitBook() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; _success = null; });

    try {
      final token = await AuthService.getSavedToken();
      final res = await http.post(
        Uri.parse('$kBaseUrl/books'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'title': _titleCtrl.text.trim(),
          'description': _descCtrl.text.trim(),
          'category': _selectedCategory,
          'coverImage': _coverCtrl.text.trim().isEmpty
              ? null
              : _coverCtrl.text.trim(),
          'fileUrl': _fileCtrl.text.trim().isEmpty
              ? null
              : _fileCtrl.text.trim(),
          'isPaid': _isPaid,
          'price': _isPaid
              ? double.tryParse(_priceCtrl.text.trim()) ?? 0
              : 0,
        }),
      ).timeout(const Duration(seconds: 15));

      final body = jsonDecode(res.body);
      if (!mounted) return;

      setState(() => _loading = false);

      if (body['success'] == true) {
        setState(() => _success =
            'Book submitted! Waiting for admin approval.');
        _formKey.currentState!.reset();
        _titleCtrl.clear();
        _descCtrl.clear();
        _coverCtrl.clear();
        _fileCtrl.clear();
        _priceCtrl.clear();
        setState(() { _isPaid = false; _selectedCategory = 'Fiction'; });
      } else {
        setState(() => _error = body['message'] ?? 'Failed to submit book.');
      }
    } catch (e) {
      setState(() {
        _loading = false;
        _error = 'Server connect aagavillai.';
      });
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _coverCtrl.dispose();
    _fileCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded,
              size: 18, color: Colors.white54),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Add New Book',
          style: GoogleFonts.playfairDisplay(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: _cream,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Success banner
                if (_success != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4A8C7E).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: const Color(0xFF4A8C7E).withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle_outline_rounded,
                            size: 16, color: Color(0xFF4A8C7E)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(_success!,
                              style: GoogleFonts.lato(
                                  fontSize: 13,
                                  color: const Color(0xFF4A8C7E))),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // Error banner
                if (_error != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFCC4E2A).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: const Color(0xFFCC4E2A).withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline_rounded,
                            size: 16, color: Color(0xFFCC4E2A)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(_error!,
                              style: GoogleFonts.lato(
                                  fontSize: 13,
                                  color: const Color(0xFFCC4E2A))),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // Title
                const _Label('Book Title *'),
                const SizedBox(height: 8),
                _Field(
                  controller: _titleCtrl,
                  hint: 'Enter book title',
                  icon: Icons.title_rounded,
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Title required' : null,
                ),
                const SizedBox(height: 20),

                // Description
                const _Label('Description *'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _descCtrl,
                  maxLines: 4,
                  style: GoogleFonts.lato(fontSize: 14, color: _cream),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Description required' : null,
                  decoration: InputDecoration(
                    hintText: 'Write a short description...',
                    hintStyle: GoogleFonts.lato(fontSize: 13, color: _muted),
                    filled: true,
                    fillColor: _card,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: _border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: _border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: _amber, width: 1.5),
                    ),
                    contentPadding: const EdgeInsets.all(14),
                  ),
                ),
                const SizedBox(height: 20),

                // Category
                const _Label('Category *'),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: _card,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _border),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedCategory,
                      dropdownColor: _card,
                      style: GoogleFonts.lato(
                          fontSize: 14, color: _cream),
                      isExpanded: true,
                      items: _categories
                          .map((c) => DropdownMenuItem(
                                value: c,
                                child: Text(c),
                              ))
                          .toList(),
                      onChanged: (val) =>
                          setState(() => _selectedCategory = val!),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Cover Image URL
                const _Label('Cover Image URL (optional)'),
                const SizedBox(height: 8),
                _Field(
                  controller: _coverCtrl,
                  hint: 'https://example.com/cover.jpg',
                  icon: Icons.image_outlined,
                ),
                const SizedBox(height: 20),

                // File URL
                const _Label('Book File URL (optional)'),
                const SizedBox(height: 8),
                _Field(
                  controller: _fileCtrl,
                  hint: 'https://example.com/book.pdf',
                  icon: Icons.link_rounded,
                ),
                const SizedBox(height: 20),

                // Paid toggle
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _card,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _border),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Paid Book',
                            style: GoogleFonts.lato(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: _cream,
                            ),
                          ),
                          Text(
                            'Charge readers for this book',
                            style: GoogleFonts.lato(
                                fontSize: 11, color: _muted),
                          ),
                        ],
                      ),
                      Switch(
                        value: _isPaid,
                        onChanged: (val) =>
                            setState(() => _isPaid = val),
                        activeThumbColor: _amber,
                      ),
                    ],
                  ),
                ),

                // Price field
                if (_isPaid) ...[
                  const SizedBox(height: 20),
                  const _Label('Price (₹) *'),
                  const SizedBox(height: 8),
                  _Field(
                    controller: _priceCtrl,
                    hint: '99',
                    icon: Icons.currency_rupee_rounded,
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      if (_isPaid && (v == null || v.isEmpty)) {
                        return 'Price required';
                      }
                      return null;
                    },
                  ),
                ],

                const SizedBox(height: 36),

                // Submit button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _submitBook,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _amber,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: _amber.withValues(alpha: 0.5),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    child: _loading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Text(
                            'Submit for Approval',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700),
                          ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Reusable Widgets ──────────────────────────────────────────────────────────

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.lato(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: const Color(0xFFB0B0C0),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  static const Color _card = Color(0xFF1A1A24);
  static const Color _muted = Color(0xFF6B6B7A);
  static const Color _cream = Color(0xFFF2EDE6);
  static const Color _border = Color(0xFF2A2A36);
  static const Color _amber = Color(0xFFE8A338);

  const _Field({
    required this.controller,
    required this.hint,
    required this.icon,
    this.keyboardType,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      style: GoogleFonts.lato(fontSize: 14, color: _cream),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.lato(fontSize: 13, color: _muted),
        filled: true,
        fillColor: _card,
        prefixIcon: Icon(icon, size: 18, color: _muted),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _amber, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFCC4E2A)),
        ),
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 14),
      ),
    );
  }
}