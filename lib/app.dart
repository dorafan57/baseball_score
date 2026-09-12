import 'package:flutter/material.dart';

import 'screens/game_list_screen.dart';

/// スマートフォン向けレイアウトを想定しているため、通常の画面幅ではこの幅で
/// 中央固定表示する。
const double kAppMaxWidth = 480;

/// デスクトップとみなす画面幅のしきい値。これ以上の場合は [kAppMaxWidthWide] を使う。
const double kWideScreenBreakpoint = 700;

/// デスクトップなど横幅の広い画面で許容する最大幅。
const double kAppMaxWidthWide = 900;

class BaseballScoreApp extends StatelessWidget {
  const BaseballScoreApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '草野球スコア',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1B5E20),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF4F6F4),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1B5E20),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      // OS のテーマ設定（ライト／ダーク）に追従する。
      themeMode: ThemeMode.system,
      // ダイアログも含めた画面全体の最大幅を画面サイズに応じて制限する。
      builder: (context, child) {
        final screenWidth = MediaQuery.sizeOf(context).width;
        final maxWidth = screenWidth >= kWideScreenBreakpoint
            ? kAppMaxWidthWide
            : kAppMaxWidth;
        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: child,
          ),
        );
      },
      home: const GameListScreen(),
    );
  }
}
