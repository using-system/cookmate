import 'package:cookmate/features/home/presentation/home_shell.dart';
import 'package:cookmate/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

GoRouter _buildRouter() {
  return GoRouter(
    initialLocation: '/home/chat',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            HomeShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home/chat',
                builder: (context, state) =>
                    const Scaffold(body: Center(child: Text('chat'))),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home/settings',
                builder: (context, state) =>
                    const Scaffold(body: Center(child: Text('settings'))),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

Widget _wrap(GoRouter router) {
  return ProviderScope(
    child: MaterialApp.router(
      routerConfig: router,
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('renders bottom navigation bar with Chat and Settings tabs',
      (tester) async {
    final router = _buildRouter();
    await tester.pumpWidget(_wrap(router));
    await tester.pumpAndSettle();

    final l10n = AppLocalizations.of(
      tester.element(find.byType(HomeShell)),
    );

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text(l10n.homeTabChat), findsOneWidget);
    expect(find.text(l10n.homeTabSettings), findsOneWidget);
  });

  testWidgets('Chat tab is selected on initial load', (tester) async {
    final router = _buildRouter();
    await tester.pumpWidget(_wrap(router));
    await tester.pumpAndSettle();

    final navBar = tester.widget<NavigationBar>(find.byType(NavigationBar));
    expect(navBar.selectedIndex, 0);
  });
}
