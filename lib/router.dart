import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'core/constants.dart';
import 'providers/auth_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/auth/email_confirm_screen.dart';
import 'screens/home_screen.dart';
import 'screens/explore_screen.dart';
import 'screens/news_screen.dart';
import 'screens/community_screen.dart';
import 'screens/mypage_screen.dart';
import 'screens/post_detail_screen.dart';
import 'screens/post_write_screen.dart';
import 'screens/company/company_detail_screen.dart';
import 'screens/watchlist_group_detail_screen.dart';

// auth 상태를 라우터에서 참조하기 위한 provider
final _routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: authState.isLoggedIn ? '/' : '/auth/login',
    redirect: (context, state) {
      final loggedIn = authState.isLoggedIn;
      final onAuth = state.matchedLocation.startsWith('/auth');

      if (!loggedIn && !onAuth) return '/auth/login';
      if (loggedIn && onAuth) return '/';
      return null;
    },
    routes: [
      // ── 인증 화면 (BottomNav 없음) ─────────────────────────────────────────
      GoRoute(
        path: '/auth/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/auth/signup',
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: '/auth/confirm',
        builder: (context, state) {
          final email = (state.extra as Map<String, dynamic>?)?['email'] as String? ?? '';
          return EmailConfirmScreen(email: email);
        },
      ),

      // ── 메인 앱 (BottomNav 포함) ───────────────────────────────────────────
      ShellRoute(
        builder: (context, state, child) => _ScaffoldWithNav(child: child),
        routes: [
          GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
          GoRoute(path: '/explore', builder: (context, state) => const ExploreScreen()),
          GoRoute(path: '/news', builder: (context, state) => const NewsScreen()),
          GoRoute(path: '/community', builder: (context, state) => const CommunityScreen()),
          GoRoute(path: '/mypage', builder: (context, state) => const MyPageScreen()),
        ],
      ),

      // ── 전체 화면 (BottomNav 없음) ─────────────────────────────────────────
      GoRoute(
        path: '/company/:corpCode',
        builder: (context, state) => CompanyDetailScreen(
          corpCode: state.pathParameters['corpCode']!,
        ),
      ),
      GoRoute(
        path: '/watchlist/:groupId',
        builder: (context, state) => WatchlistGroupDetailScreen(
          groupId: state.pathParameters['groupId']!,
        ),
      ),
      GoRoute(
        path: '/community/post/:postId',
        builder: (context, state) => PostDetailScreen(
          postId: state.pathParameters['postId']!,
        ),
      ),
      GoRoute(
        path: '/community/write',
        builder: (context, state) {
          final extra = state.extra as Map<String, String?>?;
          return PostWriteScreen(
            corpCode: extra?['corpCode'],
            corpName: extra?['corpName'],
          );
        },
      ),
    ],
  );
});

// main.dart에서 사용
GoRouter createRouter(WidgetRef ref) => ref.watch(_routerProvider);

// ── BottomNav 쉘 ──────────────────────────────────────────────────────────────

class _ScaffoldWithNav extends StatelessWidget {
  const _ScaffoldWithNav({required this.child});

  final Widget child;

  static const _tabs = [
    (icon: Icons.home_outlined, activeIcon: Icons.home, label: '홈', path: '/'),
    (icon: Icons.search_outlined, activeIcon: Icons.search, label: '탐색', path: '/explore'),
    (icon: Icons.newspaper_outlined, activeIcon: Icons.newspaper, label: '뉴스', path: '/news'),
    (icon: Icons.forum_outlined, activeIcon: Icons.forum, label: '커뮤니티', path: '/community'),
    (icon: Icons.person_outline, activeIcon: Icons.person, label: '마이', path: '/mypage'),
  ];

  int _locationToIndex(String location) {
    if (location.startsWith('/explore')) return 1;
    if (location.startsWith('/news')) return 2;
    if (location.startsWith('/community')) return 3;
    if (location.startsWith('/mypage')) return 4;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    final currentIndex = _locationToIndex(location);

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (index) => context.go(_tabs[index].path),
        destinations: _tabs
            .map((tab) => NavigationDestination(
                  icon: Icon(tab.icon),
                  selectedIcon: Icon(tab.activeIcon, color: AppColors.primary),
                  label: tab.label,
                ))
            .toList(),
      ),
    );
  }
}
