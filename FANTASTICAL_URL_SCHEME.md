# Fantastical URL Scheme 레퍼런스

> 출처: https://flexibits.com/fantastical-ios/help/integration

## URL Scheme

**기본 스킴:** `x-fantastical3://`

## 액션

### 1. parse — 일정 생성

`x-fantastical3://parse?[parameters]`

#### 파라미터

| 파라미터 | 설명 | 형식 |
|---------|------|------|
| `sentence` | 자연어 입력 (**사용 시 다른 파라미터 무시됨**) | URL encoded |
| `title` | 일정 제목 | URL encoded |
| `notes` | 메모 | URL encoded |
| `location` | 장소 | URL encoded |
| `url` | 관련 URL | URL encoded |
| `start` | 시작 시간 | `yyyy-MM-dd HH:mm` |
| `end` | 종료 시간 | `yyyy-MM-dd HH:mm` |
| `due` | 마감 시간 | `yyyy-MM-dd HH:mm` |
| `reminder` | 알림 | URL encoded |
| `attendees` | 참석자 (쉼표 구분 이메일) | URL encoded |
| `allDay` | 종일 이벤트 | `0` 또는 `1` |
| `availability` | 가용성 | `free`, `busy`, `tentative`, `unavailable` |
| `private` | 비공개 (Exchange만) | `0` 또는 `1` |
| `add` | 자동 추가 (확인 없이) | `1` 설정 시 |

#### 중요 사항
- **`sentence` 파라미터 사용 시 다른 파라미터는 무시됨**
- `sentence` 없이 개별 파라미터(`title`, `start`, `end`, `location` 등)를 조합하면 더 정확한 제어 가능

#### 예시
```
# 자연어 방식 (sentence)
x-fantastical3://parse?sentence=Meeting%20tomorrow%20at%203pm

# 개별 파라미터 방식 (더 정확)
x-fantastical3://parse?title=AI%20Study&start=2026-03-26%2019:00&end=2026-03-26%2020:00&location=서울AI허브&notes=기초강의

# sentence + notes 조합 (sentence가 우선, notes는 무시될 수 있음)
x-fantastical3://parse?sentence=sentence&notes=[your note]
```

### 2. show — 날짜 이동

`x-fantastical3://show?date=[date]`

- 형식: `yyyy-mm-dd` 또는 자연어 ("Tuesday", "next month" 등)
- 예시: `x-fantastical3://show?date=2026-03-26`

## x-callback-url 지원

```
x-fantastical3://x-callback-url/parse?[parameters]
x-fantastical3://x-callback-url/show?[parameters]
```

지원 파라미터: `x-source`, `x-success`, `x-cancel`, `x-error`

## 설계 고려사항

### sentence vs 개별 파라미터
- **sentence 방식**: Fantastical의 NLP에 의존, 간단하지만 파싱 정확도 불확실
- **개별 파라미터 방식**: Gemini가 구조화된 JSON으로 추출 → 각 필드를 개별 파라미터로 전달 → 더 정확
- **권장**: 개별 파라미터 방식이 더 안정적 (Gemini 추출 결과를 직접 매핑)
