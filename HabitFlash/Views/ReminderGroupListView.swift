//
//  ReminderGroupListView.swift
//  ReMindful
//
//  Created by Jeff Jassky on 1/16/24.
//

import SwiftUI

struct ReminderGroupListView: View {
    @ObservedObject var reminderGroupManager: ReminderGroupManager
    @EnvironmentObject var settings: SettingsManager
    @EnvironmentObject var reminderManager: ReminderManager

    var body: some View {
        VStack(alignment: .leading) {
            Text("Reminders").font(.title).padding()
            Divider()
            
            VStack(alignment: .leading) {
                Toggle("Display the time every hour on the hour", isOn: settings.$showHourOnTheHour).onChange(of: settings.showHourOnTheHour) { newValue in
                    settings.displayMessagePublisher.send(newValue ? "Clock reminders on" : "Clock reminders off")
                }
                ForEach(Array(reminderGroupManager.reminderGroups.enumerated()), id: \.element.id) { index, group in
                    ReminderGroupView(reminderGroup: $reminderGroupManager.reminderGroups[index], onDelete: {
                        reminderGroupManager.reminderGroups.remove(at: index)
                        reminderManager.stopTimer(groupID: group.id)
                    }).environmentObject(settings).environmentObject(reminderManager)
                }
            }.padding()
        }
    }
}

struct ReminderGroupListView_Previews: PreviewProvider {
    static var settingsManager = SettingsManager();
    static var previews: some View {
        ReminderGroupListView(reminderGroupManager: ReminderGroupManager())
            .environmentObject(ReminderManager(settings: settingsManager))
    }
}
