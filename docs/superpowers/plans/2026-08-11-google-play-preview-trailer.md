# Google Play Preview Trailer Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 실제 모바일 플레이 녹화 4개로 약 30초짜리 세로형 `Pixel Guard: Wave` Google Play 미리보기 영상을 제작한다.

**Architecture:** 원본 폴더는 읽기 전용으로 유지한다. 날짜별 출력 폴더에 로컬 FFmpeg 런타임, 장면 분석물, 렌더 스크립트, 최종 MP4와 검증 자료를 분리해 둔다. 1080×2640 원본은 시스템 바만 제외하고 전체 UI를 보존한 채 1080×1920 블러 배경 위에 중앙 배치한다.

**Tech Stack:** Python 3, Pillow, OpenCV, imageio-ffmpeg의 FFmpeg 바이너리, PowerShell

---

### Task 1: 출력 작업공간과 FFmpeg 준비

**Files:**
- Create: `C:\Users\min21\Desktop\구글플레이스토어배포\PIXEL GUARD\GooglePlay_미리보기_동영상_2026-08-11\work\python_pkgs\`
- Create: `C:\Users\min21\Desktop\구글플레이스토어배포\PIXEL GUARD\GooglePlay_미리보기_동영상_2026-08-11\source_manifest.csv`

- [ ] **Step 1: 날짜별 출력 폴더 생성**

```powershell
$output = 'C:\Users\min21\Desktop\구글플레이스토어배포\PIXEL GUARD\GooglePlay_미리보기_동영상_2026-08-11'
New-Item -ItemType Directory -Force -Path $output, "$output\work", "$output\qa" | Out-Null
```

- [ ] **Step 2: FFmpeg 패키지를 출력 작업공간에만 설치**

```powershell
python -m pip install --target "$output\work\python_pkgs" imageio-ffmpeg==0.6.0
```

Expected: `Successfully installed imageio-ffmpeg-0.6.0`.

- [ ] **Step 3: FFmpeg 경로 확인**

```powershell
$env:PYTHONPATH = "$output\work\python_pkgs"
$ffmpeg = python -c "import imageio_ffmpeg; print(imageio_ffmpeg.get_ffmpeg_exe())"
& $ffmpeg -version
```

Expected: 첫 줄에 `ffmpeg version`이 표시된다.

- [ ] **Step 4: 스킬 제공 인벤토리 실행**

```powershell
python 'C:\Users\min21\.codex\skills\creating-google-play-assets\scripts\asset_tool.py' inventory 'C:\Users\min21\Desktop\구글플레이스토어배포\PIXEL GUARD' --ffmpeg $ffmpeg | Set-Content -Encoding utf8 "$output\work\source_inventory.json"
```

Expected: `게임영상1.mp4`부터 `게임영상4.mp4`까지 크기, 길이, FPS, 오디오 존재 여부가 JSON에 기록된다.

### Task 2: 장면 후보 정밀 분석

**Files:**
- Create: `C:\Users\min21\Desktop\구글플레이스토어배포\PIXEL GUARD\GooglePlay_미리보기_동영상_2026-08-11\work\contact_*.jpg`
- Create: `C:\Users\min21\Desktop\구글플레이스토어배포\PIXEL GUARD\GooglePlay_미리보기_동영상_2026-08-11\edit_decisions.md`

- [ ] **Step 1: 각 영상에서 2초 간격 컨택트 시트 생성**

OpenCV로 프레임을 읽어 시트당 20장, 각 프레임 아래에 원본 파일명과 타임코드를 표시한다. 원본은 열기만 하고 출력은 `work` 아래에 저장한다.

- [ ] **Step 2: 다음 기능별로 움직임이 이어지는 3~5초 구간 선택**

```text
전투 훅: 게임영상2 또는 게임영상3의 다수 적·투사체 동시 등장 구간
건설/배치: 게임영상4의 길 만들기와 게임영상1의 타워 배치 구간
방어 진형: 게임영상1 또는 게임영상2의 타워·영웅·성벽이 함께 보이는 구간
강화 선택: 게임영상2 또는 게임영상3의 격자형 선택 UI가 열린 짧은 구간
최종 하이라이트: 게임영상2 후반 또는 게임영상3 중반의 가장 밀도 높은 전투 구간
```

- [ ] **Step 3: 선택 구간을 `edit_decisions.md`에 초 단위로 기록**

Expected: 합계 27.5초 분량의 실제 플레이 컷과 2.5초 엔드 카드가 정의된다.

### Task 3: 렌더 스크립트와 자막 애셋 작성

**Files:**
- Create: `C:\Users\min21\Desktop\구글플레이스토어배포\PIXEL GUARD\GooglePlay_미리보기_동영상_2026-08-11\work\render_preview.py`
- Create: `C:\Users\min21\Desktop\구글플레이스토어배포\PIXEL GUARD\GooglePlay_미리보기_동영상_2026-08-11\work\caption_*.png`
- Create: `C:\Users\min21\Desktop\구글플레이스토어배포\PIXEL GUARD\GooglePlay_미리보기_동영상_2026-08-11\work\end_card.png`

- [ ] **Step 1: Pillow로 투명 자막 PNG 생성**

다섯 자막 `성을 지켜라`, `길을 만들고`, `방어선을 세워`, `매 웨이브 더 강하게`, `끝까지 버텨라`를 화면 너비의 80% 안에 맞춘다. Windows의 `malgunbd.ttf`를 사용하고 밝은 아이보리 채움, 짙은 외곽선과 약한 그림자를 적용한다.

- [ ] **Step 2: 엔드 카드 PNG 생성**

```text
PIXEL GUARD
WAVE
```

배경은 마지막 실제 전투 프레임을 어둡게 처리하고, 중앙 게임명 이외의 클릭 유도 문구는 넣지 않는다.

- [ ] **Step 3: FFmpeg 필터 그래프 작성**

각 컷에 `crop=1080:2450:0:70`을 적용해 상태바와 내비게이션 바를 제거한다. 배경 레이어는 `scale=1080:1920:force_original_aspect_ratio=increase,crop=1080:1920,boxblur=30:10`으로 만들고, 전경은 `scale=-2:1920`으로 만든 다음 중앙에 오버레이한다. 자막 PNG는 게임 HUD를 가리지 않는 상단 안전영역에 오버레이한다.

- [ ] **Step 4: 오디오와 출력 설정 작성**

원본 오디오는 `loudnorm=I=-16:LRA=11:TP=-1.5`로 컷 간 레벨을 맞춘다. 최종 출력은 `libx264`, High profile, CRF 18, 30fps, `yuv420p`, AAC 48kHz 192kbps, `+faststart`로 설정한다.

### Task 4: 초안 렌더와 시각 검수

**Files:**
- Create: `C:\Users\min21\Desktop\구글플레이스토어배포\PIXEL GUARD\GooglePlay_미리보기_동영상_2026-08-11\work\preview_draft.mp4`
- Create: `C:\Users\min21\Desktop\구글플레이스토어배포\PIXEL GUARD\GooglePlay_미리보기_동영상_2026-08-11\qa\timeline_contact.jpg`

- [ ] **Step 1: 초안 렌더 실행**

```powershell
$env:PYTHONPATH = "$output\work\python_pkgs"
python "$output\work\render_preview.py" --draft
```

Expected: 약 30초 길이의 `preview_draft.mp4`가 생성된다.

- [ ] **Step 2: 1초 간격 타임라인 컨택트 시트 생성**

Expected: 30개 프레임에 초 단위 타임코드가 붙은 `timeline_contact.jpg`가 생성된다.

- [ ] **Step 3: 시작·컷 경계·엔드 카드 확인**

검사 항목은 첫 프레임 전투, 자막 겹침 없음, UI 변형 없음, 검은 여백 없음, 실패 팝업·개인 알림·개발 UI 없음, 엔드 카드 2.5초 유지다. 실패한 구간은 타임코드 또는 자막 위치를 수정하고 초안을 다시 렌더한다.

### Task 5: 최종 렌더와 납품 문서 작성

**Files:**
- Create: `C:\Users\min21\Desktop\구글플레이스토어배포\PIXEL GUARD\GooglePlay_미리보기_동영상_2026-08-11\Pixel_Guard_Wave_GooglePlay_Preview_30s_1080x1920.mp4`
- Create: `C:\Users\min21\Desktop\구글플레이스토어배포\PIXEL GUARD\GooglePlay_미리보기_동영상_2026-08-11\youtube_upload_settings.txt`
- Create: `C:\Users\min21\Desktop\구글플레이스토어배포\PIXEL GUARD\GooglePlay_미리보기_동영상_2026-08-11\source_manifest.csv`

- [ ] **Step 1: 최종 파일명으로 렌더**

```powershell
python "$output\work\render_preview.py" --final
```

- [ ] **Step 2: YouTube 업로드 설정 작성**

```text
제목: Pixel Guard: Wave | 공식 게임플레이 미리보기
공개 상태: 일부 공개 또는 공개
퍼가기: 허용
수익 창출/광고: 사용 안 함
연령 제한: 없음
Play Console: 이 동영상의 개별 YouTube URL을 입력
```

- [ ] **Step 3: 원본 출처 매니페스트 작성**

각 원본 파일의 절대 경로, 바이트 크기, 수정 시각, 사용한 시작·종료 타임코드와 최종 파일의 해상도·길이·코덱을 CSV에 기록한다.

### Task 6: 최종 검증

**Files:**
- Verify: `C:\Users\min21\Desktop\구글플레이스토어배포\PIXEL GUARD\GooglePlay_미리보기_동영상_2026-08-11\Pixel_Guard_Wave_GooglePlay_Preview_30s_1080x1920.mp4`

- [ ] **Step 1: FFmpeg 메타데이터 검사**

```powershell
& $ffmpeg -hide_banner -i "$output\Pixel_Guard_Wave_GooglePlay_Preview_30s_1080x1920.mp4"
```

Expected: 29~31초, H.264 High, 1080×1920, 30fps, yuv420p, AAC stereo 48kHz.

- [ ] **Step 2: 무결성과 검은 프레임 검사**

```powershell
& $ffmpeg -v error -i "$output\Pixel_Guard_Wave_GooglePlay_Preview_30s_1080x1920.mp4" -f null -
& $ffmpeg -hide_banner -i "$output\Pixel_Guard_Wave_GooglePlay_Preview_30s_1080x1920.mp4" -vf blackdetect=d=0.4:pix_th=0.02 -an -f null -
```

Expected: 디코딩 오류가 없고 의도하지 않은 검은 화면 구간이 보고되지 않는다.

- [ ] **Step 3: 원본 보존 확인**

`source_manifest.csv`에 기록한 원본 4개의 바이트 크기와 수정 시각을 현재 값과 대조한다. 하나라도 달라지면 납품을 중단하고 변경 원인을 확인한다.

- [ ] **Step 4: 최종 전체 재생과 대표 프레임 검사**

영상 시작, 5초, 10초, 15초, 20초, 25초, 29초 프레임을 열어 자막 가독성과 UI 보존을 확인하고, 전체 영상의 오디오 끊김·클리핑·컷 전환을 재생 검수한다.
