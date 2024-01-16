//
//  DisplaySettingsView.swift
//  ReMindful
//
//  Created by Jeff Jassky on 1/16/24.
//

import SwiftUI

struct DisplaySettingsView: View {
    @EnvironmentObject var settings: SettingsManager
    var body: some View {
        VStack(alignment: .leading) {
            Text("Visual settings").font(.title)
            Divider()
            VStack(alignment: .leading){
                Toggle("Show system reminders", isOn: settings.$useSystemNotifications).onChange(of: settings.useSystemNotifications) { newValue in
                    settings.displayMessagePublisher.send(newValue ? "System reminders on" : "System reminders off")
                }
                Divider()
                Toggle("Show full screen reminders", isOn: settings.$useFullScreenNotifications).onChange(of: settings.useFullScreenNotifications) { newValue in
                    settings.displayMessagePublisher.send(newValue ? "Full screen reminders on" : "Full screen reminders off")
                }
                Toggle("Fade in and out", isOn: settings.$fadeInOut).onChange(of: settings.fadeInOut) { newValue in
                    settings.displayMessagePublisher.send(newValue ? "Fade enabled" : "Fade disabled")
                }
                Toggle("Text shadow", isOn: settings.$fontShadow).onChange(of: settings.fontShadow) { newValue in
                    settings.displayMessagePublisher.send(newValue ? "Text shadow on" : "Text shadow off")
                }
                HStack {
                    Text("Display duration:")
                    Slider(value: settings.$displayDuration, in: 0...100, onEditingChanged: { bool in
                        if(!bool){
                            settings.displayMessagePublisher.send("Display duration changed")
                        }
                      })
                        .frame(width: 100)
                }
                HStack {
                    Text("Font:")
                    Slider(value: settings.$fontSize, in: 30...250, onEditingChanged: { bool in
                        if(!bool){
                            settings.displayMessagePublisher.send("Font size changed")
                        }
                      })
                        .frame(width: 100)
                    ColorPicker("", selection: settings.fontColor)
                        .labelsHidden()
                        .frame(width: 100)
                        .onChange(of: settings.fontColorHex) { newValue in
                            settings.displayMessagePublisher.send("Font color changed")
                        }
                }
            }.padding()
        }
    }
}

struct DisplaySettingsView_Previews: PreviewProvider {
    static var settingsManager = SettingsManager()
    static var previews: some View {
        DisplaySettingsView()
            .environmentObject(settingsManager)
    }
}
