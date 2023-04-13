import SwiftUI
import AppKit
import UserNotifications

extension Color {
    func toHexString() -> String {
        let components = self.cgColor!.components!
        let r = components[0]
        let g = components[1]
        let b = components[2]
        
        return String(format: "%02X%02X%02X", Int(r * 255), Int(g * 255), Int(b * 255))
    }

    static func fromHexString(_ hex: String) -> Color {
        return Color(hex: hex)
    }
}

@main
struct HabitFlashApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        SettingsScene()
    }
}



class TimerManager: ObservableObject {
    @Published var timer: Timer? = nil
    
    var timerExpiredCallback: (() -> Void)?
    
    func startNewTimer(intervalSeconds: Int, giveOrTakeSeconds: Int) {
        print("timer starting")
        timer?.invalidate()
        let lowerBound = max(1, intervalSeconds - giveOrTakeSeconds)
        let upperBound = intervalSeconds + giveOrTakeSeconds
        let interval = Double(Int.random(in: lowerBound...upperBound))
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { _ in
            self.timerExpiredCallback?()
            self.timer = nil
        }
    }

    func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
}


class AppDelegate: NSObject, NSApplicationDelegate {
    var timerManager = TimerManager()
    
    var window: NSWindow!
    var settingsWindow: NSWindow!

    func applicationDidFinishLaunching(_ notification: Notification) {
        requestNotificationPermission()
        let contentView = HabitFlashContentView().environmentObject(timerManager)
        

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
        
        NotificationCenter.default.addObserver(self, selector: #selector(systemWillSleep(_:)), name: NSWorkspace.willSleepNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(systemDidWake(_:)), name: NSWorkspace.didWakeNotification, object: nil)


    }

    func applicationWillTerminate(_ notification: Notification) {
    }
    
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        showSettingsWindow()
        return true
    }
    
    @objc func systemWillSleep(_ notification: Notification) {
        timerManager.stopTimer()
    }
    
    @objc func systemDidWake(_ notification: Notification) {
        timerManager.startNewTimer(intervalSeconds: 10, giveOrTakeSeconds: 5)
    }

    
    func showSettingsWindow() {
        if settingsWindow == nil {
            let settingsView = SettingsView()
            settingsWindow = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 480, height: 200),
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
    @EnvironmentObject var timerManager: TimerManager
    
    @AppStorage("reminders") private var reminders: String = "Stretch,Water,Stand"
    @AppStorage("intervalSeconds") private var intervalSeconds: Int = 10
    @AppStorage("giveOrTakeSeconds") private var giveOrTakeSeconds: Int = 5
    @AppStorage("fontSize") private var fontSize: Double = 100.0
    @AppStorage("fontColor") private var fontColorHex: String = "FFFFFF"
    @AppStorage("fadeInOut") private var fadeInOut: Bool = false
    @AppStorage("playSound") private var playSound: Bool = false
    @AppStorage("sound") private var sound: String = "Default"
    @AppStorage("volume") private var volume: Double = 1.0
    @AppStorage("displayDuration") private var displayDuration: Double = 50
    @AppStorage("useNotifications") private var useNotifications: Bool = true
    @AppStorage("useFullScreenNotifications") private var useFullScreenNotifications: Bool = true
    @AppStorage("useSystemNotifications") private var useSystemNotifications: Bool = false

    
    @State private var timer: Timer? = nil
    @State private var reminderText = ""
    @State private var trigger = false
    @State private var reminderOpacity = 0.0

    private var remindersArray: [String] {
        reminders.components(separatedBy: ",")
    }
    private var fontColor: Color {
        Color.fromHexString(fontColorHex)
    }

    var body: some View {
        Text(reminderText)
            .font(.system(size: CGFloat(fontSize), weight: .bold, design: .default))
            .foregroundColor(fontColor)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.clear)
            .ignoresSafeArea()
            .onAppear {
                timerManager.timerExpiredCallback = startOver
                startNewTimer()
            }
            .opacity(reminderOpacity)
    }
    
