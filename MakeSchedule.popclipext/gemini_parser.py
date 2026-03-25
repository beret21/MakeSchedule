#!/usr/bin/env python3
"""
MakeSchedule - Gemini 일정 추출기
선택한 텍스트에서 Gemini를 사용하여 일정 정보를 JSON으로 추출합니다.

입력: stdin (클립보드 텍스트)
출력: stdout (JSON 문자열 1줄)
에러: stderr + 적절한 exit code
"""

import sys
import json
import argparse
import datetime


def get_system_prompt():
    """동적 연도를 포함한 시스템 프롬프트 생성"""
    current_year = datetime.datetime.now().year
    return f"""입력된 텍스트에서 일정 정보를 추출하여 JSON으로 출력해.

규칙:
- 현재 연도는 {current_year}년. 텍스트에 연도가 있으면 그것을 사용.
- 날짜: YYYY-MM-DD
- 시간: 24시간제 HH:MM (저녁 7시→19:00, 오후 3시→15:00)
- 종료 시간 없으면 시작 +1시간
- 여러 날 일정이면 start_date와 end_date가 다름
- 시간 정보가 없는 여러 날 일정이면 all_day를 true로
- 제목은 한국어 유지

JSON 필드:
- "title": 일정 제목
- "start_date": 시작 날짜 YYYY-MM-DD
- "start_time": 시작 시간 HH:MM (종일이면 빈 문자열)
- "end_date": 종료 날짜 YYYY-MM-DD (같은 날이면 start_date와 동일)
- "end_time": 종료 시간 HH:MM (종일이면 빈 문자열)
- "all_day": true/false (종일 일정 여부)
- "location": 장소명
- "notes": 캘린더 메모 부가정보. 줄바꿈으로 구분:
  강의/세션 내용, 주소, 지도/홈페이지/채팅방 링크, 참고 사항. 빈 항목 생략.

예시 1 (시간 지정 일정):
{{"title": "AI Study 110 - 5차 모임", "start_date": "2026-03-26", "start_time": "19:00", "end_date": "2026-03-26", "end_time": "20:00", "all_day": false, "location": "서울AI허브 희경빌딩 C동 지하강의실", "notes": "[ 강의 내용 ]\\n- 김인태: AI 기초강의\\n\\n주소: 서초구 매헌로8길 47\\n지도: https://naver.me/GSUAn4rd"}}

예시 2 (여러 날 종일 일정):
{{"title": "제주 워크숍", "start_date": "2026-04-10", "start_time": "", "end_date": "2026-04-12", "end_time": "", "all_day": true, "location": "제주 컨벤션센터", "notes": "숙소: OO호텔\\n준비물: 노트북"}}

텍스트에서 일정 정보를 찾을 수 없으면 다음 JSON을 출력:
{{"error": "일정 정보를 찾을 수 없습니다."}}

유효한 JSON만 출력. 마크다운 코드블록이나 설명 없이."""


def extract_schedule(api_key, text):
    """Gemini API를 호출하여 일정 정보를 JSON으로 추출"""
    from google import genai

    client = genai.Client(api_key=api_key)

    prompt = f"""{get_system_prompt()}

텍스트:
{text}"""

    response = client.models.generate_content(
        model="gemini-2.0-flash",
        contents=prompt
    )
    result = response.text.strip()

    # 마크다운 코드블록 제거
    if result.startswith("```"):
        lines = result.split('\n')
        if lines[-1].startswith("```"):
            result = '\n'.join(lines[1:-1])
        else:
            result = '\n'.join(lines[1:])

    data = json.loads(result)

    # Gemini가 일정을 찾지 못한 경우
    if data.get("error"):
        print(
            f"ERROR: {data['error']}",
            file=sys.stderr
        )
        sys.exit(5)

    # 필수 필드 확인
    if not data.get("title") or not data.get("start_date"):
        return None

    return data


def main():
    parser = argparse.ArgumentParser(
        description='Gemini 일정 추출기'
    )
    parser.add_argument(
        '--api-key', required=True, help='Gemini API Key'
    )
    args = parser.parse_args()

    text = sys.stdin.read().strip()
    if not text:
        print(
            "ERROR: 입력 텍스트가 비어있습니다.",
            file=sys.stderr
        )
        sys.exit(1)

    try:
        data = extract_schedule(args.api_key, text)
        if not data:
            print(
                "ERROR: 일정 정보를 추출할 수 없습니다.",
                file=sys.stderr
            )
            sys.exit(1)

        # JSON 1줄로 stdout 출력
        print(json.dumps(data, ensure_ascii=False))

    except json.JSONDecodeError as e:
        print(
            f"ERROR: Gemini 응답 JSON 파싱 실패 - {e}",
            file=sys.stderr
        )
        sys.exit(1)
    except Exception as e:
        error_msg = str(e).lower()
        if any(k in error_msg for k in
               ["api_key", "permission", "403"]):
            print(
                f"ERROR: API 키 인증 실패 - {e}",
                file=sys.stderr
            )
            sys.exit(2)
        elif any(k in error_msg for k in
                 ["429", "resource", "quota"]):
            print(
                f"ERROR: API 요청 한도 초과 - {e}",
                file=sys.stderr
            )
            sys.exit(3)
        elif any(k in error_msg for k in
                 ["connection", "timeout", "network"]):
            print(
                f"ERROR: 네트워크 오류 - {e}",
                file=sys.stderr
            )
            sys.exit(4)
        else:
            print(f"ERROR: {e}", file=sys.stderr)
            sys.exit(1)


if __name__ == "__main__":
    main()
