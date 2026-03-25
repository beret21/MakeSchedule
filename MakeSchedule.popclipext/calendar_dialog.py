#!/usr/bin/env python3
"""
MakeSchedule - 일정 등록 대화상자 (v4)
달력 선택기, 시간 스피너, 캘린더 드롭다운을 포함한 편집 UI.

입력: stdin (JSON 문자열)
출력: stdout (등록 결과 JSON 또는 "CANCELLED")
"""

import os
import sys
import json
import calendar
import subprocess
import tkinter as tk
from tkinter import ttk
from datetime import datetime

LAST_CAL_FILE = os.path.expanduser(
    "~/.makeschedule_last_calendar"
)


def load_last_calendar():
    try:
        with open(LAST_CAL_FILE, 'r') as f:
            return f.read().strip()
    except FileNotFoundError:
        return None


def save_last_calendar(name):
    with open(LAST_CAL_FILE, 'w') as f:
        f.write(name)


def get_calendars():
    script = '''
    tell application "Calendar"
        set calNames to {}
        repeat with c in calendars
            if writable of c then
                set end of calNames to (name of c)
            end if
        end repeat
        set AppleScript's text item delimiters to "|||"
        return calNames as text
    end tell
    '''
    try:
        r = subprocess.run(
            ["osascript", "-e", script],
            capture_output=True, text=True, timeout=10
        )
        if r.returncode == 0 and r.stdout.strip():
            return r.stdout.strip().split("|||")
    except Exception:
        pass
    return ["캘린더"]


def create_event(title, start_date, end_date,
                 location, notes, calendar_name,
                 all_day=False):
    def esc(s):
        return s.replace('\\', '\\\\').replace('"', '\\"')

    if all_day:
        s_as = start_date.strftime("%A, %B %d, %Y at 12:00:00 AM")
        e_as = end_date.strftime("%A, %B %d, %Y at 12:00:00 AM")
        props = (
            f'summary:"{esc(title)}", '
            f'start date:startDate, end date:endDate, '
            f'allday event:true, '
            f'location:"{esc(location)}", '
            f'description:"{esc(notes)}"'
        )
    else:
        s_as = start_date.strftime("%A, %B %d, %Y at %I:%M:%S %p")
        e_as = end_date.strftime("%A, %B %d, %Y at %I:%M:%S %p")
        props = (
            f'summary:"{esc(title)}", '
            f'start date:startDate, end date:endDate, '
            f'location:"{esc(location)}", '
            f'description:"{esc(notes)}"'
        )

    script = f'''
    set startDate to date "{s_as}"
    set endDate to date "{e_as}"
    tell application "Calendar"
        tell calendar "{esc(calendar_name)}"
            make new event at end with properties {{{props}}}
        end tell
    end tell
    return "OK"
    '''
    r = subprocess.run(
        ["osascript", "-e", script],
        capture_output=True, text=True, timeout=10
    )
    return r.returncode == 0


