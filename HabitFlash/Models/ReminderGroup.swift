//
//  ReminderGroup.swift
//  ReMindful
//
//  Created by Jeff Jassky on 1/16/24.
//

import Foundation

struct ReminderGroup: Identifiable, Codable {
    var id = UUID()
    var reminders: String
    var intervalCount: Int
    var interval: String
    var giveOrTakeCount: Int
    var giveOrTakeInterval: String
    var always: Bool

    var schedules: [String: ReminderGroupSchedule]

    init(
        reminders: String,
        intervalCount: Int,
        interval: String,
        giveOrTakeCount: Int,
        giveOrTakeInterval: String,
        always: Bool
    ) {
        self.reminders = reminders
        self.intervalCount = intervalCount
        self.interval = interval
        self.giveOrTakeCount = giveOrTakeCount
        self.giveOrTakeInterval = giveOrTakeInterval
        self.always = always

        // Initialize the schedules dictionary with default values
        self.schedules = [
            "sunday": ReminderGroupSchedule(enabled: true, time: "all day"),
            "monday": ReminderGroupSchedule(enabled: true, time: "all day"),
            "tuesday": ReminderGroupSchedule(enabled: true, time: "all day"),
            "wednesday": ReminderGroupSchedule(enabled: true, time: "all day"),
            "thursday": ReminderGroupSchedule(enabled: true, time: "all day"),
            "friday": ReminderGroupSchedule(enabled: true, time: "all day"),
            "saturday": ReminderGroupSchedule(enabled: true, time: "all day"),
        ]
    }
}
