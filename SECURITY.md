# Security

## Scope

현재 앱은 서버 계정, 로그인, 결제, 클라우드 저장을 운영하지 않는다. 주요 보안/개인정보
관심사는 로컬 저장, 광고 SDK, 외부 에셋 출처다.

## Rules

- 비밀키와 서명 파일은 저장소에 커밋하지 않는다.
- Play 업로드용 keystore 정보는 로컬 `key.properties`로 관리한다.
- 진행도와 설정은 기기 내부 저장소에 둔다.
- 광고 SDK 사용 여부와 AD_ID 권한은 개인정보처리방침과 Google Play 데이터 보안 문서에 반영한다.

## Asset Hygiene

- AI 생성 에셋은 생성 목적, 사용 위치, 라이선스/출처를 문서에 남긴다.
- 외부 LPC/오픈소스 에셋은 원본 라이선스를 확인한다.
- 스크린샷/스토어 이미지는 `docs/generated/google-play`에 보관한다.
