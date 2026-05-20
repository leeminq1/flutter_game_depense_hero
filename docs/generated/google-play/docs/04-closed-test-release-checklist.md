# 비공개 테스트 출시 체크리스트

## 앱 세부정보

```text
App name: PIXEL GUARD:WAVE
Package name: com.min21.pixelguardwave
Version: 1.0.21+22
Default language: Korean - ko-KR
App or game: Game
Free or paid: Free
Category: Strategy
```

## AAB 업로드 전

- `pubspec.yaml`의 `versionCode`가 이전 업로드보다 큰지 확인한다.
- `applicationId`가 `com.min21.pixelguardwave`인지 확인한다.
- Play 업로드용 release signing이 적용되어 있는지 확인한다.
- APK가 아니라 Android App Bundle을 빌드한다.
- 실제 Android 기기에서 release 실행을 한 번 확인한다.

빌드 명령:

```powershell
flutter build appbundle --release
```

업로드 파일:

```text
build/app/outputs/bundle/release/app-release.aab
```

## 현재 테스트 빌드 주의

- 전체 Stage 해금 디버그가 켜져 있다.
- 이 상태는 비공개 테스트에서 Stage 전체 밸런스를 빠르게 확인하기 위한 것이다.
- 운영 배포 전에는 `kUnlockAllCampaignStagesForDevelopment`를 false로 바꾼다.
- AdMob SDK와 `AD_ID` 권한이 있으므로 Google Play 데이터 보안/광고 선언과 개인정보처리방침을 맞춘다.

## Play Console 순서

1. 비공개 테스트 트랙 출시 만들기.
2. AAB 업로드.
3. 출시 노트 입력.
4. 테스터 이메일 목록 또는 Google 그룹 연결.
5. 데이터 보안, 광고, 콘텐츠 등급, 타겟층, 개인정보처리방침 URL 확인.
6. 검토 제출.

## 테스트 목적 문구

```text
이번 비공개 테스트는 전체 Stage 해금 상태에서 핵심 요새 방어 루프, 보스 밸런스, 전투 가독성, 로컬 진행 저장, 보상형 재시도 광고 흐름을 검증하기 위한 테스트입니다.
```
