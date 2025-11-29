import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/api_client.dart';
import 'services/auth_service.dart';
import 'services/news_service.dart';
import 'providers/auth_provider.dart';
import 'providers/news_provider.dart';
import 'pages/home_page.dart';
// import 'pages/add_news_page.dart';
// import 'pages/profile_page.dart';

void main() {
  final api = ApiClient(baseUrl: 'http://api-portal-berita.test'); // ganti baseUrl
  final authService = AuthService(api);
  final newsService = NewsService(api);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider(authService)),
        ChangeNotifierProvider(create: (_) => NewsProvider(newsService)),
      ],
      child: MyApp(newsService: newsService),
    ),
  );
}

class MyApp extends StatelessWidget {
  final NewsService newsService;
  const MyApp({super.key, required this.newsService});

  @override
  Widget build(BuildContext context) {
    final theme = ThemeData.dark().copyWith(
      colorScheme: ColorScheme.dark(primary: Colors.deepOrange),
      scaffoldBackgroundColor: const Color(0xFF2B2623), // dark brown
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: const Color(0xFF2B2623),
        selectedItemColor: Colors.orangeAccent,
        unselectedItemColor: Colors.grey[400],
      )
    );

    return MaterialApp(
      title: 'News Portal',
      theme: theme,
      home: RootPage(),
    );
  }
}

class RootPage extends StatefulWidget {
  @override
  State<RootPage> createState() => _RootPageState();
}

class _RootPageState extends State<RootPage> {
  int _current = 0;
  final pages = [HomePage()];

  @override
  void initState() {
    super.initState();
    // prefetch news
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NewsProvider>().fetch();
      context.read<AuthProvider>().loadProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: pages[_current],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _current,
        onTap: (i) => setState(() => _current = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.add_box), label: 'Add'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
