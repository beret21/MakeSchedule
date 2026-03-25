# MakeSchedule 설치 가이드

## 1. Gemini API Key 발급

1. [Google AI Studio](https://aistudio.google.com/) 접속
2. **Get API Key** 클릭
3. API Key 복사 (무료 티어로 충분)

## 2. PopClip Extension 설치

1. `MakeSchedule.popclipext` 폴더를 Finder에서 더블클릭
2. PopClip 설치 확인 대화상자에서 **Install** 클릭

## 3. API Key 설정

1. PopClip 메뉴바 아이콘 → 설정
2. MakeSchedule 확장의 **Gemini API Key** 필드에 키 입력

## 4. 첫 실행

1. 아무 텍스트를 선택하고 MakeSchedule 아이콘 클릭
2. "첫 실행: google-generativeai 패키지를 설치합니다..." 알림 표시
3. "패키지 설치 완료! 다시 시도해주세요." 알림 확인
4. 다시 텍스트 선택 후 아이콘 클릭 → Fantastical이 열리면 정상

## 문제 해결

### Python을 찾을 수 없다는 오류
```bash
# Homebrew로 Python 설치
brew install python@3.11
```

### 패키지 설치 실패
```bash
# 수동 설치
pip3 install google-generativeai

# 설치 상태 초기화 후 재시도
rm ~/.makeschedule_setup_done
```

### Fantastical을 열 수 없다는 오류
Fantastical 앱이 설치되어 있는지 확인하세요.

### 로그 확인
```bash
tail -f /tmp/makeschedule.log
```
