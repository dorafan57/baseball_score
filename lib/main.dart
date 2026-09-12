import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'firebase_options_web.dart';

// アプリのルートウィジェット。外部（テストなど）から
// `package:baseball_score/main.dart` 経由でも参照できるよう再公開する。
export 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: buildFirebaseOptions());
  await FirebaseAuth.instance.signInAnonymously();
  runApp(const ProviderScope(child: BaseballScoreApp()));
}
