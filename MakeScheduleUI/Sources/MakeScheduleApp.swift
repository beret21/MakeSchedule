import SwiftUI

// Read stdin before the app launches (must happen synchronously before GUI)
let stdinInput: EventInput = {
    // Check if stdin is a pipe/file (not a terminal)
    if isatty(fileno(stdin)) == 0 {
        return readStdinInput()
    }
    return EventInput(
        title: nil, start_date: nil, start_time: nil,
        end_date: nil, end_time: nil, all_day: nil,
        location: nil, notes: nil
    )
}()

@main
struct MakeScheduleApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            ScheduleFormView(input: stdinInput)
        }
        .windowStyle(.titleBar)
        .windowResizability(.contentSize)
        .defaultPosition(.center)
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // 팝업을 최전면으로 가져오기
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)

        if let window = NSApplication.shared.windows.first {
            window.title = "MakeSchedule 일정 등록"
            window.styleMask.remove(.resizable)
            window.center()
            window.level = .floating
            window.makeKeyAndOrderFront(nil)
            // floating 후 normal로 복귀 (다른 앱 위에 항상 떠있지 않도록)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                window.level = .normal
            }
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}
