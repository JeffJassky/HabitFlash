//
//  ReminderManager.swift
//  ReMindful
//
//  Created by Jeff Jassky on 1/16/24.
//
import SwiftUI
import AppKit
import UserNotifications
import Foundation
import Combine
import EventKit

class ReminderManager: ObservableObject {
    @EnvironmentObject var reminderGroupManager: ReminderGroupManager
    var showReminderPublisher = PassthroughSubject<UUID, Never>()
    
    var timers: [UUID: Timer] = [:]
    
    var settings: SettingsManager
    init(settings: SettingsManager) {
        self.settings = settings
    }
    
    func startNewTimer(groupID: UUID) {
        stopTimer(groupID: groupID)
        if let index = settings.reminderGroupManager.reminderGroups.firstIndex(where: { $0.id == groupID }) {
            let reminderGroup = settings.reminderGroupManager.reminderGroups[index]
            let interervalMultiplier = reminderGroup.interval == "Minutes" ? 60 : reminderGroup.interval == "Hours" ? 3600 : 60;
            let giveOrTakeMultiplier = reminderGroup.giveOrTakeInterval == "Minutes" ? 60 : reminderGroup.giveOrTakeInterval == "Hours" ? 3600 : 60;
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
