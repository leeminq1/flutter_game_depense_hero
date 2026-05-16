# Google Play 비공개 테스트 입력 자료

앱 이름: `PIXEL GUARD:WAVE`  
패키지 이름: `com.min21.pixelguardwave`  
현재 버전: `1.0.18+19`  
기본 언어: `한국어 - ko-KR`  
트랙: `비공개 테스트`

## 복사해서 입력할 파일

- `01-store-listing-ko-KR.md`: 스토어 등록정보 문구
- `02-app-content-and-data-safety.md`: 앱 콘텐츠, 데이터 보안, 개인정보처리방침 답변
- `03-content-rating-and-target-audience.md`: 콘텐츠 등급 및 타겟층 답변
- `04-closed-test-release-checklist.md`: 비공개 테스트 출시 체크리스트
- `05-privacy-policy-url-and-pages.md`: GitHub Pages 개인정보처리방침 URL과 설정
- `06-graphic-assets.md`: 스크린샷 및 그래픽 에셋 안내

## 현재 코드 기준

- Android App Bundle 경로:
  `build/app/outputs/bundle/release/app-release.aab`
- `pubspec.yaml` 버전: `1.0.18+19`
- `google_mobile_ads`가 포함되어 있고, Android main manifest에 `AD_ID` 권한과 AdMob
  application id meta-data가 있다.
- 진행도, 설정, 업그레이드, 보상 기록은 기기 내부 로컬 저장소에 저장된다.
- 현재 비공개 테스트는 전체 Stage 해금 디버그가 켜져 있다.

## 제출 전 재확인

- 광고/데이터 보안 양식에서 광고 ID 사용 여부를 현재 manifest와 맞춘다.
- 운영 배포 전에는 전체 Stage 해금 디버그를 제거하고 문서를 다시 갱신한다.
- 새 업로드마다 versionCode를 올린다.
