//
//  ReminderGroupView.swift
//  ReMindful
//
//  Created by Jeff Jassky on 1/16/24.
//

import SwiftUI

struct ReminderGroupView: View {
    @Binding var reminderGroup: ReminderGroup
    @EnvironmentObject var settings: SettingsManager
    @EnvironmentObject var reminderManager: ReminderManager
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
                        // Add more sounds here
                    }.frame(width: 100)
                    Text("give or take")
                    TextField("Give or take", value: $reminderGroup.giveOrTakeCount, formatter: NumberFormatter()).frame(width: 30)
                    Picker("", selection: $reminderGroup.giveOrTakeInterval) {
                        Text(reminderGroup.giveOrTakeCount == 1 ? "Minute" : "Minutes").tag("Minutes")
                        Text(reminderGroup.giveOrTakeCount == 1 ? "Hour" : "Hours").tag("Hours")
                        // Add more sounds here
                    }.frame(width: 100)
                }
                TextField("Reminders", text: $reminderGroup.reminders)
                HStack (alignment: .bottom){
                    VStack (alignment: .leading) {
                        Toggle("Always", isOn: $reminderGroup.always)
                        if !reminderGroup.always {
                            ForEach(Array(reminderGroup.schedules.keys), id: \.self) { key in
                                ReminderGroupScheduleView(
                                    reminderGroupSchedule: Binding<ReminderGroupSchedule>(
                                        get: { reminderGroup.schedules[key] ?? ReminderGroupSchedule(enabled: true, time: "all day") },
                                        set: { reminderGroup.schedules[key] = $0 }
                                    ),
                                    day: key.description
                                )
                            }
                        }else{
                            Spacer().frame(maxWidth: .infinity, maxHeight: CGFloat(1))
                        }
                    }.frame(maxWidth: .infinity)
                    Button("Remove group") {
                        onDelete?()
                    }.frame(alignment: .trailing)
                    Button("View sample") {
                        reminderManager.showReminderPublisher.send(reminderGroup.id)
                    }.frame(alignment: .trailing)
                }

            }.padding()
        }
    }
}

struct ReminderGroupView_Previews: PreviewProvider {
    
    static var settingsManager = SettingsManager();

    static var reminderManager = ReminderManager(settings: settingsManager)
    
    @State static private var reminderGroup = ReminderGroup(
        reminders: "Sleep, whatever",
        intervalCount: 10,
        interval: "Minutes",
        giveOrTakeCount: 5,
        giveOrTakeInterval: "Minutes",
        always: true
    )
    
    static var previews: some View {
        ReminderGroupView(reminderGroup: $reminderGroup)
            .environmentObject(settingsManager)
            .environmentObject(reminderManager)
    }
}
