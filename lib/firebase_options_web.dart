import 'package:firebase_core/firebase_core.dart';

/// Web用の Firebase 設定値。
///
/// `flutterfire configure`（対話的なログインが必要）は使わず、
/// ビルド時の `--dart-define` から読み込む。値は GitHub Actions の
/// Secrets、またはローカル開発では `dart_define.local.json`
/// （`.gitignore` 対象、`dart_define.example.json` を参考に作成）から渡す。
FirebaseOptions buildFirebaseOptions() => const FirebaseOptions(
  apiKey: String.fromEnvironment('FIREBASE_API_KEY'),
  appId: String.fromEnvironment('FIREBASE_APP_ID'),
  messagingSenderId: String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID'),
  projectId: String.fromEnvironment('FIREBASE_PROJECT_ID'),
  authDomain: String.fromEnvironment('FIREBASE_AUTH_DOMAIN'),
  storageBucket: String.fromEnvironment('FIREBASE_STORAGE_BUCKET'),
);
