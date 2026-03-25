# MakeSchedule

선택한 텍스트에서 AI로 일정을 추출하여 macOS 캘린더에 등록하는 PopClip Extension입니다.

## 기능

메일, SNS, 메시지 등에서 모임/일정 공지 텍스트를 선택하면:

1. **Gemini 2.0 Flash**가 텍스트에서 일정 정보를 JSON으로 구조화 추출
2. **SwiftUI 네이티브 대화상자**에서 추출된 일정을 검수/편집
3. **Calendar.app**에 EventKit으로 정확하게 등록

## 주요 특징

- Gemini AI가 한국어 일정 텍스트를 정확하게 파싱
- macOS 네이티브 DatePicker로 날짜/시간 편집
- 캘린더 드롭다운으로 등록할 캘린더 선택 (마지막 선택 기억)
- 종일 일정, 여러 날 일정 지원
- 장소, 메모 (강의내용, 주소, 링크 등) 자동 정리
- 에러 시 macOS 알림으로 안내

## 사용 예시

**입력 텍스트:**

```text
[AI Study 110 -5차 모임공지] 3월 26일 목요일에 진행합니다~!
일시: 3월 26일(목) 저녁 7시
장소: 서울AI허브 희경빌딩 C동 지하강의실
주소: 서초구 매헌로8길 47
지도: https://naver.me/GSUAn4rd
```

**추출 결과 → 편집 대화상자 → 캘린더 등록**

## 설치

### 사전 요구사항

- macOS 13+ (Ventura) — **Apple Silicon (M1/M2/M3/M4) 필수**
- [PopClip](https://www.popclip.app/) 4586+
- [Xcode Command Line Tools](https://developer.apple.com/xcode/) (SwiftUI 빌드용)
- Python 3.11+
- Gemini API Key ([Google AI Studio](https://aistudio.google.com/)에서 무료 발급)

> Intel Mac에서는 소스에서 직접 빌드하면 동작합니다.

### 설치 방법

1. SwiftUI 앱 빌드: `cd MakeScheduleUI && swift build -c release`
2. 바이너리 복사: `cp .build/release/MakeScheduleUI ../MakeSchedule.popclipext/`
3. `MakeSchedule.popclipext` 폴더를 더블클릭하여 PopClip에 설치
4. PopClip 설정에서 **Gemini API Key** 입력
5. 첫 실행 시 `google-genai` 패키지가 자동 설치됩니다
6. 첫 실행 시 캘린더 접근 권한을 허용해주세요

## 사용법

1. 일정이 포함된 텍스트를 **드래그하여 선택**
2. PopClip 메뉴에서 **캘린더 아이콘** 클릭
3. 편집 대화상자에서 내용 확인/수정
4. 캘린더 선택 후 **등록** 클릭

## 문제 해결

- 로그 확인: `tail -f /tmp/makeschedule.log`
- 설치 초기화: `rm ~/.makeschedule_setup_done_v2`
- 캘린더 권한: 시스템 설정 > 개인정보 > 캘린더
