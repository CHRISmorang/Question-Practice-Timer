import SwiftUI
import AppKit

@main
struct QuestionPracticeTimerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var windowController: TimerWindowController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let contentView = AnyView(FloatingTimerView())
        windowController = TimerWindowController(rootView: contentView)
        
        windowController?.window?.center()
        windowController?.showWindow(nil)
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}
