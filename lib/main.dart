import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'services/auth_service.dart';
import 'screens/auth/role_select_screen.dart';
import 'screens/user/user_home_screen.dart';
import 'screens/author/author_home_screen.dart';

void main() {
  runApp(const OpenReadsApp());
}

class OpenReadsApp extends StatelessWidget {
  const OpenReadsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OpenReads',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFE8A338),
        ),
        textTheme: GoogleFonts.latoTextTheme(ThemeData.dark().textTheme),
      ),
      home: const SplashRouter(),
      routes: {
        '/role-select': (_) => const RoleSelectScreen(),
        '/admin-home':  (_) => const AdminHome(),
        '/author-home': (_) => const AuthorHomeScreen(),
        '/user-home':   (_) => const UserHomeScreen(),
      },
    );
  }
}

// ── Splash / Auto Login Check ─────────────────────────────────────────────────
class SplashRouter extends StatefulWidget {
  const SplashRouter({super.key});

  @override
  State<SplashRouter> createState() => _SplashRouterState();
}

class _SplashRouterState extends State<SplashRouter> {
  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    final token = await AuthService.getSavedToken();
    final role  = await AuthService.getSavedRole();
    if (!mounted) return;
    if (token != null && role != null) {
      Navigator.pushReplacementNamed(
        context,
        role == 'admin'
            ? '/admin-home'
            : role == 'author'
                ? '/author-home'
                : '/user-home',
      );
    } else {
      Navigator.pushReplacementNamed(context, '/role-select');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF0F0F14),
      body: Center(
        child: CircularProgressIndicator(color: Color(0xFFE8A338)),
      ),
    );
  }
}

// ── Admin Home (Placeholder) ──────────────────────────────────────────────────
class AdminHome extends StatelessWidget {
  const AdminHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F14),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.admin_panel_settings_rounded,
                color: Color(0xFFE8A338), size: 64),
            const SizedBox(height: 16),
            Text(
              'Admin Dashboard',
              style: GoogleFonts.playfairDisplay(
                fontSize: 28,
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Welcome, Admin!',
              style: GoogleFonts.lato(
                  color: Colors.white54, fontSize: 13),
            ),
            const SizedBox(height: 32),
            TextButton(
              onPressed: () async {
                await AuthService.logout();
                if (context.mounted) {
                  Navigator.pushReplacementNamed(context, '/role-select');
                }
              },
              child: const Text('Logout',
                  style: TextStyle(color: Color(0xFFE8A338))),
            ),
          ],
        ),
      ),
    );
  }
}