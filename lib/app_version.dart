/// アプリのバージョン表示用定数。
///
/// [kAppVersion] は `pubspec.yaml` の `version:` と合わせて手動で更新する。
const String kAppVersion = '1.0.0+1';

/// ビルド時に `--dart-define=BUILD_INFO=<値>` を渡すと、デプロイ物の識別用に
/// コミットハッシュやビルド日時などを埋め込める（未指定なら空文字）。
/// 例: `flutter build web --dart-define=BUILD_INFO=$(git rev-parse --short HEAD)`
const String kBuildInfo = String.fromEnvironment('BUILD_INFO');
