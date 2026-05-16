# Design Docs Index

이 폴더는 현재 코드 기준의 게임 감각, 밸런스, 맵 제작 원칙을 정리한다.

## Active

| 문서 | 목적 |
| --- | --- |
| `gameplay-balance-pass.md` | 현재 수치 밸런스와 조정 의도 |
| `combat-pillars.md` | 전투가 지켜야 하는 감각 원칙 |
| `defense-roster-bible.md` | 방어 유닛의 판타지/실루엣 참고 |
| `enemy-roster-bible.md` | 적 역할과 아트 방향 참고 |
| `map-authoring/README.md` | 새 Stage를 만들 때의 작업 규칙 |
| `map-authoring/stage-atlas.md` | Stage 1~30의 실제 구현 요약 |
| `stage-art-bible.md` | 환경 테마와 시각 진행 |
| `audio-architecture.md` | 오디오 서비스와 성능 규칙 |

## Generated Pair

정확한 수치표는 `docs/generated/current-game-data-snapshot.md`에서 확인한다. 이 파일은
`flutter test tool/export_game_data_docs.dart`로 갱신한다.

## 용어

- 현재 문서/게임명: `Pixel Guard: Wave`
- 현재 플레이어 용어: `Stage`, `Wave`, `Camp`, `설계 카드`
- 과거 호환 용어: `Citadel Siege`, `Siege`, `Act`, `Cycle`

과거 용어는 역사 설명이나 코드 호환 타입 설명에만 사용한다.
