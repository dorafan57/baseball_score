import 'package:go_router/go_router.dart';

import 'screens/game_list_screen.dart';
import 'screens/score_input_screen.dart';

/// アプリ全体のルート定義。
///
/// GitHub Pages（静的ホスティング、サーバ側リライトなし）で配信するため、
/// Flutter Web標準のハッシュURL戦略（`#/...`）のまま使う
/// （`usePathUrlStrategy()` は呼ばない）。ハッシュ部分はサーバーへ送られない
/// ため、直接そのURLを開いても常に同じ `index.html` が返り、404対策が不要になる。
GoRouter buildRouter() => GoRouter(
  routes: [
    GoRoute(path: '/', builder: (context, state) => const GameListScreen()),
    GoRoute(
      path: '/game/:gameId',
      builder: (context, state) =>
          ScoreInputScreen(gameId: state.pathParameters['gameId']!),
    ),
  ],
);
