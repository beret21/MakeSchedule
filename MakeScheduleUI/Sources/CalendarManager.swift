import EventKit
import AppKit

class CalendarManager: ObservableObject {
    let store = EKEventStore()
    @Published var calendars: [EKCalendar] = []
    @Published var accessGranted = false
    @Published var authorizationChecked = false
    @Published var errorMessage: String?

    func requestAccess() {
        if #available(macOS 14.0, *) {
            store.requestFullAccessToEvents { granted, error in
                DispatchQueue.main.async {
                    self.accessGranted = granted
                    self.authorizationChecked = true
                    if granted {
                        self.loadCalendars()
                    } else {
                        self.errorMessage = error?.localizedDescription
                            ?? "캘린더 접근 권한이 거부되었습니다."
                    }
                }
            }
        } else {
            store.requestAccess(to: .event) { granted, error in
                DispatchQueue.main.async {
                    self.accessGranted = granted
                    self.authorizationChecked = true
                    if granted {
                        self.loadCalendars()
                    } else {
                        self.errorMessage = error?.localizedDescription
                            ?? "캘린더 접근 권한이 거부되었습니다."
                    }
                }
            }
        }
    }

    func openSystemSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Calendars") {
            NSWorkspace.shared.open(url)
        }
    }

    private func loadCalendars() {
        let allCalendars = store.calendars(for: .event)
        calendars = allCalendars.filter { $0.allowsContentModifications }
            .sorted { $0.title.localizedCompare($1.title) == .orderedAscending }
    }

    func createEvent(
        title: String,
        startDate: Date,
        endDate: Date,
        isAllDay: Bool,
        location: String,
        notes: String,
        calendar: EKCalendar
    ) throws {
        let event = EKEvent(eventStore: store)
        event.title = title
        event.startDate = startDate
        event.endDate = endDate
        event.isAllDay = isAllDay
        event.location = location.isEmpty ? nil : location
        event.notes = notes.isEmpty ? nil : notes
        event.calendar = calendar
        try store.save(event, span: .thisEvent)
    }

    // MARK: - Last calendar persistence

    static let lastCalendarFile = NSString("~/.makeschedule_last_calendar").expandingTildeInPath

    static func loadLastCalendarName() -> String? {
        guard let data = FileManager.default.contents(atPath: lastCalendarFile),
              let name = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines),
              !name.isEmpty
        else { return nil }
        return name
    }

    static func saveLastCalendarName(_ name: String) {
        try? name.write(toFile: lastCalendarFile, atomically: true, encoding: .utf8)
    }
}
