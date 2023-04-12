import SwiftUI
import AppKit
import UserNotifications


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
        requestNotificationPermission()
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

struct HabitFlashContentView: View {
    @AppStorage("reminders") private var reminders: String = "Stretch,Water,Stand"
    @AppStorage("minSeconds") private var minSeconds: Int = 5
    @AppStorage("maxSeconds") private var maxSeconds: Int = 15
    @AppStorage("fontSize") private var fontSize: Int = 100
    @AppStorage("fontColor") private var fontColor: String = "FFFFFF"
    @AppStorage("fadeInOut") private var fadeInOut: Bool = false
    @AppStorage("playSound") private var playSound: Bool = false
    @AppStorage("sound") private var sound: String = "Default"
    @AppStorage("volume") private var volume: Double = 1.0
    @AppStorage("displayDuration") private var displayDuration: Double = 50
    @AppStorage("useFullScreenNotifications") private var useFullScreenNotifications: Bool = true
    @AppStorage("useSystemNotifications") private var useSystemNotifications: Bool = false

    
    @State private var timer: Timer? = nil
    @State private var reminderText = ""
    @State private var trigger = false
    @State private var reminderOpacity = 0.0

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
            .opacity(reminderOpacity)
    }

    func startNewTimer() {
        timer?.invalidate()
        let interval = Double(Int.random(in: min(minSeconds, maxSeconds)...max(minSeconds, maxSeconds)))
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { _ in
            trigger.toggle()
        }
    }


    func showReminder() {
        if useFullScreenNotifications {
            playSelectedSound();
            reminderText = remindersArray.randomElement()!.trimmingCharacters(in: .whitespacesAndNewlines)
            let delay = max(Double(reminderText.count) / 17, 0.5) * max(1, displayDuration / 20)
            
            if fadeInOut {
                withAnimation(.easeInOut(duration: 0.5)) {
                    reminderOpacity = 1.0
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        reminderOpacity = 0.0
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        reminderText = ""
                    }
                }
            } else {
                reminderOpacity = 1.0
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    reminderOpacity = 0.0
                    reminderText = ""
                }
            }
        }
        if useSystemNotifications {
            print("Showing system notification");
            let content = UNMutableNotificationContent()
            content.title = "HabitFlash Reminder"
            content.body = reminderText
            content.sound = playSound ? UNNotificationSound(named: UNNotificationSoundName(rawValue: sound)) : nil

            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
            let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)

            UNUserNotificationCenter.current().add(request)
        }
    }

    func playSelectedSound() {
        guard playSound else { return }

        let soundName: String
        switch sound {
        case "Chime":
            soundName = "Ping"
        case "Bell":
            soundName = "Submarine"
        default:
            soundName = "Purr"
        }

        if let systemSound = NSSound(named: soundName) {
            systemSound.volume = Float(volume)
            systemSound.play()
        } else {
            print("Error: Could not load or play the sound file.")
        }
    }


}

struct SettingsView: View {
    @AppStorage("reminders") private var reminders: String = "Stretch,Water,Stand"
    @AppStorage("minSeconds") private var minSeconds: Int = 5
    @AppStorage("maxSeconds") private var maxSeconds: Int = 15
    @AppStorage("fontSize") private var fontSize: Int = 100
    @AppStorage("fontColor") private var fontColor: String = "FFFFFF"
    @AppStorage("fadeInOut") private var fadeInOut: Bool = false
    @AppStorage("playSound") private var playSound: Bool = false
    @AppStorage("sound") private var sound: String = "Default"
    @AppStorage("volume") private var volume: Double = 1.0
    @AppStorage("displayDuration") private var displayDuration: Double = 50
    @AppStorage("useFullScreenNotifications") private var useFullScreenNotifications: Bool = true
    @AppStorage("useSystemNotifications") private var useSystemNotifications: Bool = false


    var body: some View {
        VStack (alignment: .leading) {
            HStack {
                Text("Reminders:")
                TextEditor(text: $reminders)
                    .frame(minHeight: 100, maxHeight: .infinity)
                    .border(Color.gray, width: 1)
            }
            GroupBox(label: Text("Notification display settings")) {
                VStack(alignment: .leading) {
                    Toggle("Use full screen notifications", isOn: $useFullScreenNotifications)
                    Toggle("Use system notifications", isOn: $useSystemNotifications)
                }
            }
            .padding(.bottom)
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
                Text("Display duration:")
                Slider(value: $displayDuration, in: 0...100)
                    .frame(width: 150)
                Text("\(Int(displayDuration))")
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
            Toggle("Fade in and out", isOn: $fadeInOut)
            
            Toggle("Play sound", isOn: $playSound)
            
            HStack {
                Text("Sound:")
                Picker("Sound", selection: $sound) {
                    Text("Default").tag("Default")
                    Text("Chime").tag("Chime")
                    Text("Bell").tag("Bell")
                    // Add more sounds here
                }
                .frame(width: 150)
            }
            
            HStack {
                Text("Volume:")
                Slider(value: $volume, in: 0...1)
                    .frame(width: 150)
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
