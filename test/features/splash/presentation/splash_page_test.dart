import 'package:cookmate/features/splash/presentation/splash_page.dart';
import 'package:cookmate/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

GoRouter _buildRouter() {
  return GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(path: '/splash', builder: (context, state) => const SplashPage()),
      GoRoute(
        path: '/home/chat',
        builder: (context, state) =>
            const Scaffold(body: Center(child: Text('chat-home'))),
      ),
    ],
  );
}

Widget _wrap(GoRouter router, {Locale locale = const Locale('en')}) {
  return MaterialApp.router(
    routerConfig: router,
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
  );
}

String _currentPath(GoRouter router) =>
    router.routerDelegate.currentConfiguration.uri.path;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('renders logo, title, and description', (tester) async {
    final router = _buildRouter();
    await tester.pumpWidget(_wrap(router));
    await tester.pump();

    final l10n = AppLocalizations.of(tester.element(find.byType(SplashPage)));

    expect(find.byType(Image), findsOneWidget);
    expect(find.text(l10n.splashTitle), findsOneWidget);
    expect(find.text(l10n.splashDescription), findsOneWidget);
  });

  testWidgets('stays on splash before 5 seconds elapse', (tester) async {
    final router = _buildRouter();
    await tester.pumpWidget(_wrap(router));
    await tester.pump(const Duration(seconds: 4));

    expect(_currentPath(router), '/splash');
    expect(find.text('chat-home'), findsNothing);
  });

  testWidgets('navigates to /home/chat after 5 seconds', (tester) async {
    final router = _buildRouter();
    await tester.pumpWidget(_wrap(router));
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();

    expect(_currentPath(router), '/home/chat');
    expect(find.text('chat-home'), findsOneWidget);
  });
}
