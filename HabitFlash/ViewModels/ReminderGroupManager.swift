//
//  ReminderGroupManager.swift
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

import Foundation
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
