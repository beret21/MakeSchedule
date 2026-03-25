#!/bin/bash
# ═══════════════════════════════════════════════════════════════
# MakeSchedule 설치 스크립트
# Dropbox로 공유된 프로젝트 폴더에서 실행
# ═══════════════════════════════════════════════════════════════

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
EXT_DIR="$SCRIPT_DIR/MakeSchedule.popclipext"
UI_DIR="$SCRIPT_DIR/MakeScheduleUI"
BINARY="$EXT_DIR/MakeScheduleUI"

echo "📅 MakeSchedule 설치를 시작합니다."
echo ""

# 1. Swift 빌드 (바이너리가 없거나 소스가 더 새로운 경우)
NEED_BUILD=false
if [ ! -f "$BINARY" ]; then
    NEED_BUILD=true
elif [ "$(find "$UI_DIR/Sources" -name '*.swift' -newer "$BINARY" 2>/dev/null)" ]; then
    NEED_BUILD=true
fi

if [ "$NEED_BUILD" = true ]; then
    echo "🔨 SwiftUI 앱 빌드 중..."
    cd "$UI_DIR"
    swift build -c release 2>&1 | tail -1
    cp .build/release/MakeScheduleUI "$BINARY"
    echo "✅ 빌드 완료"
else
    echo "✅ 바이너리 최신 상태 (빌드 불필요)"
fi

# 2. Python 의존성 확인
echo ""
PYTHON_PATH="/opt/anaconda3/bin/python3"
[ ! -f "$PYTHON_PATH" ] && PYTHON_PATH="/opt/homebrew/bin/python3"
[ ! -f "$PYTHON_PATH" ] && PYTHON_PATH="/usr/local/bin/python3"
[ ! -f "$PYTHON_PATH" ] && PYTHON_PATH=$(which python3 2>/dev/null)

if [ -z "$PYTHON_PATH" ] || [ ! -f "$PYTHON_PATH" ]; then
    echo "⚠️  Python3를 찾을 수 없습니다. 설치 후 다시 실행하세요."
    echo "   brew install python@3.11"
    exit 1
fi

if $PYTHON_PATH -c "from google import genai" 2>/dev/null; then
    echo "✅ google-genai 패키지 설치됨"
else
    echo "📦 google-genai 패키지 설치 중..."
    $PYTHON_PATH -m pip install google-genai --quiet
    echo "✅ 패키지 설치 완료"
fi

# 3. PopClip Extension 설치
echo ""
echo "📎 PopClip Extension 설치..."
open "$EXT_DIR"
echo ""
echo "═══════════════════════════════════════════════"
echo "  PopClip 대화상자에서 Install을 클릭하세요."
echo "  설치 후 PopClip 설정에서 Gemini API Key를 입력하세요."
echo "  API Key: https://aistudio.google.com/"
echo "═══════════════════════════════════════════════"