# ═══════════════════════════════════════════════════════════════
# 달력 위젯 (순수 tkinter)
# ═══════════════════════════════════════════════════════════════
class CalendarPopup:
    """날짜 선택 달력 팝업"""

    def __init__(self, parent, callback, initial_date=None):
        self.callback = callback
        self.top = tk.Toplevel(parent)
        self.top.overrideredirect(True)
        self.top.configure(bg="white", bd=1, relief=tk.SOLID)

        if initial_date:
            self.year = initial_date.year
            self.month = initial_date.month
            self.selected = initial_date
        else:
            now = datetime.now()
            self.year = now.year
            self.month = now.month
            self.selected = now

        self.today = datetime.now().date()
        self._build()

        # 팝업 외부 클릭 시 닫기
        self.top.bind("<FocusOut>", lambda e: self._close())
        self.top.focus_set()

    def _build(self):
        for w in self.top.winfo_children():
            w.destroy()

        # 헤더 (◀ 2026년 3월 ▶)
        hdr = tk.Frame(self.top, bg="white")
        hdr.pack(fill=tk.X, padx=5, pady=5)

        tk.Button(
            hdr, text="◀", command=self._prev_month,
            relief=tk.FLAT, bg="white", font=("", 12)
        ).pack(side=tk.LEFT)

        tk.Label(
            hdr, text=f"{self.year}년 {self.month}월",
            bg="white", font=("SF Pro Text", 13, "bold")
        ).pack(side=tk.LEFT, expand=True)

        tk.Button(
            hdr, text="▶", command=self._next_month,
            relief=tk.FLAT, bg="white", font=("", 12)
        ).pack(side=tk.RIGHT)

        # 요일 헤더
        days_frame = tk.Frame(self.top, bg="white")
        days_frame.pack(fill=tk.X, padx=5)
        for day in ["일", "월", "화", "수", "목", "금", "토"]:
            color = "#cc0000" if day == "일" else (
                "#0066cc" if day == "토" else "#333"
            )
            tk.Label(
                days_frame, text=day, width=4, bg="white",
                fg=color, font=("SF Pro Text", 11)
            ).pack(side=tk.LEFT)

        # 날짜 그리드
        grid = tk.Frame(self.top, bg="white")
        grid.pack(fill=tk.BOTH, padx=5, pady=(0, 5))

        cal = calendar.Calendar(firstweekday=6)  # 일요일 시작
        weeks = cal.monthdayscalendar(self.year, self.month)

        for week in weeks:
            row = tk.Frame(grid, bg="white")
            row.pack(fill=tk.X)
            for i, day in enumerate(week):
                if day == 0:
                    tk.Label(
                        row, text="", width=4, bg="white"
                    ).pack(side=tk.LEFT)
                else:
                    d = datetime(
                        self.year, self.month, day
                    ).date()
                    bg = "#007AFF" if d == self.selected.date() else (
                        "#E8F0FE" if d == self.today else "white"
                    )
                    fg = "white" if d == self.selected.date() else (
                        "#cc0000" if i == 0 else (
                            "#0066cc" if i == 6 else "#333"
                        )
                    )
                    btn = tk.Label(
                        row, text=str(day), width=4,
                        bg=bg, fg=fg,
                        font=("SF Pro Text", 11),
                        cursor="hand2"
                    )
                    btn.pack(side=tk.LEFT)
                    btn.bind(
                        "<Button-1>",
                        lambda e, d=day: self._select(d)
                    )

    def _prev_month(self):
        if self.month == 1:
            self.month = 12
            self.year -= 1
        else:
            self.month -= 1
        self._build()

    def _next_month(self):
        if self.month == 12:
            self.month = 1
            self.year += 1
        else:
            self.month += 1
        self._build()

    def _select(self, day):
        self.selected = datetime(self.year, self.month, day)
        self.callback(self.selected)
        self._close()

    def _close(self):
        self.top.destroy()

    def show_at(self, widget):
        x = widget.winfo_rootx()
        y = widget.winfo_rooty() + widget.winfo_height()
        self.top.geometry(f"+{x}+{y}")


