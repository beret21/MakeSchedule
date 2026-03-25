#!/bin/bash
# ═══════════════════════════════════════════════════════════════
# MakeSchedule - PopClip Extension Shell Wrapper (v2)
# ═══════════════════════════════════════════════════════════════
# 설명: 선택한 텍스트에서 Gemini로 일정을 추출하여 Calendar.app에 등록
#
# 워크플로우:
#   pbpaste → Gemini API (JSON 추출) → 검수 대화상자 → Calendar.app 등록
# ═══════════════════════════════════════════════════════════════

LOG_FILE="/tmp/makeschedule_$(date +%Y).log"
echo "==============================" >> "$LOG_FILE"
echo "$(date): PopClip Script Started" >> "$LOG_FILE"

export PATH="/opt/homebrew/bin:/usr/local/bin:/opt/anaconda3/bin:$PATH"

notify() {
    osascript -e "display notification \"$2\" with title \"$1\""
}

# ═══════════════════════════════════════════════════════════════
# API 키 확인
# ═══════════════════════════════════════════════════════════════
if [ -z "$POPCLIP_OPTION_GEMINIAPIKEY" ]; then
    exit 2
fi

# ═══════════════════════════════════════════════════════════════
# Python 경로 찾기
# ═══════════════════════════════════════════════════════════════
PYTHON_PATH="/opt/anaconda3/bin/python3"
[ ! -f "$PYTHON_PATH" ] && PYTHON_PATH="/opt/homebrew/bin/python3"
[ ! -f "$PYTHON_PATH" ] && PYTHON_PATH="/usr/local/bin/python3"
[ ! -f "$PYTHON_PATH" ] && PYTHON_PATH=$(which python3 2>/dev/null)

if [ -z "$PYTHON_PATH" ] || [ ! -f "$PYTHON_PATH" ]; then
    notify "MakeSchedule 오류" "Python3를 찾을 수 없습니다."
    exit 1
fi

PIP_DIR="$(dirname "$PYTHON_PATH")"
if [ -f "$PIP_DIR/pip3" ]; then PIP_CMD="$PIP_DIR/pip3"
elif [ -f "$PIP_DIR/pip" ]; then PIP_CMD="$PIP_DIR/pip"
else PIP_CMD="$PYTHON_PATH -m pip"; fi

echo "$(date): Python: $PYTHON_PATH" >> "$LOG_FILE"

# ═══════════════════════════════════════════════════════════════
# 첫 실행 시 패키지 설치
# ═══════════════════════════════════════════════════════════════
SETUP_MARKER="$HOME/.makeschedule_setup_done_v2"
if [ ! -f "$SETUP_MARKER" ]; then
    if ! $PYTHON_PATH -c "from google import genai" 2>/dev/null; then
        notify "MakeSchedule" "첫 실행: google-genai 설치 중..."
        $PIP_CMD install google-genai --quiet 2>&1 >> "$LOG_FILE"
        if $PYTHON_PATH -c "from google import genai" 2>/dev/null; then
            touch "$SETUP_MARKER"
            notify "MakeSchedule" "설치 완료! 다시 시도해주세요."
            exit 0
        fi
        notify "MakeSchedule 오류" "패키지 설치 실패"
        exit 1
    else
        touch "$SETUP_MARKER"
    fi
fi

# ═══════════════════════════════════════════════════════════════
# 선택 텍스트 확인 (PopClip이 $POPCLIP_TEXT로 전달)
# ═══════════════════════════════════════════════════════════════
if [ -z "$POPCLIP_TEXT" ]; then
    notify "MakeSchedule 오류" "선택된 텍스트가 없습니다."
    exit 1
fi

# ═══════════════════════════════════════════════════════════════
# Gemini API 호출
# ═══════════════════════════════════════════════════════════════
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "$(date): Calling Gemini API (${#POPCLIP_TEXT} chars)..." >> "$LOG_FILE"
JSON_RESULT=$(echo "$POPCLIP_TEXT" | "$PYTHON_PATH" "$SCRIPT_DIR/gemini_parser.py" --api-key "$POPCLIP_OPTION_GEMINIAPIKEY" 2>> "$LOG_FILE")
EXIT_CODE=$?

echo "$(date): Gemini exit=$EXIT_CODE" >> "$LOG_FILE"
echo "$(date): JSON: $JSON_RESULT" >> "$LOG_FILE"

if [ $EXIT_CODE -ne 0 ] || [ -z "$JSON_RESULT" ]; then
    case $EXIT_CODE in
        2) notify "MakeSchedule 오류" "API 키를 확인해주세요." ;;
        3) notify "MakeSchedule 오류" "API 한도 초과." ;;
        4) notify "MakeSchedule 오류" "네트워크 오류." ;;
        *) notify "MakeSchedule 오류" "일정 추출 실패." ;;
    esac
    exit 1
fi

# ═══════════════════════════════════════════════════════════════
# SwiftUI 대화상자로 검수/편집 + EventKit 캘린더 등록
# ═══════════════════════════════════════════════════════════════
UI_PATH="$SCRIPT_DIR/MakeScheduleUI"

echo "$(date): Opening SwiftUI dialog..." >> "$LOG_FILE"
DIALOG_RESULT=$(echo "$JSON_RESULT" | "$UI_PATH" 2>> "$LOG_FILE")
DIALOG_EXIT=$?

echo "$(date): Dialog result=[$DIALOG_RESULT] exit=$DIALOG_EXIT" >> "$LOG_FILE"

if [ "$DIALOG_RESULT" = "CANCELLED" ] || [ -z "$DIALOG_RESULT" ]; then
    echo "$(date): User cancelled" >> "$LOG_FILE"
    exit 0
fi

# 결과 JSON에서 상태 확인
STATUS=$(echo "$DIALOG_RESULT" | "$PYTHON_PATH" -c "import json,sys; print(json.load(sys.stdin).get('status',''))" 2>/dev/null)

if [ "$STATUS" = "OK" ]; then
    CAL_NAME=$(echo "$DIALOG_RESULT" | "$PYTHON_PATH" -c "import json,sys; print(json.load(sys.stdin).get('calendar',''))" 2>/dev/null)
    notify "MakeSchedule" "[$CAL_NAME] 캘린더에 등록 완료!"
    echo "$(date): Registered to [$CAL_NAME]" >> "$LOG_FILE"
    exit 0
else
    notify "MakeSchedule 오류" "캘린더 등록 실패."
    echo "$(date): ERROR - Registration failed" >> "$LOG_FILE"
    exit 1
fi
