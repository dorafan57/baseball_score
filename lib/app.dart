import 'package:flutter/material.dart';

import 'screens/game_list_screen.dart';

/// スマートフォン向けレイアウトを想定しているため、
/// デスクトップなど横幅の広い画面では中央にこの幅で固定表示する。
const double kAppMaxWidth = 480;

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
      // ダイアログも含めた画面全体を最大幅 480px に制限する。
      builder: (context, child) => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: kAppMaxWidth),
          child: child,
        ),
      ),
      home: const GameListScreen(),
    );
  }
}
