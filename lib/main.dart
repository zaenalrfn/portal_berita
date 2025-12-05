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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);

  final api = ApiClient(baseUrl: 'http://api-portal-berita.test');
  final authService = AuthService(api);
  final newsService = NewsService(api);

  runApp(
    MultiProvider(
      providers: [
        Provider.value(value: api),
        ChangeNotifierProvider(create: (_) => AuthProvider(authService)),
        ChangeNotifierProvider(create: (_) => NewsProvider(newsService)),
      ],
      child: MyApp(), // newsService tidak perlu dilempar ke MyApp sekarang
    ),
  );
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

    return MaterialApp(title: 'News Portal', theme: theme, home: RootPage());
  }
}

class RootPage extends StatefulWidget {
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

    // prefetch: gunakan fetchInitial() (bukan fetch())
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // muat data awal news (page 1)
      context.read<NewsProvider>().fetchInitial();
      // muat profile user
      context.read<AuthProvider>().loadProfile();
    });

    _authListener = () {
      final auth = context.read<AuthProvider>();
      if (!auth.isLoggedIn && mounted) {
        // jika user logout dan sedang berada di Profile tab, pindah ke Home
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

  // cek apaka user sudah login atau belum buat akses halaman profile dan juga add news
  Future<void> _onNavTap(int index) async {
    if (index == 1 || index == 2) {
      final auth = context.read<AuthProvider>();
      if (!auth.isLoggedIn) {
        final didLogin = await showDialog<bool>(
          context: context,
          builder: (context) => const LoginDialog(),
        );

        if (didLogin == true) {
          // user barusan login sukses: muat ulang profile & data yang perlu
          await context.read<AuthProvider>().loadProfile();
          await context.read<NewsProvider>().refresh(); // gunakan refresh() bukan fetch()
          setState(() => _current = index);
        } else {
          // user batal / gagal login -> jangan pindah tab
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
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.add), label: 'Add'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
