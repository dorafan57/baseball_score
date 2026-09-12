/// アプリのバージョン表示用定数。
///
/// GitHub Pagesへのデプロイワークフロー（`.github/workflows/deploy.yml`）が
/// ビルド時に `--dart-define=APP_VERSION=<年.月.日>-<その日の何回目のデプロイか>`
/// （例: `2026.09.13-2`）を渡して埋め込む。ローカルビルドなど未指定の場合は
/// 'dev' と表示する。
const String kAppVersion = String.fromEnvironment(
  'APP_VERSION',
  defaultValue: 'dev',
);

/// ビルド時に `--dart-define=BUILD_INFO=<値>` を渡すと、デプロイ物の識別用に
/// コミットハッシュを埋め込める（未指定なら空文字）。
/// デプロイワークフローはコミットSHA（短縮形）を渡す。
const String kBuildInfo = String.fromEnvironment('BUILD_INFO');