# ═══════════════════════════════════════════════════════════════
# 시간 선택 위젯
# ═══════════════════════════════════════════════════════════════
class TimeSpinner(ttk.Frame):
    """시간 선택 스피너 (오전/오후 + HH:MM)"""

    def __init__(self, parent, initial_time="12:00"):
        super().__init__(parent)
        self._parse_initial(initial_time)

        # 시간 입력 필드
        self.time_var = tk.StringVar(
            value=self._format_display()
        )
        self.entry = ttk.Entry(
            self, textvariable=self.time_var,
            width=6, justify=tk.CENTER,
            font=("SF Pro Text", 13)
        )
        self.entry.pack(side=tk.LEFT)
        self.entry.bind("<FocusOut>", self._on_edit)
        self.entry.bind("<Return>", self._on_edit)

        # 오전/오후
        self.ampm_var = tk.StringVar(value=self.ampm)
        self.ampm_btn = ttk.Button(
            self, textvariable=self.ampm_var,
            width=4, command=self._toggle_ampm
        )
        self.ampm_btn.pack(side=tk.LEFT, padx=(3, 0))

        # 상하 버튼 프레임
        arrows = ttk.Frame(self)
        arrows.pack(side=tk.LEFT, padx=(3, 0))
        ttk.Button(
            arrows, text="▲", width=2,
            command=lambda: self._adjust(1)
        ).pack()
        ttk.Button(
            arrows, text="▼", width=2,
            command=lambda: self._adjust(-1)
        ).pack()

        self._valid = True

    def _parse_initial(self, time_str):
        try:
            h, m = map(int, time_str.split(":"))
        except (ValueError, AttributeError):
            h, m = 12, 0
        self.ampm = "오후" if h >= 12 else "오전"
        self.hour = h % 12 or 12
        self.minute = m

    def _format_display(self):
        return f"{self.hour:d}:{self.minute:02d}"

    def _format_24h(self):
        h = self.hour % 12
        if self.ampm == "오후":
            h += 12
        if h == 24:
            h = 12
        if self.ampm == "오전" and self.hour == 12:
            h = 0
        return f"{h:02d}:{self.minute:02d}"

    def get_time_24h(self):
        return self._format_24h()

    def _toggle_ampm(self):
        self.ampm = "오후" if self.ampm == "오전" else "오전"
        self.ampm_var.set(self.ampm)

    def _adjust(self, delta):
        """상하 화살표: 커서 위치에 따라 시간 또는 분 조정"""
        try:
            cursor = self.entry.index(tk.INSERT)
        except Exception:
            cursor = 0

        colon_pos = self.time_var.get().find(":")
        if cursor <= colon_pos:
            # 시간 조정
            self.hour += delta
            if self.hour > 12:
                self.hour = 1
            elif self.hour < 1:
                self.hour = 12
        else:
            # 분 조정
            self.minute += delta
            if self.minute > 59:
                self.minute = 0
            elif self.minute < 0:
                self.minute = 59

        self.time_var.set(self._format_display())
        self._set_valid(True)

    def _on_edit(self, event=None):
        """직접 입력 검증"""
        raw = self.time_var.get().strip()

        # HH:MM 또는 HHMM 형식 파싱
        try:
            if ":" in raw:
                parts = raw.split(":")
                h = int(parts[0])
                m = int(parts[1]) if len(parts) > 1 else 0
            elif len(raw) == 4 and raw.isdigit():
                h = int(raw[:2])
                m = int(raw[2:])
            elif len(raw) == 3 and raw.isdigit():
                h = int(raw[:1])
                m = int(raw[1:])
            elif raw.isdigit():
                h = int(raw)
                m = 0
            else:
                self._set_valid(False)
                return

            # 24시간제 입력 처리
            if h >= 0 and h <= 23 and m >= 0 and m <= 59:
                if h == 0:
                    self.ampm = "오전"
                    self.hour = 12
                elif h < 12:
                    self.ampm = "오전"
                    self.hour = h
                elif h == 12:
                    self.ampm = "오후"
                    self.hour = 12
                else:
                    self.ampm = "오후"
                    self.hour = h - 12
                self.minute = m
                self.ampm_var.set(self.ampm)
                self.time_var.set(self._format_display())
                self._set_valid(True)
            else:
                self._set_valid(False)
        except (ValueError, IndexError):
            self._set_valid(False)

    def _set_valid(self, valid):
        self._valid = valid
        if valid:
            self.entry.configure(foreground="black")
        else:
            self.entry.configure(foreground="red")

    def is_valid(self):
        return self._valid

    def set_enabled(self, enabled):
        state = "normal" if enabled else "disabled"
        self.entry.configure(state=state)
        self.ampm_btn.configure(state=state)
        for child in self.winfo_children():
            if isinstance(child, ttk.Frame):
                for btn in child.winfo_children():
                    btn.configure(state=state)


