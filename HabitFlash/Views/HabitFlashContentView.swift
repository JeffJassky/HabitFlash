//
//  HabitFlashContentView.swift
//  ReMindful
//
//  Created by Jeff Jassky on 1/16/24.
//

import SwiftUI
import AppKit
import UserNotifications
import Foundation
import Combine


struct HabitFlashContentView: View {
    @EnvironmentObject var settings: SettingsManager
    @EnvironmentObject var reminderManager: ReminderManager
    
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
                reminderManager.startAllTimers()
            }
            .opacity(reminderOpacity)
            .onReceive(reminderManager.showReminderPublisher) { groupId in
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
        reminderManager.startNewTimer(groupID: group)
    }
    
    func showReminder(reminder: String){
        reminderText = reminder.trimmingCharacters(in: .whitespacesAndNewlines)
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

struct HabitFlashContentView_Previews: PreviewProvider {
    static var settingsManager = SettingsManager()
    static var reminderManager = ReminderManager(settings: settingsManager)
    static var pomodoroManager = PomodoroManager(settings: settingsManager)
    static var previews: some View {
        HabitFlashContentView()
            .environmentObject(settingsManager)
            .environmentObject(reminderManager)
            .environmentObject(pomodoroManager)
    }
}
