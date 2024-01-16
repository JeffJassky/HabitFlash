//
//  SettingsView.swift
//  ReMindful
//
//  Created by Jeff Jassky on 1/16/24.
//


import Foundation
import SwiftUI
import AppKit
import UserNotifications
import Combine

struct SettingsView: View {
    
    @EnvironmentObject var settings: SettingsManager
    @State var selection: Set<Int> = [0]
    
    var body: some View {
        NavigationView {
            List(selection: self.$selection) {
                Label("Timer", systemImage: "alarm.fill").accentColor(.orange).tag(0)
                Label("Reminders", systemImage: "bell.fill").accentColor(.orange).tag(1)
                Label("Calendar", systemImage: "calendar").accentColor(.orange).tag(2)
                Label("Visuals", systemImage: "eye.fill").accentColor(.orange).tag(3)
                Label("Sound", systemImage: "speaker.2.fill").accentColor(.orange).tag(4)
            }
            .listStyle(SidebarListStyle())
            .frame(minWidth: 180, idealWidth: 180, maxWidth: 180, maxHeight: .infinity)
            
            VStack {
                Group {
                    if let selected = selection.first {
                        switch selected {
                        case 0:
                            PomodoroTimerView()
                        case 1:
                            ReminderGroupSettingsView()
                        case 2:
                            CalendarSettingsView()
                        case 3:
                            DisplaySettingsView()
                        case 4:
                            SoundSettingsView()
                        default:
                            PomodoroTimerView()
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

struct SettingsView_Previews: PreviewProvider {
    static var settingsManager = SettingsManager()
    static var previews: some View {
        SettingsView()
            .environmentObject(settingsManager)
    }
}
