# Suggested Commands

Windows PowerShell workspace commands:

- List files: `Get-ChildItem -Recurse -Filter *.dart lib`
- Search text fallback when `rg` is unavailable: `Get-ChildItem -Path lib,test -Recurse -Filter *.dart | Select-String -Pattern 'pattern'`
- Analyze: `flutter analyze`
- Run tests: `flutter test`
- Run one test file: `flutter test test/<file>_test.dart`
- Format Dart files: `dart format <paths>`
- Run app for Chrome/web: `flutter run -d chrome`
- Build web validation: `flutter build web`
- Git status: `git status --short`

Note: `rg.exe` may be unavailable or blocked in this environment; use PowerShell `Get-ChildItem` + `Select-String` fallback.