import SwiftUI
import AppKit
import UserNotifications
import Foundation
import Combine
import EventKit

@main
struct HabitFlashApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    var body: some Scene {
        WindowGroup {
            SettingsView()
                .environmentObject(appDelegate.settingsManager)
                .environmentObject(appDelegate.reminderManager)
                .environmentObject(appDelegate.pomodoroManager)
        }
    }
}


class AppDelegate: NSObject, NSApplicationDelegate {
    
    var settingsManager = SettingsManager()
    lazy var reminderManager = ReminderManager(settings: settingsManager)
    lazy var pomodoroManager = PomodoroManager(settings: settingsManager)
    
    var window: NSWindow!
    var settingsWindow: NSWindow!


    func applicationDidFinishLaunching(_ notification: Notification) {
        requestNotificationPermission()

        let contentView = HabitFlashContentView()
            .environmentObject(settingsManager)
            .environmentObject(reminderManager)
            .environmentObject(pomodoroManager)

        let window = NSWindow(
            contentRect: NSScreen.main!.frame,
            styleMask: [],
            backing: .buffered,
            defer: false
        )
        window.level = .floating
        window.contentView = NSHostingView(rootView: contentView)
        window.backgroundColor = .clear
        window.isOpaque = false
        window.ignoresMouseEvents = true
        self.window = window
        window.makeKeyAndOrderFront(nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(systemWillSleep(_:)), name: NSWorkspace.willSleepNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(systemDidWake(_:)), name: NSWorkspace.didWakeNotification, object: nil)
    }

    func applicationWillTerminate(_ notification: Notification) {
    }
    
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        return true
    }
    
    @objc func systemWillSleep(_ notification: Notification) {
//        reminderManager.stopAllTimers()
    }
    
    @objc func systemDidWake(_ notification: Notification) {
//        reminderManager.startAllTimers()
    }
    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            if let error = error {
                print("Error requesting notification authorization: \(error)")
            } else if !granted {
                print("Notification authorization not granted")
            }
        }
    }

}
