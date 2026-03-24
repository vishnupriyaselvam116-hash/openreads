import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/auth_service.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  final String role;
  const RegisterScreen({super.key, required this.role});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey    = GlobalKey<FormState>();
  final _nameCtrl   = TextEditingController();
  final _emailCtrl  = TextEditingController();
  final _passCtrl   = TextEditingController();
  final _penNameCtrl = TextEditingController();
  bool _obscure  = true;
  bool _loading  = false;
  String? _error;

  static const Color _bg    = Color(0xFF0F0F14);
  static const Color _cream = Color(0xFFF2EDE6);
  static const Color _muted = Color(0xFF6B6B7A);

  Color get _accent => widget.role == 'author'
      ? const Color(0xFF5E6AD2)
      : const Color(0xFF4A8C7E);

  String get _roleLabel =>
      widget.role == 'author' ? 'Author' : 'Reader';

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });

    final result = await AuthService.register(
      name:     _nameCtrl.text.trim(),
      email:    _emailCtrl.text.trim(),
      password: _passCtrl.text,
      role:     widget.role,
      penName:  widget.role == 'author'
                    ? _penNameCtrl.text.trim()
                    : null,
    );

    if (!mounted) return;
    setState(() => _loading = false);

    if (result.success) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        widget.role == 'author' ? '/author-home' : '/user-home',
        (_) => false,
      );
    } else {
      setState(() => _error = result.message);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _penNameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded,
              size: 18, color: Colors.white54),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),

                // Role badge
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _accent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                    border:
                        Border.all(color: _accent.withOpacity(0.25)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        widget.role == 'author'
                            ? Icons.edit_rounded
                            : Icons.person_rounded,
                        size: 13,
                        color: _accent,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '$_roleLabel Registration',
                        style: GoogleFonts.lato(
                          fontSize: 12,
                          color: _accent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                Text(
                  'Create account',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 30,
                    fontWeight: FontWeight.w700,
                    color: _cream,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Join OpenReads as a ${_roleLabel.toLowerCase()}',
                  style: GoogleFonts.lato(fontSize: 14, color: _muted),
                ),
                const SizedBox(height: 36),

                // Error banner
                if (_error != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFCC4E2A).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color:
                              const Color(0xFFCC4E2A).withOpacity(0.3)),
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

                // Name
                _InputLabel('Full Name'),
                const SizedBox(height: 8),
                _Field(
                  controller: _nameCtrl,
                  hint: 'Your name',
                  icon: Icons.person_outline_rounded,
                  accent: _accent,
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Name required' : null,
                ),
                const SizedBox(height: 20),

                // Pen name — author only
                if (widget.role == 'author') ...[
                  _InputLabel('Pen Name (optional)'),
                  const SizedBox(height: 8),
                  _Field(
                    controller: _penNameCtrl,
                    hint: 'Your author pen name',
                    icon: Icons.draw_outlined,
                    accent: _accent,
                  ),
                  const SizedBox(height: 20),
                ],

                // Email
                _InputLabel('Email'),
                const SizedBox(height: 8),
                _Field(
                  controller: _emailCtrl,
                  hint: 'your@email.com',
                  icon: Icons.email_outlined,
                  accent: _accent,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Email required';
                    if (!v.contains('@')) return 'Valid email required';
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Password
                _InputLabel('Password'),
                const SizedBox(height: 8),
                _Field(
                  controller: _passCtrl,
                  hint: 'Min 6 characters',
                  icon: Icons.lock_outline_rounded,
                  accent: _accent,
                  obscure: _obscure,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscure
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      size: 18,
                      color: _muted,
                    ),
                    onPressed: () =>
                        setState(() => _obscure = !_obscure),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Password required';
                    if (v.length < 6) return 'Min 6 characters';
                    return null;
                  },
                ),
                const SizedBox(height: 36),

                // Register button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _register,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _accent,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: _accent.withOpacity(0.5),
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
                        : Text(
                            'Create Account',
                            style: GoogleFonts.lato(
                                fontSize: 16,
                                fontWeight: FontWeight.w700),
                          ),
                  ),
                ),
                const SizedBox(height: 24),

                // Login link
                Center(
                  child: GestureDetector(
                    onTap: () => Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            LoginScreen(role: widget.role),
                      ),
                    ),
                    child: RichText(
                      text: TextSpan(
                        style: GoogleFonts.lato(
                            fontSize: 14, color: _muted),
                        children: [
                          const TextSpan(
                              text: 'Already have an account? '),
                          TextSpan(
                            text: 'Sign In',
                            style: TextStyle(
                              color: _accent,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
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

class _InputLabel extends StatelessWidget {
  final String text;
  const _InputLabel(this.text);

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
  final Color accent;
  final bool obscure;
  final TextInputType? keyboardType;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;

  static const Color _cardBg = Color(0xFF1A1A24);
  static const Color _muted  = Color(0xFF6B6B7A);
  static const Color _cream  = Color(0xFFF2EDE6);
  static const Color _border = Color(0xFF2A2A36);

  const _Field({
    required this.controller,
    required this.hint,
    required this.icon,
    required this.accent,
    this.obscure = false,
    this.keyboardType,
    this.suffixIcon,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      validator: validator,
      style: GoogleFonts.lato(fontSize: 15, color: _cream),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.lato(fontSize: 14, color: _muted),
        filled: true,
        fillColor: _cardBg,
        prefixIcon: Icon(icon, size: 18, color: _muted),
        suffixIcon: suffixIcon,
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
          borderSide: BorderSide(color: accent, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFCC4E2A)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
              color: Color(0xFFCC4E2A), width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 14),
      ),
    );
  }
}