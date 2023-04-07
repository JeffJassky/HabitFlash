import SwiftUI
import AppKit

@main
struct HabitFlashApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        SettingsScene()
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow!
    var settingsWindow: NSWindow!

    func applicationDidFinishLaunching(_ notification: Notification) {
        let contentView = HabitFlashContentView()

        let window = NSWindow(
            contentRect: NSScreen.main!.frame,
            styleMask: [],
            backing: .buffered, defer: false)
        window.level = .floating
        window.contentView = NSHostingView(rootView: contentView)
        window.backgroundColor = .clear
        window.isOpaque = false
        window.ignoresMouseEvents = true
        self.window = window
        window.makeKeyAndOrderFront(nil)
    }

    func applicationWillTerminate(_ notification: Notification) {
    }
    
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        showSettingsWindow()
        return true
    }
    
    func showSettingsWindow() {
        if settingsWindow == nil {
            let settingsView = SettingsView()
            settingsWindow = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 400, height: 200),
                styleMask: [.titled, .closable, .miniaturizable],
                backing: .buffered, defer: false)
            settingsWindow.center()
            settingsWindow.contentView = NSHostingView(rootView: settingsView)
            settingsWindow.title = "HabitFlash Settings"
        }
        settingsWindow.makeKeyAndOrderFront(nil)
    }
}

struct HabitFlashContentView: View {
    @AppStorage("reminders") private var reminders: String = "Stretch,Water,Stand"
    @AppStorage("minSeconds") private var minSeconds: Int = 5
    @AppStorage("maxSeconds") private var maxSeconds: Int = 15
    @AppStorage("fontSize") private var fontSize: Int = 100
    @AppStorage("fontColor") private var fontColor: String = "FFFFFF"
    
    @State private var timer: Timer? = nil
    @State private var reminderText = ""
    @State private var trigger = false

    private var remindersArray: [String] {
        reminders.components(separatedBy: ",")
    }

    var body: some View {
        Text(reminderText)
            .font(.system(size: CGFloat(fontSize), weight: .bold, design: .default))
            .foregroundColor(Color(hex: fontColor))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.clear)
            .ignoresSafeArea()
            .onAppear {
                startNewTimer()
            }
            .onChange(of: trigger) { _ in
                showReminder()
                startNewTimer()
            }
    }

    func startNewTimer() {
        timer?.invalidate()
        let interval = Double(Int.random(in: min(minSeconds, maxSeconds)...max(minSeconds, maxSeconds)))
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { _ in
            trigger.toggle()
        }
    }


    func showReminder() {
        reminderText = remindersArray.randomElement()!.trimmingCharacters(in: .whitespacesAndNewlines)
        let delay = max(Double(reminderText.count) / 17, 0.5)
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            reminderText = ""
        }
    }
}

struct SettingsView: View {
    @AppStorage("reminders") private var reminders: String = "Stretch,Water,Stand"
    @AppStorage("minSeconds") private var minSeconds: Int = 5
    @AppStorage("maxSeconds") private var maxSeconds: Int = 15
    @AppStorage("fontSize") private var fontSize: Int = 100
    @AppStorage("fontColor") private var fontColor: String = "FFFFFF"

    var body: some View {
        VStack (alignment: .leading) {
            HStack {
                Text("Reminders:")
                TextEditor(text: $reminders)
                    .frame(minHeight: 100, maxHeight: .infinity)
                    .border(Color.gray, width: 1)
            }
            HStack {
                Text("Min seconds:")
                TextField("", value: $minSeconds, formatter: NumberFormatter())
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(width: 50)

                Text("Max seconds:")
                TextField("", value: $maxSeconds, formatter: NumberFormatter())
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(width: 50)
            }
            HStack {
                Text("Font size:")
                TextField("", value: $fontSize, formatter: NumberFormatter())
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(width: 50)
            }
            HStack {
                Text("Font color (hex):")
                TextField("", text: $fontColor)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(width: 100)
            }
        }
        .padding()
    }
}

struct SettingsScene: Scene {
    var body: some Scene {
        WindowGroup {
            SettingsView()
        }
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
