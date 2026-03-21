# collect_tool

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.



$env:HTTP_PROXY = "http://127.0.0.1:7890"
$env:HTTPS_PROXY = "http://127.0.0.1:7890"
$env:PUB_NO_SSL_VALIDATION = "true"
$env:DART_VM_OPTIONS = "--no-ssl-validation"
$env:PUB_HOSTED_URL = "https://pub.dartlang.org"
$env:FLUTTER_STORAGE_BASE_URL = "https://storage.googleapis.com"

flutter clean
# 依赖下载（代理生效则会成功）
flutter pub get  

# 打包（代理生效则会成功）
flutter build windows 