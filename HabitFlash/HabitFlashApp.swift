import SwiftUI
import AppKit
import UserNotifications
import Foundation
import Combine

@main
struct HabitFlashApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    var body: some Scene {
        WindowGroup {
            SettingsView()
                .environmentObject(appDelegate.settingsManager)
                .environmentObject(appDelegate.timerManager)
        }
    }
}

struct ReminderGroup: Identifiable, Codable {
    var id = UUID()
    var reminders: String
    var intervalCount: Int
    var interval: String
    var giveOrTakeCount: Int
    var giveOrTakeInterval: String
}

class SettingsManager: ObservableObject{
    var displayMessagePublisher = PassthroughSubject<String, Never>()
    @Published var reminderGroupManager = ReminderGroupManager()
    @AppStorage("fontSize") var fontSize: Double = 100.0
    @AppStorage("fontColor") var fontColorHex: String = "FFFFFF"
    @AppStorage("fontShadow") var fontShadow: Bool = true
    @AppStorage("fadeInOut") var fadeInOut: Bool = false
    @AppStorage("playSound") var playSound: Bool = false
    @AppStorage("sound") var sound: String = "Default"
    @AppStorage("volume") var volume: Double = 1.0
    @AppStorage("displayDuration") var displayDuration: Double = 50
    @AppStorage("useNotifications") var useNotifications: Bool = true
    @AppStorage("useFullScreenNotifications") var useFullScreenNotifications: Bool = true
    @AppStorage("useSystemNotifications") var useSystemNotifications: Bool = false
    
    var fontColor: Binding<Color> {
        Binding<Color>(
            get: { Color.fromHexString(self.fontColorHex) },
            set: { self.fontColorHex = $0.toHexString() }
        )
    }

}

class TimerManager: ObservableObject {
    @EnvironmentObject var reminderGroupManager: ReminderGroupManager
    var showReminderPublisher = PassthroughSubject<UUID, Never>()
    
    var settings: SettingsManager
    var timers: [UUID: Timer] = [:]
    
    init(settings: SettingsManager) {
        self.settings = settings
    }
    
    func startNewTimer(groupID: UUID) {
        stopTimer(groupID: groupID)
        if let index = settings.reminderGroupManager.reminderGroups.firstIndex(where: { $0.id == groupID }) {
            let reminderGroup = settings.reminderGroupManager.reminderGroups[index]
            let interervalMultiplier = reminderGroup.interval == "Minutes" ? 60 : reminderGroup.interval == "Hours" ? 3600 : reminderGroup.interval == "Days" ? 86400 : 1;
            let giveOrTakeMultiplier = reminderGroup.giveOrTakeInterval == "Minutes" ? 60 : reminderGroup.giveOrTakeInterval == "Hours" ? 3600 : reminderGroup.giveOrTakeInterval == "Days" ? 86400 : 1;
            let lowerBound = (reminderGroup.intervalCount * interervalMultiplier) - (reminderGroup.giveOrTakeCount * giveOrTakeMultiplier)
            let upperBound = (reminderGroup.intervalCount * interervalMultiplier) + (reminderGroup.giveOrTakeCount * giveOrTakeMultiplier)
            let randomInterval = Int.random(in: lowerBound...upperBound)
            
            let timer = Timer.scheduledTimer(withTimeInterval: TimeInterval(randomInterval), repeats: false) { _ in
                print("Showing reminder", groupID)
                self.showReminderPublisher.send(groupID)
            }
            
            timers[groupID] = timer
        }
    }
    
    func startAllTimers() {
        for group in settings.reminderGroupManager.reminderGroups {
            print("Starting timer")
            self.startNewTimer(groupID: group.id)
        }
    }

    
    func stopTimer(groupID: UUID) {
        timers[groupID]?.invalidate()
        timers[groupID] = nil
    }
}

class ReminderGroupManager: ObservableObject {
    private let reminderGroupsKey = "reminderGroups"

