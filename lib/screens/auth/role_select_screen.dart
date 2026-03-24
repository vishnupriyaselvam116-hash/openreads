import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'login_screen.dart';

class RoleSelectScreen extends StatelessWidget {
  const RoleSelectScreen({super.key});

  static const Color _bg    = Color(0xFF0F0F14);
  static const Color _amber = Color(0xFFE8A338);
  static const Color _cream = Color(0xFFF2EDE6);
  static const Color _muted = Color(0xFF6B6B7A);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              const SizedBox(height: 60),

              // Logo
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: _amber,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(Icons.auto_stories_rounded,
                    color: Colors.white, size: 32),
              ),
              const SizedBox(height: 20),

              Text(
                'OpenReads',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: _cream,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),

              Text(
                'Choose how you want to continue',
                style: GoogleFonts.lato(fontSize: 14, color: _muted),
              ),

              const Spacer(),

              // Reader card
              _RoleCard(
                icon: Icons.person_rounded,
                title: "I'm a Reader",
                subtitle: 'Browse, read and enjoy books',
                color: const Color(0xFF4A8C7E),
                onTap: () => _go(context, 'user'),
              ),
              const SizedBox(height: 14),

              // Author card
              _RoleCard(
                icon: Icons.edit_rounded,
                title: "I'm an Author",
                subtitle: 'Publish and manage your books',
                color: const Color(0xFF5E6AD2),
                onTap: () => _go(context, 'author'),
              ),
              const SizedBox(height: 14),

              // Admin card
              _RoleCard(
                icon: Icons.admin_panel_settings_rounded,
                title: 'Admin',
                subtitle: 'Manage the platform',
                color: _amber,
                onTap: () => _go(context, 'admin'),
              ),

              const Spacer(),

              Text(
                'OpenReads © 2024',
                style: GoogleFonts.lato(fontSize: 11, color: _muted),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _go(BuildContext context, String role) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => LoginScreen(role: role)),
    );
  }
}

// ── Role Card Widget ──────────────────────────────────────────────────────────
class _RoleCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  static const Color _cardBg = Color(0xFF1A1A24);
  static const Color _cream  = Color(0xFFF2EDE6);
  static const Color _muted  = Color(0xFF6B6B7A);

  const _RoleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _cardBg,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              // Icon box
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),

              // Text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.lato(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: _cream,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.lato(fontSize: 12, color: _muted),
                    ),
                  ],
                ),
              ),

              Icon(Icons.arrow_forward_ios_rounded, size: 14, color: _muted),
            ],
          ),
        ),
      ),
    );
  }
}