    func startOver() {
        showReminder();
        startNewTimer()
    }
    
    func startNewTimer() {
        timerManager.startNewTimer(intervalSeconds: intervalSeconds, giveOrTakeSeconds: giveOrTakeSeconds)
    }

    func stopTimer() {
        timerManager.stopTimer()
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
            let soundName: String
            switch sound {
            case "Chime":
                soundName = "Ping"
            case "Bell":
                soundName = "Submarine"
            default:
                soundName = "Purr"
            }
            print("Showing system notification");
            let content = UNMutableNotificationContent()
            content.title = "ReMindful"
            content.body = reminderText
            content.sound = playSound ? UNNotificationSound(named: UNNotificationSoundName(rawValue: soundName)) : nil

            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)
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
    @AppStorage("intervalSeconds") private var intervalSeconds: Int = 10
    @AppStorage("giveOrTakeSeconds") private var giveOrTakeSeconds: Int = 5
    @AppStorage("fontSize") private var fontSize: Double = 100.0
    @AppStorage("fontColor") private var fontColorHex: String = "FFFFFF"
    @AppStorage("fadeInOut") private var fadeInOut: Bool = false
    @AppStorage("playSound") private var playSound: Bool = false
    @AppStorage("sound") private var sound: String = "Default"
    @AppStorage("volume") private var volume: Double = 1.0
    @AppStorage("displayDuration") private var displayDuration: Double = 50
    @AppStorage("useNotifications") private var useNotifications: Bool = true
    @AppStorage("useFullScreenNotifications") private var useFullScreenNotifications: Bool = true
    @AppStorage("useSystemNotifications") private var useSystemNotifications: Bool = false
    
    private var fontColor: Binding<Color> {
        Binding<Color>(
            get: { Color.fromHexString(fontColorHex) },
            set: { fontColorHex = $0.toHexString() }
        )
    }
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Toggle("Remind every", isOn: $useNotifications)
                TextField("", value: $intervalSeconds, formatter: NumberFormatter())
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(width: 50)

                Text("seconds give or take")
                TextField("", value: $giveOrTakeSeconds, formatter: NumberFormatter())
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(width: 50)
                Text("seconds.")
            }
            Spacer(minLength: CGFloat(10))
            Divider()
            Spacer(minLength: CGFloat(10))
            
            Text("Reminders:").font(.headline)
                .alignmentGuide(.leading) { d in d[.leading] }
            TextEditor(text: $reminders)
                .frame(minHeight: 100, maxHeight: .infinity)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(15) // Add padding to the text input
                .cornerRadius(30)
            
            GroupBox(label: Text("Display Settings").font(.headline)) {
                VStack(alignment: .leading) {
                    Toggle("Show system reminders", isOn: $useSystemNotifications)
                    Divider()
                    Toggle("Show full screen reminders", isOn: $useFullScreenNotifications)
                    Toggle("Fade in and out", isOn: $fadeInOut)
                    HStack {
                        Text("Display duration:")
                        Slider(value: $displayDuration, in: 0...100)
                            .frame(width: 100)
                        Text("\(Int(displayDuration))")
                    }
                    HStack {
                        Text("Font:")
                        Slider(value: $fontSize, in: 30...250)
                            .frame(width: 100)
                        ColorPicker("", selection: fontColor)
                            .labelsHidden()
                            .frame(width: 100)
                    }
                }
                .padding(15).frame(maxWidth: .infinity)
            }.padding() // Stretch the group width to full width


            VStack(alignment: .leading) {
                GroupBox(label: Text("Sound Settings").font(.headline)) {

                    HStack {
                        Toggle("Play sound", isOn: $playSound)
                        Picker("", selection: $sound) {
                            Text("Default").tag("Default")
                            Text("Chime").tag("Chime")
                            Text("Bell").tag("Bell")
                            // Add more sounds here
                        }.frame(width: 100)
                        Text("at volume")
                        Slider(value: $volume, in: 0...1)
                            .frame(width: 100)
                    }.padding(15).frame(maxWidth: .infinity)
                }
                .padding()
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
