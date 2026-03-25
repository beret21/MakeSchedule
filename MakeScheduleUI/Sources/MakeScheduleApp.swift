import SwiftUI
import EventKit

// --request-permission 모드: 권한만 요청하고 종료
let isPermissionMode = CommandLine.arguments.contains("--request-permission")

// Read stdin before the app launches (must happen synchronously before GUI)
let stdinInput: EventInput = {
    if isPermissionMode { return EventInput(title: nil, start_date: nil, start_time: nil, end_date: nil, end_time: nil, all_day: nil, location: nil, notes: nil) }
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
        if isPermissionMode {
            // 권한만 요청하고 종료 — 창 표시 안 함
            NSApp.setActivationPolicy(.accessory)
            let store = EKEventStore()
            if #available(macOS 14.0, *) {
                store.requestFullAccessToEvents { granted, _ in
                    if granted {
                        fputs("GRANTED\n", stdout)
                    } else {
                        fputs("DENIED\n", stdout)
                    }
                    DispatchQueue.main.async {
                        NSApp.terminate(nil)
                    }
                }
            } else {
                store.requestAccess(to: .event) { granted, _ in
                    if granted {
                        fputs("GRANTED\n", stdout)
                    } else {
                        fputs("DENIED\n", stdout)
                    }
                    DispatchQueue.main.async {
                        NSApp.terminate(nil)
                    }
                }
            }
            return
        }

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
