# 비공개 테스트 출시 체크리스트

## 앱 세부정보

```text
App name: PIXEL GUARD:WAVE
Package name: com.min21.pixelguardwave
Default language: Korean - ko-KR
App or game: Game
Free or paid: Free
Category: Strategy
```

## AAB 업로드 전

- `applicationId`가 `com.min21.pixelguardwave`인지 확인.
- Play 업로드용 릴리즈 서명 설정 확인.
- APK만 만들지 말고 Android App Bundle을 빌드.
- 새 업로드마다 `versionCode` 증가.
- 가능하면 실제 Android 기기에서 테스트.

권장 빌드 명령:

```powershell
flutter build appbundle --release
```

예상 출력:

```text
build/app/outputs/bundle/release/app-release.aab
```

## Play Console 설정 순서

1. 앱 만들기.
2. `게임` 선택.
3. `무료` 선택.
4. 기본 스토어 등록정보 작성.
5. 개인정보처리방침 URL 입력.
6. 데이터 보안 작성.
7. 콘텐츠 등급 작성.
8. 타겟층 작성.
9. 앱 액세스 권한 작성.
10. 광고 선언 작성.
11. 스크린샷과 기능 그래픽 업로드.
12. 비공개 테스트 트랙 출시 만들기.
13. 이메일 목록 또는 Google 그룹으로 테스터 추가.
14. 검토 제출.

## 현재 테스트 목적 문구

```text
이번 비공개 테스트는 핵심 요새 방어 루프, 영웅 선택, 스테이지 흐름, 전투 가독성, 로컬 진행 저장을 검증하기 위한 테스트입니다.
```

## 제출 전 위험 요소

현재 `android/app/build.gradle.kts`는 별도로 바꾸지 않았다면 릴리즈 빌드에 debug signing config를 사용합니다. Google Play 업로드에는 일반적으로 올바른 릴리즈 서명 또는 Play App Signing 설정이 필요합니다. 최종 비공개 테스트 업로드 전에 서명을 설정하세요.