    @Published var reminderGroups: [ReminderGroup] {
        didSet {
            saveReminderGroups()
        }
    }

    init() {
        self.reminderGroups = []
        self.reminderGroups = loadReminderGroups()
    }

    private func saveReminderGroups() {
        if let encoded = try? JSONEncoder().encode(reminderGroups) {
            UserDefaults.standard.set(encoded, forKey: reminderGroupsKey)
        }
    }

    private func loadReminderGroups() -> [ReminderGroup] {
        if let data = UserDefaults.standard.data(forKey: reminderGroupsKey),
           let decoded = try? JSONDecoder().decode([ReminderGroup].self, from: data) {
            return decoded
        } else {
            return []
        }
    }
}


class AppDelegate: NSObject, NSApplicationDelegate {
    
    var settingsManager = SettingsManager()
    lazy var timerManager = TimerManager(settings: settingsManager)
    
    var window: NSWindow!
    var settingsWindow: NSWindow!


    func applicationDidFinishLaunching(_ notification: Notification) {
        requestNotificationPermission()

        let contentView = HabitFlashContentView()
            .environmentObject(settingsManager)
            .environmentObject(timerManager)

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
//        timerManager.stopAllTimers()
    }
    
    @objc func systemDidWake(_ notification: Notification) {
//        timerManager.startAllTimers()
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
    @EnvironmentObject var settings: SettingsManager
    @EnvironmentObject var timerManager: TimerManager
    
    private var showReminderSubscriber: AnyCancellable?
    
    @State private var reminderText = ""
    @State private var trigger = false
    @State private var reminderOpacity = 0.0
    @State private var hideWorkItem: DispatchWorkItem?

    var body: some View {
        Text(reminderText)
            .font(.system(size: CGFloat(settings.fontSize), weight: .bold, design: .default))
            .foregroundColor(settings.fontColor.wrappedValue)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.clear)
            .ignoresSafeArea()
            .shadow(color: settings.fontShadow ? Color.black : Color.clear, radius: CGFloat(settings.fontSize/5), x: CGFloat(settings.fontSize/20), y: CGFloat(settings.fontSize/20))
            .onAppear {
                timerManager.startAllTimers()
            }
            .opacity(reminderOpacity)
            .onReceive(timerManager.showReminderPublisher) { groupId in
                showReminderGroupReminder(group: groupId)
            }
            .onReceive(settings.displayMessagePublisher) { message in
                print("got message", message)
                showReminder(reminder: message)
            }
    }

    func showReminderGroupReminder(group: UUID){
        if let thisGroup = settings.reminderGroupManager.reminderGroups.first(where: { $0.id == group }) {
            let remindersArray = thisGroup.reminders.components(separatedBy: ",")
            if let randomReminder = remindersArray.randomElement() {
                reminderText = randomReminder
            } else {
                reminderText = "No reminders found"
            }
        } else {
            reminderText = "Invalid group ID"
        }
        showReminder(reminder: reminderText)
        timerManager.startNewTimer(groupID: group)
    }
    
    func showReminder(reminder: String){
        reminderText = reminder;
        hideWorkItem?.cancel()
        
        if settings.useFullScreenNotifications {
            if(settings.playSound){
                if let systemSound = NSSound(named: settings.sound) {
                    systemSound.volume = Float(settings.volume)
                    systemSound.play()
                } else {
                    print("Error: Could not load or play the sound file.")
                }
            }
            let delay = max(Double(reminderText.count) / 17, 0.5) * max(1, settings.displayDuration / 20)
            
            if settings.fadeInOut {
                withAnimation(.easeInOut(duration: 0.5)) {
                    reminderOpacity = 1.0
                }
                let newWorkItem = DispatchWorkItem {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        reminderOpacity = 0.0
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        reminderText = ""
                    }
                }
                hideWorkItem = newWorkItem
                DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: newWorkItem)
            } else {
                reminderOpacity = 1.0
                let newWorkItem = DispatchWorkItem {
                    reminderOpacity = 0.0
                    reminderText = ""
                };
                hideWorkItem = newWorkItem;
                DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: newWorkItem)
            }
        }
        if settings.useSystemNotifications {
            print("Showing system notification");
            let content = UNMutableNotificationContent()
            content.title = "ReMindful"
            content.body = reminderText
            content.sound = settings.playSound ? UNNotificationSound(named: UNNotificationSoundName(rawValue: settings.sound)) : nil

            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)
            let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)

            UNUserNotificationCenter.current().add(request)
        }
    }
}

