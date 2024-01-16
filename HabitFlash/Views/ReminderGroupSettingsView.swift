//
//  ReminderGroupSettingsView.swift
//  ReMindful
//
//  Created by Jeff Jassky on 1/16/24.
//

import SwiftUI

struct ReminderGroupSettingsView: View{
    @EnvironmentObject var settings: SettingsManager
    @EnvironmentObject var reminderManager: ReminderManager
    
    var body: some View {
        VStack(alignment: .leading) {
            ReminderGroupListView(reminderGroupManager: settings.reminderGroupManager)
                .environmentObject(settings)
                .environmentObject(reminderManager)
            HStack{
                Spacer().frame(maxWidth: .infinity)
                Button("New reminder group") {
                    let reminderGroup = ReminderGroup(
                        reminders: "Stretch,Water,Stand",
                        intervalCount: 10,
                        interval: "Minutes",
                        giveOrTakeCount: 5,
                        giveOrTakeInterval: "Minutes",
                        always: true
                    );
                    settings.reminderGroupManager.reminderGroups.append(reminderGroup)
                    reminderManager.startNewTimer(groupID: reminderGroup.id)
                }.padding().frame(alignment: .trailing)
            }
         }
    }
}

struct ReminderGroupSettingsView_Previews: PreviewProvider {
    static var settingsManager = SettingsManager()
    static var reminderManager = ReminderManager(settings: settingsManager)
    static var previews: some View {
        ReminderGroupSettingsView()
            .environmentObject(settingsManager)
            .environmentObject(reminderManager)
    }
}