# ═══════════════════════════════════════════════════════════════
# 날짜 입력 필드 (달력 팝업 연동)
# ═══════════════════════════════════════════════════════════════
class DateEntry(ttk.Frame):
    def __init__(self, parent, initial_date=""):
        super().__init__(parent)

        self.date_var = tk.StringVar(value=initial_date)
        self.entry = ttk.Entry(
            self, textvariable=self.date_var,
            width=12, font=("SF Pro Text", 13)
        )
        self.entry.pack(side=tk.LEFT)

        self.cal_btn = ttk.Button(
            self, text="📅", width=3,
            command=self._show_calendar
        )
        self.cal_btn.pack(side=tk.LEFT, padx=(3, 0))

        self.popup = None

    def _show_calendar(self):
        if self.popup:
            return
        try:
            d = datetime.strptime(
                self.date_var.get().strip(), "%Y-%m-%d"
            )
        except ValueError:
            d = datetime.now()

        self.popup = CalendarPopup(
            self.winfo_toplevel(), self._on_select, d
        )
        self.popup.show_at(self.entry)

    def _on_select(self, dt):
        self.date_var.set(dt.strftime("%Y-%m-%d"))
        self.popup = None

    def get(self):
        return self.date_var.get().strip()

    def set_enabled(self, enabled):
        state = "normal" if enabled else "disabled"
        self.entry.configure(state=state)
        self.cal_btn.configure(state=state)


