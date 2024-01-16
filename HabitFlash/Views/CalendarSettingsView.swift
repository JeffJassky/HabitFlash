//
//  CalendarSettingsView.swift
//  ReMindful
//
//  Created by Jeff Jassky on 1/16/24.
//

import SwiftUI
import EventKit

struct CalendarSettingsView: View {
    @EnvironmentObject var settings: SettingsManager
    @State private var isAccessGranted = false
    @State private var availableCalendars: [EKCalendar] = []

    @State private var eventStore = EKEventStore()

    private func requestCalendarAccess() {
        eventStore.requestAccess(to: .event) { (granted, error) in
            DispatchQueue.main.async {
                if granted {
                    self.eventStore = EKEventStore()
                    let calendars = self.eventStore.calendars(for: .event)
                    print("Fetched Calendars: \(calendars)")
                    self.availableCalendars = calendars
                    self.isAccessGranted = true
                } else {
                    self.isAccessGranted = false
                    print("Access Denied: \(String(describing: error))")
                }
            }
        }
    }


    var body: some View {
        VStack {
            if isAccessGranted {
                List(availableCalendars, id: \.calendarIdentifier) { calendar in
                    Toggle(isOn: Binding(
                        get: { self.settings.selectedCalendars.contains(calendar.calendarIdentifier) },
                        set: { isSelected in
                            if isSelected {
                                self.settings.selectedCalendars.append(calendar.calendarIdentifier)
                            } else {
                                self.settings.selectedCalendars.removeAll { $0 == calendar.calendarIdentifier }
                            }
                        }
                    )) {
                        Text(calendar.title)
                    }
                }
            } else {
                VStack(alignment: .leading) {
                    Text("Access to the calendar is needed to show alerts for events.")
                    Button("Request Access", action: requestCalendarAccess)
                }.padding();
            }
        }.onAppear(perform: requestCalendarAccess)
    }
}

struct CalendarSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        CalendarSettingsView()
            .environmentObject(SettingsManager())
    }
}
