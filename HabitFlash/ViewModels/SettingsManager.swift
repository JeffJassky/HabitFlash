//
//  SettingsManager.swift
//  ReMindful
//
//  Created by Jeff Jassky on 1/16/24.
//

import Foundation
import SwiftUI
import AppKit
import UserNotifications
import Foundation
import Combine
import EventKit

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
    @AppStorage("showHourOnTheHour") var showHourOnTheHour: Bool = true
    @AppStorage("pomodoroDuration") var pomodoroDuration: Int = 25;
    @AppStorage("pomodoroCountdownDisplay") var pomodoroCountdownDisplay: Bool = true;
    @AppStorage("pomodoroCountdownDisplayFrequency") var pomodoroCountdownDisplayFrequency: Int = 10;
    
    @Published var selectedCalendars: [String] {
        didSet {
            UserDefaults.standard.set(selectedCalendars, forKey: "selectedCalendars")
        }
    }
    
    init() {
        self.selectedCalendars = UserDefaults.standard.stringArray(forKey: "selectedCalendars") ?? []
    }
    
    var fontColor: Binding<Color> {
        Binding<Color>(
            get: { Color.fromHexString(self.fontColorHex) },
            set: { self.fontColorHex = $0.toHexString() }
        )
    }

}
