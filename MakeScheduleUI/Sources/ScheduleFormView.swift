import SwiftUI
import EventKit

struct ScheduleFormView: View {
    let input: EventInput

    @StateObject private var calendarManager = CalendarManager()

    @State private var title: String = ""
    @State private var isAllDay: Bool = false
    @State private var startDate: Date = Date()
    @State private var endDate: Date = Date().addingTimeInterval(3600)
    @State private var location: String = ""
    @State private var notes: String = ""
    @State private var selectedCalendarID: String = ""
    @State private var showError: Bool = false
    @State private var errorText: String = ""

    // 시간 직접 입력용
    @State private var startTimeText: String = "19:00"
    @State private var endTimeText: String = "20:00"
    @State private var startTimeValid: Bool = true
    @State private var endTimeValid: Bool = true

    // Fantastical-inspired accent
    private let accentOrange = Color(red: 0.95, green: 0.45, blue: 0.25)

    var body: some View {
        ZStack {
            // Subtle warm gradient background
            LinearGradient(
                colors: [
                    Color(nsColor: .windowBackgroundColor),
                    Color(nsColor: .windowBackgroundColor).opacity(0.95)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // MARK: - Header
                headerView
                    .padding(.top, 20)
                    .padding(.bottom, 14)

                if calendarManager.authorizationChecked && !calendarManager.accessGranted {
                    // 권한 거부 시 전체 화면 단계별 안내
                    Spacer()
                    permissionDeniedView
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: handleCancel) {
                            Text("닫기")
                                .frame(width: 72)
                        }
                        .keyboardShortcut(.cancelAction)
                        .controlSize(.large)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 16)
                } else {
                    // MARK: - Content Card
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: 0) {
                            // Title section
                            titleSection

                            sectionDivider

                            // Date & Time section
                            dateTimeSection

                            sectionDivider

                            // Details section
                            detailsSection

                            sectionDivider

                            // Calendar section
                            calendarSection
                        }
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(nsColor: .controlBackgroundColor))
                                .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 2)
                        )
                        .padding(.horizontal, 20)
                        .padding(.vertical, 4)
                    }

                    Spacer(minLength: 8)

                    // MARK: - Footer buttons
                    footerButtons
                        .padding(.bottom, 16)
                }
            }
        }
        .frame(width: 520, height: 620)
        .onAppear {
            populateFromInput()
            calendarManager.requestAccess()
        }
        .onChange(of: calendarManager.calendars) { cals in
            selectDefaultCalendar(from: cals)
        }
        .alert("오류", isPresented: $showError) {
            Button("확인") {}
        } message: {
            Text(errorText)
        }
    }

    // MARK: - Permission Denied View

    private var permissionDeniedView: some View {
        VStack(spacing: 20) {
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.system(size: 44))
                .foregroundColor(.secondary)

            Text("캘린더 접근 권한이 필요합니다")
                .font(.title3.weight(.semibold))

            VStack(alignment: .leading, spacing: 16) {
                // Step 1
                HStack(alignment: .top, spacing: 10) {
                    Text("1.")
                        .font(.callout.weight(.bold))
                        .foregroundColor(accentOrange)
                        .frame(width: 20, alignment: .trailing)
                    VStack(alignment: .leading, spacing: 8) {
                        Text("아래 버튼으로 시스템 설정을 열고,\nPopClip에 **'전체 캘린더 접근'** 권한을\n허용해 주세요.")
                            .font(.callout)
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)

                        Button(action: {
                            calendarManager.openSystemSettings()
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "gear")
                                Text("시스템 설정 열기")
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(accentOrange)
                        .controlSize(.regular)
                    }
                }

                // Step 2
                HStack(alignment: .top, spacing: 10) {
                    Text("2.")
                        .font(.callout.weight(.bold))
                        .foregroundColor(accentOrange)
                        .frame(width: 20, alignment: .trailing)
                    Text("권한 설정 후 PopClip이 자동으로\n재실행됩니다.")
                        .font(.callout)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                // Step 3
                HStack(alignment: .top, spacing: 10) {
                    Text("3.")
                        .font(.callout.weight(.bold))
                        .foregroundColor(accentOrange)
                        .frame(width: 20, alignment: .trailing)
                    Text("이 창을 닫고, 텍스트를 다시 선택하여\nMakeSchedule을 실행해 주세요.")
                        .font(.callout)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.horizontal, 8)
        }
        .padding(.horizontal, 40)
    }

    // MARK: - Header

    private var headerView: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(accentOrange.opacity(0.15))
                    .frame(width: 36, height: 36)
                Image(systemName: "calendar.badge.plus")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(accentOrange)
            }
            Text("일정 등록")
                .font(.title2.weight(.bold))
                .foregroundColor(.primary)
        }
    }

    // MARK: - Title Section

    private var titleSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            sectionLabel("제목", icon: "pencil")
            TextField("일정 제목을 입력하세요", text: $title)
                .textFieldStyle(.plain)
                .font(.title3.weight(.medium))
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(nsColor: .textBackgroundColor))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(
                            title.isEmpty ? Color.secondary.opacity(0.2) : accentOrange.opacity(0.5),
                            lineWidth: 1
                        )
                )
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    // MARK: - Date & Time Section

    private let fieldLabelWidth: CGFloat = 40

    private var dateTimeSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            // All-day toggle
            HStack {
                sectionLabel("종일", icon: "sun.max")
                Spacer()
                Toggle("", isOn: $isAllDay.animation(.easeInOut(duration: 0.25)))
                    .toggleStyle(.switch)
                    .labelsHidden()
                    .tint(accentOrange)
                    .onChange(of: isAllDay) { _ in
                        syncTimeFields()
                    }
            }

            // Start — 한 줄: 라벨 + 날짜 + 시간
            HStack(spacing: 8) {
                Text("시작")
                    .font(.callout.weight(.medium))
                    .foregroundColor(.secondary)
                    .frame(width: fieldLabelWidth, alignment: .trailing)

                DatePicker("", selection: $startDate,
                           displayedComponents: .date)
                    .labelsHidden()
                    .datePickerStyle(.stepperField)

                if !isAllDay {
                    timeField(
                        text: $startTimeText,
                        isValid: $startTimeValid,
                        date: $startDate,
                        base: startDate
                    )
                    .transition(.opacity.combined(with: .move(edge: .trailing)))
                }

                Spacer()
            }

            // End — 한 줄: 라벨 + 날짜 + 시간
            HStack(spacing: 8) {
                Text("종료")
                    .font(.callout.weight(.medium))
                    .foregroundColor(.secondary)
                    .frame(width: fieldLabelWidth, alignment: .trailing)

                DatePicker("", selection: $endDate,
                           displayedComponents: .date)
                    .labelsHidden()
                    .datePickerStyle(.stepperField)

                if !isAllDay {
                    timeField(
                        text: $endTimeText,
                        isValid: $endTimeValid,
                        date: $endDate,
                        base: endDate
                    )
                    .transition(.opacity.combined(with: .move(edge: .trailing)))
                }

                Spacer()
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: - Time Field Helper

    private func timeField(
        text: Binding<String>,
        isValid: Binding<Bool>,
        date: Binding<Date>,
        base: Date
    ) -> some View {
        HStack(spacing: 4) {
            Image(systemName: "clock")
                .font(.caption)
                .foregroundColor(isValid.wrappedValue ? .secondary : .red)

            TextField("HH:MM", text: text)
                .textFieldStyle(.plain)
                .font(.system(.body, design: .monospaced).weight(.medium))
                .frame(width: 56)
                .multilineTextAlignment(.center)
                .onChange(of: text.wrappedValue) { val in
                    isValid.wrappedValue = validateAndApplyTime(
                        val, to: &date.wrappedValue, base: base)
                }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color(nsColor: .textBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(
                    isValid.wrappedValue ? Color.secondary.opacity(0.25) : Color.red.opacity(0.6),
                    lineWidth: 1
                )
        )
    }

    // MARK: - Details Section

    private var detailsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Location
            VStack(alignment: .leading, spacing: 6) {
                sectionLabel("장소", icon: "mappin.and.ellipse")
                TextField("장소를 입력하세요", text: $location)
                    .textFieldStyle(.plain)
                    .font(.callout)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(nsColor: .textBackgroundColor))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                    )
            }

            // Notes
            VStack(alignment: .leading, spacing: 6) {
                sectionLabel("메모", icon: "note.text")
                TextEditor(text: $notes)
                    .font(.callout)
                    .scrollContentBackground(.hidden)
                    .padding(8)
                    .frame(minHeight: 80, maxHeight: 120)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(nsColor: .textBackgroundColor))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                    )
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    // MARK: - Calendar Section

    private var calendarSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                sectionLabel("캘린더", icon: "calendar")

                if !calendarManager.authorizationChecked {
                    // 아직 권한 확인 중
                    ProgressView()
                        .controlSize(.small)
                    Text("로딩 중...")
                        .foregroundColor(.secondary)
                        .font(.callout)
                } else if !calendarManager.accessGranted {
                    // 권한 거부됨
                    Text("접근 권한 없음")
                        .foregroundColor(.red)
                        .font(.callout)
                } else if calendarManager.calendars.isEmpty {
                    // 권한은 있지만 쓰기 가능한 캘린더 없음
                    Text("사용 가능한 캘린더가 없습니다")
                        .foregroundColor(.secondary)
                        .font(.callout)
                } else {
                    Picker("", selection: $selectedCalendarID) {
                        ForEach(calendarManager.calendars,
                                id: \.calendarIdentifier) { cal in
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(Color(cgColor: cal.cgColor))
                                    .frame(width: 10, height: 10)
                                Text(cal.title)
                            }
                            .tag(cal.calendarIdentifier)
                        }
                    }
                    .labelsHidden()
                    .frame(maxWidth: 220)
                }

                Spacer()
            }

            // 권한 거부 시 안내 메시지
            if calendarManager.authorizationChecked && !calendarManager.accessGranted {
                VStack(alignment: .leading, spacing: 6) {
                    Text("시스템 설정 > 개인정보 보호 및 보안 > 캘린더에서\nPopClip에 접근 권한을 허용해 주세요.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)

                    Button(action: {
                        calendarManager.openSystemSettings()
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "gear")
                                .font(.caption)
                            Text("시스템 설정 열기")
                                .font(.caption)
                        }
                    }
                    .buttonStyle(.link)
                }
                .padding(.leading, 28)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: - Footer Buttons

    private var footerButtons: some View {
        HStack(spacing: 12) {
            Spacer()

            Button(action: handleCancel) {
                Text("취소")
                    .frame(width: 72)
            }
            .keyboardShortcut(.cancelAction)
            .controlSize(.large)

            Button(action: handleRegister) {
                Text("등록")
                    .frame(width: 72)
            }
            .keyboardShortcut(.defaultAction)
            .buttonStyle(.borderedProminent)
            .tint(accentOrange)
            .controlSize(.large)
            .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty || calendarManager.calendars.isEmpty)
        }
        .padding(.horizontal, 24)
    }

    // MARK: - Helpers

    private func sectionLabel(_ text: String, icon: String) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(accentOrange)
            Text(text)
                .font(.callout.weight(.semibold))
                .foregroundColor(.primary)
        }
    }

    private var sectionDivider: some View {
        Divider()
            .padding(.horizontal, 16)
    }

    // MARK: - Time validation

    private func validateAndApplyTime(
        _ text: String, to date: inout Date, base: Date
    ) -> Bool {
        let raw = text.trimmingCharacters(in: .whitespaces)
        var h: Int = 0
        var m: Int = 0

        if raw.contains(":") {
            let parts = raw.split(separator: ":")
            guard parts.count == 2,
                  let hh = Int(parts[0]),
                  let mm = Int(parts[1]) else { return false }
            h = hh; m = mm
        } else if raw.count == 4, let val = Int(raw) {
            h = val / 100; m = val % 100
        } else if raw.count == 3, let val = Int(raw) {
            h = val / 100; m = val % 100
        } else {
            return false
        }

        guard h >= 0, h <= 23, m >= 0, m <= 59 else { return false }

        let cal = Calendar.current
        var comps = cal.dateComponents(
            [.year, .month, .day], from: base)
        comps.hour = h
        comps.minute = m
        comps.second = 0
        if let newDate = cal.date(from: comps) {
            date = newDate
            return true
        }
        return false
    }

    private func syncTimeFields() {
        let cal = Calendar.current
        let sh = cal.component(.hour, from: startDate)
        let sm = cal.component(.minute, from: startDate)
        startTimeText = String(format: "%02d:%02d", sh, sm)
        let eh = cal.component(.hour, from: endDate)
        let em = cal.component(.minute, from: endDate)
        endTimeText = String(format: "%02d:%02d", eh, em)
    }

    // MARK: - Populate

    private func populateFromInput() {
        title = input.title ?? ""
        isAllDay = input.all_day ?? false
        location = input.location ?? ""
        notes = input.notes ?? ""

        if let sd = input.start_date,
           let d = parseDate(sd, isAllDay ? nil : input.start_time) {
            startDate = d
        }
        if let ed = input.end_date,
           let d = parseDate(ed, isAllDay ? nil : input.end_time) {
            endDate = d
        }
        if endDate <= startDate {
            endDate = startDate.addingTimeInterval(3600)
        }

        syncTimeFields()
    }

    // MARK: - Default calendar

    private func selectDefaultCalendar(from cals: [EKCalendar]) {
        guard !cals.isEmpty else { return }

        if let lastName = CalendarManager.loadLastCalendarName(),
           let match = cals.first(where: { $0.title == lastName }) {
            selectedCalendarID = match.calendarIdentifier
            return
        }

        if let def = calendarManager.store.defaultCalendarForNewEvents,
           cals.contains(where: {
               $0.calendarIdentifier == def.calendarIdentifier
           }) {
            selectedCalendarID = def.calendarIdentifier
            return
        }

        selectedCalendarID = cals.first?.calendarIdentifier ?? ""
    }

    // MARK: - Actions

    private func handleRegister() {
        // 시간 텍스트 최종 적용
        if !isAllDay {
            startTimeValid = validateAndApplyTime(
                startTimeText, to: &startDate, base: startDate)
            endTimeValid = validateAndApplyTime(
                endTimeText, to: &endDate, base: endDate)
            guard startTimeValid, endTimeValid else {
                errorText = "시간 형식이 올바르지 않습니다. (HH:MM)"
                showError = true
                return
            }
        }

        guard let calendar = calendarManager.calendars.first(where: {
            $0.calendarIdentifier == selectedCalendarID
        }) else {
            errorText = "캘린더를 선택해 주세요."
            showError = true
            return
        }

        do {
            try calendarManager.createEvent(
                title: title.trimmingCharacters(in: .whitespaces),
                startDate: startDate,
                endDate: endDate,
                isAllDay: isAllDay,
                location: location,
                notes: notes,
                calendar: calendar
            )

            CalendarManager.saveLastCalendarName(calendar.title)

            let result: [String: String] = [
                "status": "OK",
                "calendar": calendar.title
            ]
            if let jsonData = try? JSONSerialization.data(
                withJSONObject: result),
               let jsonStr = String(data: jsonData, encoding: .utf8) {
                print(jsonStr)
            }

            NSApplication.shared.terminate(nil)
        } catch {
            errorText = "일정 등록 실패: \(error.localizedDescription)"
            showError = true
        }
    }

    private func handleCancel() {
        print("CANCELLED")
        NSApplication.shared.terminate(nil)
    }
}
