//
//  ReminderGroupSchedule.swift
//  ReMindful
//
//  Created by Jeff Jassky on 1/16/24.
//

import Foundation
struct ReminderGroupSchedule: Codable {
    var enabled: Bool
    var time: String
    var startTime: Date?
    var endTime: Date?
}
