import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/models/article_model.dart';
import '../../article/presentation/article_details_screen.dart';
import '../../breaking_news/presentation/breaking_news_provider.dart';
import '../../breaking_news/presentation/breaking_news_screen.dart';
import '../../categories/presentation/categories_screen.dart';
import '../../home/data/home_providers.dart';
import '../../home/presentation/home_screen.dart';
import '../../magazine/presentation/magazine_screen.dart';
import '../../notifications/presentation/notifications_screen.dart';
import '../../settings/presentation/settings_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(milliseconds: 1400), () {
      if (mounted) context.go('/main');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          color: Colors.black,
        ),
        child: Center(
          child: Image.asset(
            'assets/images/splash.jpg',
            width: 320,
            height: 320,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}

class MainNavScreen extends ConsumerStatefulWidget {
  const MainNavScreen({super.key});

  @override
  ConsumerState<MainNavScreen> createState() => _MainNavScreenState();
}

class _MainNavScreenState extends ConsumerState<MainNavScreen> {
  int index = 0;

  @override
  Widget build(BuildContext context) {
    const pages = [
      HomeScreen(),
      CategoriesScreen(),
      BreakingNewsScreen(),
      MagazineScreen(),
      SettingsScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: index, children: pages),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.only(bottom: 6),
        child: NavigationBar(
          selectedIndex: index,
          onDestinationSelected: (value) {
            if (value == 0 || value == 2) {
              ref.invalidate(breakingTickerProvider);
              ref.invalidate(breakingNewsPageProvider);
            }
            setState(() => index = value);
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: '\u0627\u0644\u0631\u0626\u064a\u0633\u064a\u0629',
            ),
            NavigationDestination(
              icon: Icon(Icons.grid_view_outlined),
              selectedIcon: Icon(Icons.grid_view_rounded),
              label: '\u0627\u0644\u0623\u0642\u0633\u0627\u0645',
            ),
            NavigationDestination(
              icon: Icon(Icons.campaign_outlined),
              selectedIcon: Icon(Icons.campaign),
              label: '\u0627\u0644\u0639\u0627\u062c\u0644',
            ),
            NavigationDestination(
              icon: Icon(Icons.menu_book_outlined),
              selectedIcon: Icon(Icons.menu_book_rounded),
              label:
                  '\u0627\u0644\u0645\u062c\u0644\u0629 \u0627\u0644\u0631\u0642\u0645\u064a\u0629',
            ),
            NavigationDestination(
              icon: Icon(Icons.tune_outlined),
              selectedIcon: Icon(Icons.tune),
              label: '\u0627\u0644\u0645\u0632\u064a\u062f',
            ),
          ],
        ),
      ),
    );
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/main', builder: (_, __) => const MainNavScreen()),
      GoRoute(
        path: '/notifications',
        builder: (_, __) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/article/:id',
        builder: (_, state) {
          final article = state.extra as ArticleModel?;
          final id = int.parse(state.params['id']!);
          return ArticleDetailsScreen(articleId: id, initialArticle: article);
        },
      ),
    ],
  );
});
