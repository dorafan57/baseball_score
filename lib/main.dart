import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';

// アプリのルートウィジェット。外部（テストなど）から
// `package:baseball_score/main.dart` 経由でも参照できるよう再公開する。
export 'app.dart';

void main() {
  runApp(const ProviderScope(child: BaseballScoreApp()));
}
