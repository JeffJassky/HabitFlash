//
//  ReminderGroupScheduleView.swift
//  ReMindful
//
//  Created by Jeff Jassky on 1/16/24.
//

import SwiftUI

struct ReminderGroupScheduleView: View {
    @EnvironmentObject var settings: SettingsManager
    @Binding var reminderGroupSchedule: ReminderGroupSchedule
    var day: String
    
    var body: some View {
        VStack (alignment: .leading){
            HStack{
                Toggle(day, isOn: $reminderGroupSchedule.enabled)
                if reminderGroupSchedule.enabled{
                    Picker("", selection: $reminderGroupSchedule.time) {
                        Text("all day").tag("all day")
                        Text("from").tag("from")
                        // Add more options here
                    }.frame(width: 100)
                    if reminderGroupSchedule.enabled && reminderGroupSchedule.time == "from" {
                        DatePicker("", selection: Binding<Date>(
                            get: { reminderGroupSchedule.startTime ?? Date() },
                            set: { reminderGroupSchedule.startTime = $0 }
                        ), displayedComponents: .hourAndMinute).frame(width: 110)
                        DatePicker("to", selection: Binding<Date>(
                            get: { reminderGroupSchedule.endTime ?? Date() },
                            set: { reminderGroupSchedule.endTime = $0 }
                        ), displayedComponents: .hourAndMinute).frame(width: 110)
                    }
                }
                Spacer().frame(maxWidth: .infinity)
            }
        }
    }
}

struct ReminderGroupScheduleView_Previews: PreviewProvider {
    @State static private var reminderGroupSchedule = ReminderGroupSchedule(
        enabled: true,
        time: "all day",
        startTime: Date(),
        endTime: Date()
    )

    static var previews: some View {
        ReminderGroupScheduleView(reminderGroupSchedule: $reminderGroupSchedule, day: "Friday")
            .environmentObject(SettingsManager())
    }
}
