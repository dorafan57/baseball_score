import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'providers/theme_mode_provider.dart';
import 'router.dart';

/// PC（マウス操作）でも横スクロール表の内容をドラッグでスクロールできるようにする。
/// 既定の `MaterialScrollBehavior` はタッチ・スタイラスのみが対象のため、
/// マウスドラッグでは表がスクロールできず「見切れて見える」問題が起きていた。
class _AppScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.stylus,
    PointerDeviceKind.trackpad,
  };
}

/// スマートフォン向けレイアウトを想定しているため、通常の画面幅ではこの幅で
/// 中央固定表示する。
const double kAppMaxWidth = 480;

/// デスクトップとみなす画面幅のしきい値。これ以上の場合は [kAppMaxWidthWide] を使う。
const double kWideScreenBreakpoint = 700;

/// デスクトップなど横幅の広い画面で許容する最大幅。
const double kAppMaxWidthWide = 900;

class BaseballScoreApp extends ConsumerStatefulWidget {
  const BaseballScoreApp({super.key});

  @override
  ConsumerState<BaseballScoreApp> createState() => _BaseballScoreAppState();
}

class _BaseballScoreAppState extends ConsumerState<BaseballScoreApp> {
  // GoRouterはウィジェットごとに一度だけ生成する
  // （ウィジェットテストのたびに新しいナビゲーション履歴で始められるようにするため）。
  late final GoRouter _router = buildRouter();

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    return MaterialApp.router(
      routerConfig: _router,
      title: '草野球スコア',
      debugShowCheckedModeBanner: false,
      scrollBehavior: _AppScrollBehavior(),
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
      // 設定画面で選択したテーマ（既定は端末設定に追従）。
      themeMode: themeMode,
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
    );
  }
}
