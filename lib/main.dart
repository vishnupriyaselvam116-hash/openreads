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
        colorScheme: ColorScheme.dark(
          primary: const Color(0xFFE8A338),
        ),
        textTheme: GoogleFonts.latoTextTheme(ThemeData.dark().textTheme),
      ),
      home: const SplashRouter(),
      routes: {
        '/role-select':  (_) => const RoleSelectScreen(),
        '/admin-home':   (_) => const PlaceholderHome(role: 'Admin',  color: Color(0xFFE8A338)),
        '/author-home':  (_) => const PlaceholderHome(role: 'Author', color: Color(0xFF5E6AD2)),
        '/user-home':    (_) => const UserHomeScreen(),
        '/author-home': (_) => const AuthorHomeScreen(),
      },
    );
  }
}

// ── Auto login check ──────────────────────────────────────────────────────────
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

// ── Placeholder — Admin & Author (replace later) ──────────────────────────────
class PlaceholderHome extends StatelessWidget {
  final String role;
  final Color color;
  const PlaceholderHome({super.key, required this.role, required this.color});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F14),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_rounded, color: color, size: 64),
            const SizedBox(height: 16),
            Text(
              '$role Home',
              style: GoogleFonts.playfairDisplay(
                fontSize: 28,
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Login successful!',
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
              child: Text('Logout', style: TextStyle(color: color)),
            ),
          ],
        ),
      ),
    );
  }
}