# ═══════════════════════════════════════════════════════════════
# 메인 대화상자
# ═══════════════════════════════════════════════════════════════
class ScheduleDialog:
    def __init__(self, data):
        self.result = None

        self.root = tk.Tk()
        self.root.title("MakeSchedule 일정 등록")
        self.root.resizable(False, False)
        self.root.configure(bg="#f0f0f0")

        style = ttk.Style()
        style.theme_use("aqua")

        self.root.withdraw()

        main = ttk.Frame(self.root, padding=20)
        main.pack(fill=tk.BOTH, expand=True)

        # 헤더
        ttk.Label(
            main, text="📅 일정 등록",
            font=("SF Pro Display", 16, "bold")
        ).pack(anchor=tk.W, pady=(0, 15))

        fields = ttk.Frame(main)
        fields.pack(fill=tk.X)

        row = 0

        # 제목
        self._label(fields, "제목", row)
        self.title_var = tk.StringVar(
            value=data.get("title", "")
        )
        ttk.Entry(
            fields, textvariable=self.title_var, width=40
        ).grid(row=row, column=1, sticky=tk.W, padx=5, pady=4)
        row += 1

        # 종일
        self._label(fields, "종일", row)
        self.allday_var = tk.BooleanVar(
            value=data.get("all_day", False)
        )
        ttk.Checkbutton(
            fields, variable=self.allday_var,
            command=self._toggle_allday
        ).grid(row=row, column=1, sticky=tk.W, padx=5, pady=4)
        row += 1

        # 시작
        self._label(fields, "시작", row)
        start_frame = ttk.Frame(fields)
        start_frame.grid(
            row=row, column=1, sticky=tk.W, padx=5, pady=4
        )
        self.start_date = DateEntry(
            start_frame, data.get("start_date", "")
        )
        self.start_date.pack(side=tk.LEFT)
        self.start_time = TimeSpinner(
            start_frame, data.get("start_time", "12:00")
        )
        self.start_time.pack(side=tk.LEFT, padx=(10, 0))
        row += 1

        # 종료
        self._label(fields, "종료", row)
        end_frame = ttk.Frame(fields)
        end_frame.grid(
            row=row, column=1, sticky=tk.W, padx=5, pady=4
        )
        end_date_val = data.get(
            "end_date", data.get("start_date", "")
        )
        self.end_date = DateEntry(end_frame, end_date_val)
        self.end_date.pack(side=tk.LEFT)
        self.end_time = TimeSpinner(
            end_frame, data.get("end_time", "13:00")
        )
        self.end_time.pack(side=tk.LEFT, padx=(10, 0))
        row += 1

        # 장소
        self._label(fields, "장소", row)
        self.location_var = tk.StringVar(
            value=data.get("location", "")
        )
        ttk.Entry(
            fields, textvariable=self.location_var, width=40
        ).grid(row=row, column=1, sticky=tk.W, padx=5, pady=4)
        row += 1

        # 메모
        self._label(fields, "메모", row)
        self.notes_text = tk.Text(
            fields, width=40, height=8,
            font=("SF Pro Text", 12),
            relief=tk.SOLID, borderwidth=1
        )
        self.notes_text.grid(
            row=row, column=1, sticky=tk.W, padx=5, pady=4
        )
        self.notes_text.insert("1.0", data.get("notes", ""))
        row += 1

        # 캘린더 드롭다운
        cal_frame = ttk.Frame(main)
        cal_frame.pack(fill=tk.X, pady=(15, 0))

        ttk.Label(
            cal_frame, text="캘린더:",
            font=("SF Pro Text", 13, "bold")
        ).pack(side=tk.LEFT)

        self.calendars = get_calendars()
        self.cal_var = tk.StringVar()

        last_cal = load_last_calendar()
        if last_cal and last_cal in self.calendars:
            self.cal_var.set(last_cal)
        elif self.calendars:
            self.cal_var.set(self.calendars[0])

        ttk.Combobox(
            cal_frame, textvariable=self.cal_var,
            values=self.calendars, state="readonly", width=25
        ).pack(side=tk.LEFT, padx=10)

        # 버튼
        btn_frame = ttk.Frame(main)
        btn_frame.pack(fill=tk.X, pady=(20, 0))

        ttk.Button(
            btn_frame, text="취소", command=self._cancel
        ).pack(side=tk.RIGHT, padx=5)
        ttk.Button(
            btn_frame, text="등록", command=self._register
        ).pack(side=tk.RIGHT, padx=5)

        # 종일 초기 상태
        if self.allday_var.get():
            self._toggle_allday()

        # 창 위치
        self.root.update_idletasks()
        w = self.root.winfo_reqwidth()
        h = self.root.winfo_reqheight()
        x = (self.root.winfo_screenwidth() - w) // 2
        y = (self.root.winfo_screenheight() - h) // 3
        self.root.geometry(f"+{x}+{y}")
        self.root.deiconify()
        self.root.lift()
        self.root.focus_force()

        self.root.bind("<Return>", lambda e: self._register())
        self.root.bind("<Escape>", lambda e: self._cancel())

    def _label(self, parent, text, row):
        ttk.Label(
            parent, text=text + ":",
            font=("SF Pro Text", 13, "bold"),
            width=6, anchor=tk.E
        ).grid(row=row, column=0, sticky=tk.E, padx=5, pady=4)

    def _toggle_allday(self):
        is_allday = self.allday_var.get()
        self.start_time.set_enabled(not is_allday)
        self.end_time.set_enabled(not is_allday)

    def _register(self):
        title = self.title_var.get().strip()
        s_date = self.start_date.get()
        e_date = self.end_date.get()
        is_allday = self.allday_var.get()
        location = self.location_var.get().strip()
        notes = self.notes_text.get("1.0", tk.END).strip()
        cal_name = self.cal_var.get()

        if not title or not s_date:
            return
        if not e_date:
            e_date = s_date

        try:
            if is_allday:
                start_dt = datetime.strptime(s_date, "%Y-%m-%d")
                end_dt = datetime.strptime(e_date, "%Y-%m-%d")
            else:
                s_time = self.start_time.get_time_24h()
                e_time = self.end_time.get_time_24h()
                if not self.start_time.is_valid() or \
                   not self.end_time.is_valid():
                    return
                start_dt = datetime.strptime(
                    f"{s_date} {s_time}", "%Y-%m-%d %H:%M"
                )
                end_dt = datetime.strptime(
                    f"{e_date} {e_time}", "%Y-%m-%d %H:%M"
                )
        except ValueError:
            return

        ok = create_event(
            title, start_dt, end_dt,
            location, notes, cal_name,
            all_day=is_allday
        )

        if ok:
            save_last_calendar(cal_name)
            self.result = json.dumps({
                "status": "OK", "calendar": cal_name
            }, ensure_ascii=False)
        else:
            self.result = json.dumps({
                "status": "ERROR",
                "message": "Calendar 등록 실패"
            }, ensure_ascii=False)

        self.root.destroy()

    def _cancel(self):
        self.result = "CANCELLED"
        self.root.destroy()

    def run(self):
        self.root.mainloop()
        return self.result


def main():
    json_str = sys.stdin.read().strip()
    if not json_str:
        print("CANCELLED")
        sys.exit(0)

    try:
        data = json.loads(json_str)
    except json.JSONDecodeError:
        print("CANCELLED")
        sys.exit(1)

    dialog = ScheduleDialog(data)
    result = dialog.run()
    print(result or "CANCELLED")


if __name__ == "__main__":
    main()
