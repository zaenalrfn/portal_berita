// lib/main.dart
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'services/api_client.dart';
import 'services/auth_service.dart';
import 'services/news_service.dart';
import 'providers/auth_provider.dart';
import 'providers/news_provider.dart';
import 'pages/login_dialog.dart';
import 'pages/home_page.dart';
import 'pages/profile_page.dart';
import 'pages/add_news_page.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);

  // create ApiClient WITHOUT onUnauthenticated; we'll assign callback after runApp
  final api = ApiClient(baseUrl: 'http://10.28.196.58:8000');
  final authService = AuthService(api);
  final newsService = NewsService(api);

  runApp(
    MultiProvider(
      providers: [
        Provider.value(value: api),
        ChangeNotifierProvider(create: (_) => AuthProvider(authService)),
        ChangeNotifierProvider(create: (_) => NewsProvider(newsService)),
      ],
      child: const MyApp(),
    ),
  );

  // assign onUnauthenticated after the app is mounted so navigatorKey.currentContext is ready
  Future.microtask(() {
    api.onUnauthenticated = () async {
      final ctx = navigatorKey.currentContext;
      if (ctx == null) return;

      // 1) update provider state: logout local only (set sessionExpired=true)
      try {
        final auth = Provider.of<AuthProvider>(ctx, listen: false);
        await auth.logoutLocalOnly();
      } catch (e) {
        // ignore errors
      }

      // 2) OPTIONAL: show a small SnackBar (non-blocking) to inform user session expired
      // but do NOT force login dialog on app start.
      try {
        ScaffoldMessenger.of(ctx).showSnackBar(
          const SnackBar(
            content: Text(
              'Sesi Anda telah berakhir. Silakan login saat mengakses fitur.',
            ),
            duration: Duration(seconds: 4),
          ),
        );
      } catch (_) {}
    };
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = ThemeData.dark().copyWith(
      colorScheme: const ColorScheme.dark(primary: Colors.deepOrange),
      scaffoldBackgroundColor: const Color(0xFF2B2623),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: const Color(0xFF2B2623),
        selectedItemColor: Colors.orangeAccent,
        unselectedItemColor: Colors.grey[400],
      ),
    );

    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'News Portal',
      theme: theme,
      home: const RootPage(),
    );
  }
}

// rest of RootPage stays the same (use your existing code)
class RootPage extends StatefulWidget {
  const RootPage({super.key});
  @override
  State<RootPage> createState() => _RootPageState();
}

class _RootPageState extends State<RootPage> {
  int _current = 0;
  final pages = [HomePage(), AddNewsPage(), ProfilePage()];
  late VoidCallback _authListener;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NewsProvider>().fetchInitial();
      context.read<AuthProvider>().loadProfile();
    });

    _authListener = () {
      final auth = context.read<AuthProvider>();
      if (!auth.isLoggedIn && mounted) {
        if (_current == 1) {
          setState(() => _current = 0);
        }
      }
    };

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthProvider>().addListener(_authListener);
    });
  }

  @override
  void dispose() {
    try {
      context.read<AuthProvider>().removeListener(_authListener);
    } catch (_) {}
    super.dispose();
  }

  Future<void> _onNavTap(int index) async {
    if (index == 1 || index == 2) {
      final auth = context.read<AuthProvider>();
      if (!auth.isLoggedIn) {
        final didLogin = await showDialog<bool>(
          context: context,
          builder: (context) => const LoginDialog(),
        );

        if (didLogin == true) {
          await context.read<AuthProvider>().loadProfile();
          await context.read<NewsProvider>().refresh();
          setState(() => _current = index);
        } else {
          return;
        }
      } else {
        setState(() => _current = index);
      }
    } else {
      setState(() => _current = index);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: pages[_current],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _current,
        onTap: _onNavTap,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Beranda'),
          BottomNavigationBarItem(icon: Icon(Icons.add), label: 'Tambah'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }
}