struct SettingsView: View {
    
    @EnvironmentObject var settings: SettingsManager
    @State var selection: Set<Int> = [0]
    
    var body: some View {
        NavigationView {
            List(selection: self.$selection) {
                Label("Reminders", systemImage: "alarm.fill").accentColor(.orange).tag(0)
                Label("Visuals", systemImage: "eye.fill").accentColor(.orange).tag(1)
                Label("Sound", systemImage: "speaker.2.fill").accentColor(.orange).tag(2)
            }
            .listStyle(SidebarListStyle())
            .frame(minWidth: 180, idealWidth: 180, maxWidth: 180, maxHeight: .infinity)
            
            VStack {
                Group {
                    if let selected = selection.first {
                        switch selected {
                        case 0:
                            ReminderGroupSettingsView()
                        case 1:
                            DisplaySettingsView()
                        case 2:
                            SoundSettingsView()
                        default:
                            ReminderGroupSettingsView()
                        }
                    } else {
                        Text("Select an option from the sidebar.")
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
    }
}

struct ReminderGroupSettingsView: View{
    @EnvironmentObject var settings: SettingsManager
    @EnvironmentObject var timerManager: TimerManager
    
    var body: some View {
        VStack(alignment: .leading) {
            ReminderGroupListView(reminderGroupManager: settings.reminderGroupManager)
                .environmentObject(settings)
                .environmentObject(timerManager)
            HStack{
                Spacer().frame(maxWidth: .infinity)
                Button("New reminder group") {
                    let reminderGroup = ReminderGroup(reminders: "Stretch,Water,Stand", intervalCount: 10, interval: "Minutes", giveOrTakeCount: 5, giveOrTakeInterval: "Minutes");
                    settings.reminderGroupManager.reminderGroups.append(reminderGroup)
                    timerManager.startNewTimer(groupID: reminderGroup.id)
                }.padding().frame(alignment: .trailing)
            }
         }
    }
}

struct ReminderGroupListView: View {
    @ObservedObject var reminderGroupManager: ReminderGroupManager
    @EnvironmentObject var settings: SettingsManager
    @EnvironmentObject var timerManager: TimerManager

    var body: some View {
        VStack(alignment: .leading) {
            Text("Reminders").font(.title).padding()
            Divider()
            ForEach(Array(reminderGroupManager.reminderGroups.enumerated()), id: \.element.id) { index, group in
                ReminderGroupView(reminderGroup: $reminderGroupManager.reminderGroups[index], onDelete: {
                    reminderGroupManager.reminderGroups.remove(at: index)
                    timerManager.stopTimer(groupID: group.id)
                }).environmentObject(settings).environmentObject(timerManager)
            }
        }
    }
}

struct ReminderGroupView: View {
    @Binding var reminderGroup: ReminderGroup
    @EnvironmentObject var settings: SettingsManager
    @EnvironmentObject var timerManager: TimerManager
    var onDelete: (() -> Void)?

    var body: some View {

        GroupBox {
            VStack(alignment: .leading) {
                HStack {
                    Text("Remind me every")
                    TextField("Interval seconds", value: $reminderGroup.intervalCount, formatter: NumberFormatter()).frame(width: 30)
                    Picker("", selection: $reminderGroup.interval) {
                        Text(reminderGroup.intervalCount == 1 ? "Minute" : "Minutes").tag("Minutes")
                        Text(reminderGroup.intervalCount == 1 ? "Hour" : "Hours").tag("Hours")
                        Text(reminderGroup.intervalCount == 1 ? "Day" : "Days").tag("Days")
                        // Add more sounds here
                    }.frame(width: 100)
                    Text("give or take")
                    TextField("Give or take", value: $reminderGroup.giveOrTakeCount, formatter: NumberFormatter()).frame(width: 30)
                    Picker("", selection: $reminderGroup.giveOrTakeInterval) {
                        Text(reminderGroup.giveOrTakeCount == 1 ? "Minute" : "Minutes").tag("Minutes")
                        Text(reminderGroup.giveOrTakeCount == 1 ? "Hour" : "Hours").tag("Hours")
                        Text(reminderGroup.giveOrTakeCount == 1 ? "Day" : "Days").tag("Days")
                        // Add more sounds here
                    }.frame(width: 100)
                }
                TextField("Reminders", text: $reminderGroup.reminders)
                HStack{
                    Spacer().frame(maxWidth: .infinity)
                    Button("Remove group") {
                        onDelete?()
                    }.frame(alignment: .trailing)
                    Button("View sample") {
                        timerManager.showReminderPublisher.send(reminderGroup.id)
                    }.frame(alignment: .trailing)
                }
            }.padding()
        }
        .padding()
    }
}


struct DisplaySettingsView: View {
    @EnvironmentObject var settings: SettingsManager
    var body: some View {
        VStack(alignment: .leading) {
            Text("Visual settings").font(.title).padding()
            Divider()
            VStack(alignment: .leading){
                Toggle("Show system reminders", isOn: settings.$useSystemNotifications).onChange(of: settings.useSystemNotifications) { newValue in
                    settings.displayMessagePublisher.send(newValue ? "System reminders on" : "System reminders off")
                }
                Divider()
                Toggle("Show full screen reminders", isOn: settings.$useFullScreenNotifications).onChange(of: settings.useFullScreenNotifications) { newValue in
                    settings.displayMessagePublisher.send(newValue ? "Full screen reminders on" : "Full screen reminders off")
                }
                Toggle("Fade in and out", isOn: settings.$fadeInOut).onChange(of: settings.fadeInOut) { newValue in
                    settings.displayMessagePublisher.send(newValue ? "Fade enabled" : "Fade disabled")
                }
                Toggle("Text shadow", isOn: settings.$fontShadow).onChange(of: settings.fontShadow) { newValue in
                    settings.displayMessagePublisher.send(newValue ? "Text shadow on" : "Text shadow off")
                }
                HStack {
                    Text("Display duration:")
                    Slider(value: settings.$displayDuration, in: 0...100, onEditingChanged: { bool in
                        if(!bool){
                            settings.displayMessagePublisher.send("Display duration changed")
                        }
                      })
                        .frame(width: 100)
                }
                HStack {
                    Text("Font:")
                    Slider(value: settings.$fontSize, in: 30...250, onEditingChanged: { bool in
                        if(!bool){
                            settings.displayMessagePublisher.send("Font size changed")
                        }
                      })
                        .frame(width: 100)
                    ColorPicker("", selection: settings.fontColor)
                        .labelsHidden()
                        .frame(width: 100)
                        .onChange(of: settings.fontColorHex) { newValue in
                            settings.displayMessagePublisher.send("Font color changed")
                        }
                }
            }.padding()
        }
    }
}

struct SoundSettingsView: View {
    @EnvironmentObject var settings: SettingsManager
    var body: some View{
        VStack(alignment: .leading) {
            Text("Sound settings").font(.title).padding()
            Divider()
            HStack {
                Toggle("Play sound", isOn: settings.$playSound)
                Picker("", selection: settings.$sound) {
                    Text("Default").tag("Purr")
                    Text("Chime").tag("Submarine")
                    Text("Bell").tag("Ping")
                    // Add more sounds here
                }.frame(width: 100)
                Text("at volume")
                Slider(value: settings.$volume, in: 0...1)
                    .frame(width: 100)
            }.padding()
        }
    }
}
