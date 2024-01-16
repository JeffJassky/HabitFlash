//
//  SoundSettingsView.swift
//  ReMindful
//
//  Created by Jeff Jassky on 1/16/24.
//

import SwiftUI

struct SoundSettingsView: View {
    @EnvironmentObject var settings: SettingsManager
    var body: some View{
        VStack(alignment: .leading) {
            Text("Sound settings").font(.title).padding()
            Divider()
            HStack {
                Toggle("Play sound", isOn: settings.$playSound)
                Picker("", selection: settings.$sound) {
                    Text("Default").tag("Purr")
                    Text("Chime").tag("Submarine")
                    Text("Bell").tag("Ping")
                    // Add more sounds here
                }.frame(width: 100)
                Text("at volume")
                Slider(value: settings.$volume, in: 0...1)
                    .frame(width: 100)
            }.padding()
        }
    }
}

struct SoundSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SoundSettingsView()
            .environmentObject(SettingsManager())
    }
}
